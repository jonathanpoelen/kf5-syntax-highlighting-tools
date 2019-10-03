#!/usr/bin/env lua

if #arg < 3 then
  io.stderr:write('reduce-xml.lua prefix suffix files...\n')
  os.exit(1)
end

lpeg = require'lpeg'
local P = lpeg.P
local S = lpeg.S
local R = lpeg.R

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

local VAttr = function(p) p=P(p) return eq * ('"' * p * '"' + "'" * p * "'") end

-- TODO remove attribute with lookAhead=1
-- TODO remove attribute if same as context attribute
local reduce = lpeg.Cs(
  P'\xEF\xBB\xBF'^-1 / '' -- BOM

* ( '<?' * word * (ws1r * attr)^0 * ws0r * '?>' + blank )^0

* ( '<!DOCTYPE' * argsdoctype
  * ( '[' * (blank + '<!ENTITY' * argsdoctype * '>')^0 * ']' )^-1
  * ws0r
  * '>'
  )^-1

* ( blank
  * '<'
  * ( '/' * word
    + word
    * ( ws0
        * ( 'fallthrough' * VAttr(P'true' + '1')
          + 'context' * VAttr('#stay')
          + 'indentationsensitive' * VAttr(P'0' + 'false')
          ) / ''
      + ws1r
        * ( ( P'lookAhead' + 'casesensitive' + 'firstNonSpace'
            + 'insensitive' + 'spellChecking' + 'dynamic'
            + 'bold' + 'italic' + 'underline'
            + 'indentationsensitive'
            )
            * VAttr(P'true' / '1' + P'false' / '0')
          + attr
          )
      )^0
    * ws0r
    * P'/'^-1
    )
  * '>'
  + 1
  )^0
)

local prefix = arg[1]
local suffix = arg[2]

for _,filename in ipairs({table.unpack(arg, 3)}) do
  print(filename)
  f = io.open(filename)
  content = f:read('*a')
  f:close()
  f = io.open(prefix .. filename .. suffix, 'w')
  f:write(reduce:match(content))
  f:close()
end
