local ffi = require("ffi")
ffi.cdef(io.input("ast-one.h"):read("*a"))
ffi.cdef[[
extern const struct node_rec node_recs[];
]]
libast = ffi.load("libast.so")

T_node = ffi.metatype("T_node", {})
T_function_definition = ffi.metatype("T_function_definition", {})
T_translation_unit = ffi.metatype("T_translation_unit", {})
Tp_translation_unit = ffi.typeof("T_translation_unit*")

function node_rec(e)
	return ffi.string(libast.node_recs[e].name)
end

local n = T_node("NODE_TYPE_expression");
local f = T_function_definition(T_node("NODE_TYPE_expression"));

print(f.base.node_type)
--print(ffi.string(libast.node_recs[f.base.node_type].name))
print(node_rec(f.base.node_type))

