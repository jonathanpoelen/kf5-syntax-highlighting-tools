#!/usr/bin/env lua

if #arg < 3 then
  io.stderr:write('reduce-xml.lua prefix suffix files...\n')
  os.exit(1)
end

lpeg = require'lpeg'
local P = lpeg.P
local C = lpeg.C
local S = lpeg.S
local Cf = lpeg.Cf
local Cc = lpeg.Cc
local Cs = lpeg.Cs
local Ct = lpeg.Ct

local endcomment = P'-->'
local ws = S'\t \n'
local reduce = Cs(((ws^1 * '<') / '<' * (('!--' * (1-endcomment)^0 * endcomment) / '')^-1 + 1)^0 + ws^0 / '')

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
