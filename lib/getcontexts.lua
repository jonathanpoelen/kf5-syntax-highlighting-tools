#!/usr/bin/env lua

require('lib/xmllpegparser')

local xmlparser = xmllpegparser

local child = function(elem, path)
  local p, i, s, k, v = 1, 1
  while i do
    i = path:find('/', p, true)
    if i then
      s = path:sub(p, i - 1)
      p = i + 1
    else
      s = path:sub(p)
    end

    for k,v in pairs(elem.children) do
      if (v.tag == s) then
        elem = v
        break
      end
    end
  end
  
  return elem
end

function getcontexts(filename, replaceEntities)
  local document, e = xmlparser.parseFile(filename)
  if not document then
    io.stderr:write(e .. '\n')
    os.exit(1)
  end

  local ctxs = child(document, 'language/highlighting/contexts')
  
  if replaceEntities then
    local entities = xmlparser.createEntityTable(document.entities)

    for _,ctx in pairs(ctxs.children) do
      for _,rule in pairs(ctx.children) do
        if rule.attrs.String then
          rule.attrs.String = xmlparser.replaceEntities(rule.attrs.String, entities)
        end
      end
    end
  end
  
  return ctxs
end

return getcontexts
