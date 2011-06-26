AST = { }
indenter = "	"
function AST.walk(ast, indent)
    --print(ast)
    f = ffi.fields(ffi.nameof(ffi.typeof(ast)))
    for k,v in ipairs(f) do
        if indent then for i=1,indent do io.write(indenter) end else indent = 0 end
        if ffi.nsof(ast[v]) ~= nil then
            print(v)
            --print("descending into " .. v)
            AST.walk(ast[v], indent+1)
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
