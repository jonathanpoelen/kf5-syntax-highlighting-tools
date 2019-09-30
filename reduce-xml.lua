#!/usr/bin/env lua

if #arg < 3 then
  io.stderr:write('reduce-xml.lua prefix suffix files...\n')
  os.exit(1)
end

lpeg = require'lpeg'
local P = lpeg.P
local S = lpeg.S

local After = function(p) p=P(p) return (1 - p)^0 * p end

local ws = S'\t \n'
local ws0 = ws^0
local ws1 = ws^1
local ws0r = ws0/''
local ws1r = ws1/''
local str = '"' * After'"'
local ws1s = ws1 / ' ' + str
local noclose = (1 - S'>')
-- TODO remove attribute with lookAhead=1
-- TODO remove attribute if same as context attribute
local reduce = lpeg.Cs(ws0r *
  ( '<' *
    ( '!--' * After'-->' / ''
    + '!' * (ws1s + (1 - S'>['))^0 *
      ( S'>'
      + S'['
        * (ws0r * '<' * (ws1s + noclose)^1 * '>')^0
        * ws0r
      )
    + ( ws0 * '/' / '/'
      + ws0 * (P'fallthrough="' * (P'true' + '1') * '"' + P'context="#stay"') / ''
      + ws1s
      + (P'lookAhead' + 'casesensitive' + 'firstNonSpace'
         +'insensitive' + 'spellChecking' + 'dynamic'
         +'bold' + 'italic' + 'underline'
        )
        * '="' * (P'true' / '1' + P'false' / '0') * '"'
      + noclose
      )^1
    ) * ws0r
  + ws1r
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
