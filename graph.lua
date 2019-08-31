#!/usr/bin/env lua

require('lib/getopt')

local filename = nil
local ctxonly = false
local exclude = nil
local include = nil
function usage()
  print(arg[0] .. [=[ [-h] [-c] [-i lua_pattern] [-e lua_pattern] kate_syntax.xml

  -c  context only
  -i  include context
  -e  exclude context]=])
  os.exit(1)
end
for opt, arg in getopt("hce:i:", ...) do
  if     opt == 'c' then ctxonly = true
  elseif opt == 'e' then exclude = exclude or {} ; exclude[#exclude+1] = arg
  elseif opt == 'i' then include = include or {} ; include[#include+1] = arg
  elseif not opt    then filename = arg
  else   usage()
  end
end
if not filename then
  usage()
end
if include and not exclude then
  exclude = {''}
end
exclude = exclude or {}
include = include or {}


require('lib/getcontexts')
local ctxs = getcontexts(filename, not ctxonly)

local colorMap = {
  '"/set312/1"',
  '"lightgoldenrod1"',
  '"/set312/3"',
  '"/set312/4"',
  '"/set312/5"',
  '"/set312/6"',
  '"/set312/7"',
  '"/rdpu3/2"',
  '"/rdgy4/3"',
  '"/purd6/3"',
  '"/ylgn4/2"',
  '"/set26/6"',
}

function computeColor(name)
  return colorMap[((name:byte(1) + name:byte(2) * 25) % 12 + 1)];
end

function matchctx(name, t)
  local k,v
  for k,v in pairs(t) do
    if name:find(v) then
      return true
    end
  end
  return false
end


if ctxonly then
  print('digraph G {')
  print('  compound=true;ratio=auto')

  for ictx,ctx in pairs(ctxs.children) do
    local ctxname = ctx.attrs.name
    if not matchctx(ctxname, exclude) or matchctx(ctxname, include) then
      local t = {}
      for irule,rule in pairs(ctx.children) do
        if rule.attrs.context and rule.attrs.context ~= '#stay' and rule.attrs.context ~= '#pop' then
          t[rule.attrs.context] = true
        end
      end

      local color = computeColor(ctxname)
      print('  "' .. ctxname .. '" [style=filled,color=' .. color .. ']')
      for k,v in pairs(t) do
        print('  "' .. ctxname .. '" -> "' .. k .. '" [color=' .. color .. ']')
      end
    end
  end

  print('}')

  return 0
end

do
  local lpeg = require'lpeg'
  local P = lpeg.P
  local C = lpeg.C
  local S = lpeg.S
  local Cf = lpeg.Cf
  local Cc = lpeg.Cc
  local Cs = lpeg.Cs
  local Ct = lpeg.Ct
  _countpop = Cf((P'#pop' * Cc(1))^1, function(a,b) return a+b end)
  _wordwap = Ct(Cc('') * C(P(40) + P(1)^1)^0)
  _quote = Cs((S'"' / '\\"' + S'\\' / '\\\\' + 1)^0)
  _jumptxt = (1 - S'!')^1 * '!' * C(P(1)^1)
end

local sharp = string.byte('#',1)

local k
local v
local t1 = {'attribute','String','char','char1'}
local t2 = {'beginRegion','endRegion','lookAhead','firstNonSpace', 'column'}

function stringifyattrs(t, attrs)
  local sattr
  local s = ''
  for k,v in pairs(t) do
    if attrs[v] then
      sattr = attrs[v]
      if #sattr > 40 then
        sattr = table.concat(_wordwap:match(sattr),'\n')
      end
      s = s .. '  ' .. v .. ':' .. _quote:match(sattr)
    end
  end
  return s
end

function labelize(name)
  local n = _countpop:match(name)
  if n and n > 1 then
    return string.format('#pop(%d)%s', n, name:sub(n * 4 + 1))
  end
  return name
end

print('digraph G {')
print('  compound=true;ratio=auto')
for ictx,ctx in pairs(ctxs.children) do
  local ctxname = ctx.attrs.name
  if not matchctx(ctxname, exclude) or matchctx(ctxname, include) then
    local color = computeColor(ctxname)
    print('  subgraph cluster' .. ictx .. ' {')
    print('    "' .. ctxname .. '" [shape=box,style=filled,color=' .. color .. '];')
    local name = ctxname
    for irule,rule in pairs(ctx.children) do
      io.write('    "' .. name .. '" -> "')
      name = ctxname .. '-' .. irule .. '-' .. rule.tag
      print(name .. '" [style=dashed,color=' .. color .. '];')

      local a = ''
      if rule.tag == 'IncludeRules' then
        a = '  ' .. rule.attrs.context
      else
        if not rule.attrs['attribute'] then
          rule.attrs.attribute = ctx.attrs.attribute
        end
        a = a .. stringifyattrs(t1, rule.attrs)
        local a2 = stringifyattrs(t2, rule.attrs)
        if #a2 ~= 0 then
          a = a .. '\n' .. a2
        end
      end
      print('    "' .. name .. '" [label="' .. rule.tag .. a .. '"];')
    
      if rule.attrs.lookAhead == 'true' then
        print('    "' .. name .. '" [color=blue];')
      end

      if rule.attrs.context == '#stay' then
        print('    "' .. name .. '" -> "' .. ctxname .. '" [color=dodgerblue3];')
      elseif rule.attrs.context and rule.attrs.context:byte(1) == sharp then
        print('    "' .. name .. '" -> "' .. ctxname .. '-' .. rule.attrs.context .. '" [color=' .. color .. '];')
        print('    "' .. ctxname .. '-' .. rule.attrs.context .. '" [label="' .. labelize(rule.attrs.context) .. '"];')
      end
    end

    local fallthroughCtx = ctx.attrs.fallthroughContext
    if not fallthroughCtx then
      print('    "' .. name .. '" -> "' .. ctxname .. '" [style=dashed,color=' .. color .. '];')
    elseif fallthroughCtx:byte(1) == sharp then
      local fallthroughNameCtx = ctxname .. '-' .. fallthroughCtx
      print('    "' .. name .. '" -> "' .. fallthroughNameCtx .. '" [style=dashed,color=' .. color .. '];')
      print('    "' .. fallthroughNameCtx .. '" [label="' .. labelize(fallthroughCtx) .. '"];')
    end

    local endCtx = ctx.attrs.lineEndContext
    if endCtx == '#stay' then
      print('    "' .. ctxname .. '" -> "' .. ctxname .. '" [style=dotted,color=blue];')
    elseif endCtx:byte(1) == sharp then
      local lineEndCtx = ctxname .. '-' .. endCtx
      print('    "' .. ctxname .. '" -> "' .. lineEndCtx .. '" [style=dotted,color=blue];')
      print('    "' .. lineEndCtx .. '" [label="' .. labelize(endCtx) .. '"];')
    end

    print('  }')

    if fallthroughCtx then
      if fallthroughCtx:byte(1) == sharp then
        local lastCtx = _jumptxt:match(fallthroughCtx)
        if lastCtx then
          print('  "' .. ctxname .. '-' .. fallthroughCtx .. '" -> "' .. lastCtx .. '" [style=dashed,color=' .. color .. '];')
        end
      else
        print('  "' .. name .. '" -> "' .. fallthroughCtx .. '" [style=dashed,color=' .. color .. '];')
      end
    end

    if endCtx:byte(1) == sharp then
      local lastCtx = _jumptxt:match(endCtx)
      if lastCtx then
        print('  "' .. ctxname .. '-' .. endCtx .. '" -> "' .. lastCtx .. '" [style=dotted,color=' .. color .. '];')
      end
    else
      print('  "' .. ctxname .. '" -> "' .. endCtx .. '" [style=dotted,color=' .. color .. '];')
    end

    for irule,rule in pairs(ctx.children) do
      if rule.attrs.context then
        if rule.attrs.context:byte(1) ~= sharp then
          print('  "' .. ctxname .. '-' .. irule .. '-' .. rule.tag .. '" -> "' .. rule.attrs.context .. '" [color=' .. color .. '];')
        else
          local bindctxname = _jumptxt:match(rule.attrs.context)
          if bindctxname then
            local name = ctxname .. '-' .. rule.attrs.context
            print('  "' .. name .. '" -> "' .. bindctxname .. '" [color=' .. color .. '];')
            print('  "' .. name .. '" [color=red];')
          end
        end
      end
    end
  end
end
print('}')
