#!/usr/bin/env lua

if #arg < 3 then
  io.stderr:write('reduce-xml.lua prefix suffix files...\n')
  os.exit(1)
end

lpeg = require'lpeg'
local P = lpeg.P
local S = lpeg.S
local R = lpeg.R
local Cp = lpeg.Cp()
local Cs = lpeg.Cs
local Ct = lpeg.Ct
local C = lpeg.C

local After = function(p) p=P(p) return (1 - p)^0 * p end

local ws = S'\t \n'
local ws0 = ws^0
local ws1 = ws^1
local ws0r = ws0/''
local ws1r = ws1/' '
local str = '"' * After'"' + "'" * After"'"
local word = (R('az','AZ','09') + S'_-')^1
local iseq = ws0 * '=' * ws0
local eq = iseq/'='
local attr = word * eq * str
local comment = P'<!--' * After('-->') / ''
local blank = (ws1 + comment)^1 / ''
local argsdoctype = (ws1r * (str + word))^1 * ws0r

local StrAs = function(p) p=P(p) return ('"' * p * '"' + "'" * p * "'") end
local VAttr = function(p) return eq * StrAs(p) end
local bool = StrAs'true' / '"1"' + StrAs'false' / '"0"'

local isTrue = StrAs(P'true' + '1')
local isFalse = StrAs(P'false' + '0')

local CAttrOnly = Ct(C(word) * iseq * C(str))
local CAttr = ws1 * CAttrOnly
local emptyAttr = word * iseq * (P'""' + "''")

function isDefaultDeliminator(s)
  if not s then
    return false
  end

  local t1, t2 = {}, {}
  s = s:gsub('&amp;','&')
  for i=1,#s do
    t1[s:sub(i,i)] = true
  end
  for k in pairs(t1) do
    t2[#t2+1] = k
  end
  table.sort(t2)
  return table.concat(t2) == '\t !%&()*+,-./:;<=>?[\\]^{|}~'
end

local attrIgnoreFalse
=P'lookAhead' + 'firstNonSpace' + 'dynamic'
+ 'bold' + 'italic' + 'underline'
+ 'indentationsensitive'

local attrIgnoreTrue
=P'casesensitive'
+ 'spellChecking'

local attrBool
= attrIgnoreFalse + attrIgnoreTrue
+ 'insensitive'

local state_casesensitive
function reset_state() 
  state_casesensitive = true
end

local current_context_name

function tokt(t)
  local kt, keys = {}, {}
  for _,v in ipairs(t) do
    if not kt[v[1]] then
      keys[#keys+1] = v[1]
    end
    kt[v[1]] = v[2]
  end
  kt[0] = keys
  return kt
end

function kt2s(kt)
  local t, k, v = {}
  for _,k in ipairs(kt[0]) do
    v = kt[k]
    if v then
      t[#t+1] = ' '
      t[#t+1] = k
      t[#t+1] = '='
      t[#t+1] = attrBool:match(k) and bool:match(v) or v
    end
  end

  return table.concat(t)
end

function reduceKeywordsAttrs(t)
  local kt = tokt(t)

  if isDefaultDeliminator(kt['wordWrapDeliminator']) then
     kt['wordWrapDeliminator'] = nil
  end

  for _,k in ipairs({'weakDeliminator', 'additionalDeliminator'}) do
    if kt[k] == '""' or kt[k] == "''" then
      kt[k] = nil
    end
  end

  local casesensitive = kt['casesensitive']
  if casesensitive then
    if isTrue:match(casesensitive) then
      kt['casesensitive'] = '"1"'
    else
      state_casesensitive = false
    end
  end

  return kt2s(kt)
end

function reduceAttrs(t)
  local kt = tokt(t)

  local lookAhead = kt['lookAhead']
  if lookAhead and isTrue:match(lookAhead) then
    kt['attribute'] = nil
  else 
    local attribute = kt['attribute']
    if attribute and attribute:sub(2,-2) == current_context_name then
      kt['attribute'] = nil
    end
  end

  return kt2s(kt)
end

-- TODO noIndentationBasedFolding only with indentationBasedFolding
local reduce = Cs(
  P'\xEF\xBB\xBF'^-1 / '' -- BOM

* ( '<?' * word * (ws1r * attr)^0 * ws0r * '?>' + blank )^0

* ( '<!DOCTYPE' * argsdoctype
  * ( '[' * (blank + '<!ENTITY' * argsdoctype * '>')^0 * ']' )^-1
  * ws0r
  * '>'
  )^-1

* (blank
  + '<'
  * ( '/' * word
    + 'contexts'

    + P'context'
    * ( ws1
      * ( --[=[ TODO 'fallthrough' * iseq * str -- since 5.62
        +]=] 'lineEndContext' * iseq * StrAs'#stay'
        + emptyAttr
        )
      / ''

      -- TODO until 5.62
      + ws1 * 'fallthrough' * iseq * str / ' fallthrough="1"'

      + ws1r
      * ( (P'dynamic' + 'noIndentationBasedFolding') * eq * bool
        + P'attribute' * eq * (str / function(s) current_context_name=s:sub(2,-2) return s end)
        + attr
        )
      )^0
    * ws0r
    * ( P'/'
      + '>' * ws0 * '</context' / '/'
      )^-1

    + P'keywords' * (Ct((CAttr)^0) / reduceKeywordsAttrs) * ws0r * '/'

    + word
    * (Ct(
        ( ws1
        * ( attrIgnoreTrue * iseq * isTrue
          + attrIgnoreFalse * iseq * isFalse
          + 'context' * iseq * StrAs'#stay'
          + emptyAttr
          + CAttrOnly
          )
        )^0
      ) / reduceAttrs)
    * ws0r
    * P'/'^-1
    )
  * '>'
  + 1
  )^0
)

function removeAttr(tag, attr)
  return Cs(
    ( P'<'
    * tag
    * ( ws * attr / ''
      + ws * word * '=' * str
      )^0
    * '/>'
    + 1
    )^0
  )
end

local removeInsensitiveKw0 = removeAttr('keyword', 'insensitive="0"')
local removeInsensitiveKw1 = removeAttr('keyword', 'insensitive="1"')

local prefix = arg[1]
local suffix = arg[2]

for i=3,#arg do
  filename = arg[i]
  print(filename)

  f = io.open(filename)
  content = f:read'*a'
  f:close()

  reset_state()
  content = reduce:match(content)
  content = (state_casesensitive and removeInsensitiveKw0 or removeInsensitiveKw1):match(content)

  f = io.open(prefix .. filename .. suffix, 'w')
  f:write(content)
  f:close()
end
