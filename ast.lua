-- AST-specific functions / methods / setup goes here

local ffi = require "ffi"
AST = { }
local indenter = " "

ffi.cdef(io.input("ast-one.h"):read("*a"))
ffi.cdef[[
extern const struct node_rec node_recs[];
]]
libast = ffi.load("libast.so")

-- TODO move to toycen.c ?
Tp_translation_unit = ffi.typeof("T_translation_unit*")

-- XXX naughty ?
local function isnull(what)
    return ffi.cast('intptr_t',ffi.cast('void*',what)) == 0
end

local __walkchoice, __walkinner

function __walkchoice(ast, i, indent)
    local f = ffi.fields(ast)
    local v = f[i]
    if (v) then
        return __walkinner(ast, v, indent)
    end
end

function __walkinner(ast, v, indent)
    if indent then for i=1,indent do io.write(indenter) end else indent = 0 end
    if ffi.nsof(ast[v]) ~= nil then
        if ffi.nsof(ast[v]) == "union" then
            print(v)
            if not isnull(ast[v]) then
                __walkchoice(ast[v], ast.idx, indent+1)
            end
        elseif ffi.nsof(ast[v]) == "struct" then
            print(v)
            if not isnull(ast[v]) then
                AST.walk(ast[v], indent+1)
            end
        else
            print(v)
        end
    else
        print(v)
    end
end

function AST.walk(ast, indent)
    for k,v in ipairs(ffi.fields(ast)) do
        __walkinner(ast, v, indent)
    end
end

function AST.node_rec(e)
	return ffi.string(libast.node_recs[e].name)
end

-- vi: set ts=4 sw=4 et nocindent noai syntax=lua
