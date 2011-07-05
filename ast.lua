AST = { }
indenter = "	"

-- XXX naughty ?
function isnull(what)
    return ffi.cast('uintptr_t',ffi.cast('void*',what)) == 0
end

function AST.walk(ast, indent)
    --print(ast)
    --print(ffi.fields(ast))
    --f = ffi.fields(ffi.nameof(ffi.typeof(ast)))
    f = ffi.fields(ast)
    --print(ffi.cast("void**",ast))
    --print(ffi.nsof(ast))
    --print("foo=",ffi.deref(ast))
    --if (not ffi.deref(ast)) then print "wooble !" end
    --print(pcall(ffi.cast, 'void*', ast))
    --print(pcall(ffi.cast, ffi.typeof(ast), nil))
    --print(pcall(ffi.deref, ast))
    for k,v in ipairs(f) do
        --print("2")
        if indent then for i=1,indent do io.write(indenter) end else indent = 0 end
        --print("3")
        if ffi.nsof(ast[v]) ~= nil then
            --print("4")
            if ffi.nsof(ast[v]) == "struct" then
                --print("5")
                print(v)
                --print("descending into " .. v)
                if not isnull(ast[v]) then
                    AST.walk(ast[v], indent+1)
                end
            else
                -- TODO
                print(v)
            end
        else
            print(v)
        end
    end
end

--print(ast)
--ffi.typeof(ast)
--AST.walk(ast)
--print(ast.right)
--AST.walk(ast.right)
--print(ast.base)
--print(ffi.nsof(ast.base))
--AST.walk(ast.base)
--print(ffi.cast(ffi.typeof("void*"), ast.left))
--print(ffi.cast("void*", ast.right) == nil)
AST.walk(ast)

-- vi: set ts=4 sw=4 et nocindent noai syntax=lua
