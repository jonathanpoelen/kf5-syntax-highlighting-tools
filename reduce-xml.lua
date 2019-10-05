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

local After = function(p) p=P(p) return (1 - p)^0 * p end

local ws = S'\t \n'
local ws0 = ws^0
local ws1 = ws^1
local ws0r = ws0/''
local ws1r = ws1/' '
local str = '"' * After'"' + "'" * After"'"
local word = (R('az','AZ','09') + S'_-')^1
local eq = ws0r * '=' * ws0r
local attr = word * eq * str
local comment = P'<!--' * After('-->') / ''
local blank = (ws1 + comment)^1 / ''
local argsdoctype = (ws1r * (str + word))^1 * ws0r

local StrAs = function(p) p=P(p) return ('"' * p * '"' + "'" * p * "'") end
local VAttr = function(p) return eq * StrAs(p) end

local attrIgnoreFalse
=P'lookAhead' + 'firstNonSpace' + 'dynamic'
+ 'bold' + 'italic' + 'underline'
+ 'spellChecking'
+ 'indentationsensitive'

local attrIgnoreTrue
=P'fallthrough'
+ 'casesensitive'

local attrBool
= attrIgnoreFalse + attrIgnoreTrue
+ 'insensitive'

local state_casesensitive
function reset_state() 
  state_casesensitive = true
end

-- TODO remove attribute with lookAhead=1
-- TODO remove attribute if same as context attribute
local reduce = Cs(
  P'\xEF\xBB\xBF'^-1 / '' -- BOM

* ( '<?' * word * (ws1r * attr)^0 * ws0r * '?>' + blank )^0

* ( '<!DOCTYPE' * argsdoctype
  * ( '[' * (blank + '<!ENTITY' * argsdoctype * '>')^0 * ']' )^-1
  * ws0r
  * '>'
  )^-1

* ( '<'
  * ( '/' * word
    + word
    * ( ws0
      * ( attrIgnoreTrue * VAttr(P'true' + '1')
        + 'context' * VAttr('#stay')
        + 'weakDeliminator' * VAttr(Cp)
        + attrIgnoreFalse * VAttr(P'0' + 'false')
        ) / ''
      + ws1r
      * ( 'casesensitive' * VAttr(P'false' / '0' + '0') * (Cp/function() state_casesensitive = false end)
        + attrBool * VAttr(P'true' / '1' + P'false' / '0')
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

local removeInsensitiveKw0 = removeAttr('keyword', 'insensitive=' * StrAs'0')
local removeInsensitiveKw1 = removeAttr('keyword', 'insensitive=' * StrAs'1')

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
