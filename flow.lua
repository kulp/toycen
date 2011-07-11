-- "main program" from the lua POV
local ffi = require "ffi"

--[[
require "dumper"
-- Define a shortcut function for testing
function dump(...)
  print(DataDumper(...), "\n---")
end
--]]

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

--print(ffi.typeof(ast.base.node_type))

local function printcb(level,k,v)
    local indenter = " "
    for q=1,level do io.write(indenter) end
    print(k,v)
end

-- TODO define better API for errors
local function errorcb(msg)
    print(msg)
end

AST.walk(ast,printcb,errorcb)

--[[
--print(AST.node_rec(1))
--rec = libast.node_recs[ffi.cast("enum node_type","NODE_TYPE_node")]
rec = libast.node_recs[nodetype("NODE_TYPE_integer")]
for k,v in pairs(ffi.fields(rec)) do
    print(k,v)
    print(rec[v])
end
print(rec.items[0])
print(ffi.string(rec.items[0].c.node.name))

local size = 100;
local psize = ffi.new("int[1]", size)
--local buf = ffi.gc(ffi.C.malloc(size),ffi.C.free)
local buf = ffi.new("char[?]", size)
local data = ffi.new("int[1]", 999);
--print(libast.fmt_call(0,0,nil,nil,nil))
print(libast.fmt_call("META_IS_BASIC",ffi.cast("enum basic_type","BASIC_TYPE_int"),psize,buf,data))
print(libast.fmt_call(5,6,psize,buf,data))
print(ffi.string(buf))
--]]

--print(libast.node_recs[1])

