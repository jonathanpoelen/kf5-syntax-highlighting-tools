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
local C = lpeg.C

local After = function(p) p=P(p) return (1 - p)^0 * p end
local CAfter = function(p) p=P(p) return C((1 - p)^0) * p end

local ws = S'\t \n'
local ws0 = ws^0
local ws1 = ws^1
local ws0r = ws0/''
local ws1r = ws1/' '
local str = '"' * After'"' + "'" * After"'"
local Cstr = '"' * CAfter'"' + "'" * CAfter"'"
local word = (R('az','AZ','09') + S'_-')^1
local eq = ws0r * '=' * ws0r
local attr = word * eq * str
local comment = P'<!--' * After('-->') / ''
local blank = (ws1 + comment)^1 / ''
local argsdoctype = (ws1r * (str + word))^1 * ws0r

local StrAs = function(p) p=P(p) return ('"' * p * '"' + "'" * p * "'") end
local VAttr = function(p) return eq * StrAs(p) end
local bool = eq * (StrAs'true' / '"1"' + StrAs'false' / '"0"')

local attrIgnoreFalse
=P'lookAhead' + 'firstNonSpace' + 'dynamic'
+ 'bold' + 'italic' + 'underline'
+ 'spellChecking'
+ 'indentationsensitive'

local attrIgnoreTrue
=P'casesensitive'

local attrBool
= attrIgnoreFalse + attrIgnoreTrue
+ 'insensitive'

local state_casesensitive
function reset_state() 
  state_casesensitive = true
end

local current_context_name

-- TODO noIndentationBasedFolding only with indentationBasedFolding
-- TODO remove attribute with lookAhead=1
local reduce = Cs(
  P'\xEF\xBB\xBF'^-1 / '' -- BOM

* ( '<?' * word * (ws1r * attr)^0 * ws0r * '?>' + blank )^0

* ( '<!DOCTYPE' * argsdoctype
  * ( '[' * (blank + '<!ENTITY' * argsdoctype * '>')^0 * ']' )^-1
  * ws0r
  * '>'
  )^-1

* ( '<'
  * ( '/'
    * ( P'context' * (Cp/function() current_context_name=nil end)
      + word
      )

    + ( P'context'
    * ( ws0 * 'fallthrough' * eq * str / '' )
      + ws1r
      * ( (P'dynamic' + 'noIndentationBasedFolding') * bool
        + P'name' * eq * (str / function(s) current_context_name=s:sub(2,-2) return s end)
        + attr
        )
      )^0

    + word
    * ( ws0
      * ( attrIgnoreTrue * VAttr(P'true' + '1')
        + 'context' * VAttr('#stay')
        + 'weakDeliminator' * VAttr(Cp)
        + attrIgnoreFalse * VAttr(P'0' + 'false')
        ) / ''

      + ws1 * P'attribute' * ws0 * '=' * ws0 * str / function(s) 
          if  s:sub(2,-2) == current_context_name then print('remove', s) end
          return s:sub(2,-2) == current_context_name and '' or ' attribute=' .. s
        end

      + ws1r
      * ( 'casesensitive' * VAttr(P'false' / '0' + '0') * (Cp/function() state_casesensitive = false end)
        + attrBool * bool
        + attr
        )
      )^0
    * ws0r
    * P'/'^-1
    )
  * '>'
  + blank
  + 1
  )^0
)

function removeAttr(tag, attr)
  return Cs(
    ( P'<'
    * tag
    * ( ws1 * attr / ''
      + ws1 * word * '=' * str
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

for _,filename in ipairs({table.unpack(arg, 3)}) do
  print(filename)
  f = io.open(filename)
  content = f:read'*a'
  f:close()

  reset_state()
  content = reduce:match(content)
  content = (state_casesensitive and removeInsensitiveKw0 or removeInsensitiveKw1):match(content)
  print(state_casesensitive)

  f = io.open(prefix .. filename .. suffix, 'w')
  f:write(content)
  f:close()
end
