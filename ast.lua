local ffi = require "ffi"
require "libfields"
AST = { }
local indenter = " "

--ffifields = ffi.fields
local ffifields = ffi_fields

-- XXX naughty ?
local function isnull(what)
    return ffi.cast('intptr_t',ffi.cast('void*',what)) == 0
end

local __walkchoice, __walkinner

function __walkchoice(ast, i, indent)
    local f = ffifields(ast)
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
    for k,v in ipairs(ffifields(ast)) do
        __walkinner(ast, v, indent)
    end
end

AST.walk(ast)

-- vi: set ts=4 sw=4 et nocindent noai syntax=lua
