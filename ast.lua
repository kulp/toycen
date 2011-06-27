AST = { }
indenter = "	"
function AST.walk(ast, indent)
    --print(ast)
	--print(ffi.fields(ast))
    --f = ffi.fields(ffi.nameof(ffi.typeof(ast)))
    f = ffi.fields(ast)
	print(ffi.cast("void**",ast))
	print(ffi.nsof(ast))
    for k,v in ipairs(f) do
		print("2")
        if indent then for i=1,indent do io.write(indenter) end else indent = 0 end
		print("3")
		print(tostring(ast[v]))
			print("4")
        if ffi.nsof(ast[v]) ~= nil then
			print("4")
			if ffi.nsof(ast[v]) == "struct" then
				print("5")
				print(v)
				--print("descending into " .. v)
				AST.walk(ast[v], indent+1)
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
