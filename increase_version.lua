#!/usr/bin/env lua 
local f, s
for _,filename in ipairs(arg) do
  print(filename)
  f,err = io.open(filename)
  if err then
    io.stderr:write(err..'\n')
  else
    s = f:read'*a':gsub(' version="(%d+)"', function(n)
      return ' version="' .. tonumber(n)+1 .. '"'
    end)
    f:close()
    f = io.open(filename, 'w+')
    f:write(s)
    f:close()
  end
end
