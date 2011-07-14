-- utilities
local ffi = require "ffi"
function include_h(file)
    ffi.cdef(io.input(file):read("*a"))
end

-- construct a one-element typed array containing the argument
-- (useful for "pass-by-reference" or "pass a pointer to" semantics)
function   box(what, T) return ffi.new((T or ffi.typeof(what)).."[1]", what) end
function unbox(what, T) return T and ffi.cast(T.."*", what)[0] or what[0] end

