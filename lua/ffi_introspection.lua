-- ffi introspection support goes here
--module "ffi_instrospection"
local ffi = require("ffi")
require "libljffifields"
ffi.fields = ffi_fields

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

function ffi.subtypeof(n)
	x = tostring(n)
	-- XXX hacky
	str,count = x:gsub("c%w*<(.+)>.*$", "%1")
	if count ~= 1 then return nil else return str end
end

function ffi.nameof(n)
	return ffi.nsof(n) .. " " .. ffi.tagof(n)
end

function ffi.sameptr(a,b)
    return ffi.cast('void*',a) == ffi.cast('void*',b)
end

function ffi.isnull(what)
    return not what or ffi.sameptr(what,ffi.cast('void*',0))
end

return ffi

