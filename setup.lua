ffi = require("ffi")
ffi.cdef(io.input("ast-one.h"):read("*a"))
ffi.cdef[[
extern const struct node_rec node_recs[];
]]
libast = ffi.load("libast.so")

feelds = ffi.fields("struct node_rec")

local tu_mt = {
	__index = {
		foo = function(x) return ffi.fields((ffi.typeof(x))()) end,
	},
}
T_node = ffi.metatype("T_node", {})
T_function_definition = ffi.metatype("T_function_definition", {})
T_translation_unit = ffi.metatype("T_translation_unit", tu_mt)
Tp_translation_unit = ffi.typeof("T_translation_unit*")

function node_rec(e)
	return ffi.string(libast.node_recs[e].name)
end

-- XXX hacky
function ffi.nsof(n)
	x = tostring(n)
	if x:find("c%w*<union") then return "union" end
	if x:find("c%w*<struct") then return "struct" end
	if x:find("c%w*<enum") then return "enum" end
	return nil
end

function ffi.tagof(n)
	x = tostring(n)
	-- XXX hacky
	-- TODO enums
	str,count = x:gsub("c%w*<(%S+) (%S+)[ *&]*>.*$", "%2")
	if count ~= 1 then return nil else return str end
end

function ffi.nameof(n)
	return ffi.nsof(n) .. " " .. ffi.tagof(n)
end

local n = T_node("NODE_TYPE_expression");
local f = T_function_definition(T_node("NODE_TYPE_expression"));

--print(f.base.node_type)
--print(ffi.string(libast.node_recs[f.base.node_type].name))
--print(node_rec(f.base.node_type))
--print(tostring(Tp_translation_unit))
--print(ffi_tagof("hi"))
--print(ffi.tagof(Tp_translation_unit))
--print(ffi.deref(T_translation_unit))
--print(ffi.deref(Tp_translation_unit))
--foolds = ffi.fields(ffi.typeof(ffi.nameof(Tp_translation_unit)))
--foolds = ffi.fields(ffi.typeof(ffi_nsof(Tp_translation_unit).." "..ffi_tagof(Tp_translation_unit)))
--foolds = ffi.fields(ffi.typeof("T_translation_unit"))
--for k,v in pairs(foolds) do print(k,v) end
--for k,v in pairs(feelds) do print(k,v) end

