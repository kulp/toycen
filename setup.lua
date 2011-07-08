local ffi = require("ffi")
require "ffi_fields"

ffi.cdef(io.input("ast-one.h"):read("*a"))
ffi.cdef[[
extern const struct node_rec node_recs[];
]]
libast = ffi.load("libast.so")

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

