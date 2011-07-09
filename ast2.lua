-- AST-specific functions / methods / setup goes here
--module "AST"

local ffi = require "ffi"
AST = { }
local indenter = " "

ffi.cdef(io.input("ast-one.h"):read("*a"))
ffi.cdef[[
    extern const struct node_rec node_recs[];
    int fmt_call(enum meta_type meta, int type, int *size, char buf[], void *data);
]]
libast = ffi.load("libast.so")

-- TODO move to toycen.c ?
Tp_translation_unit = ffi.typeof("T_translation_unit*")

-- XXX naughty ?
local function isnull(what)
    return ffi.cast('intptr_t',ffi.cast('void*',what)) == 0
end

function nodetype(str)
    return ffi.cast("enum node_type",str)
end

function decode_node_item(node_item)
    local table = {
        [tonumber(ffi.cast("enum meta_type", "META_IS_NODE"  ))] = node_item.c.node,
        [tonumber(ffi.cast("enum meta_type", "META_IS_PRIV"  ))] = node_item.c.priv,
        [tonumber(ffi.cast("enum meta_type", "META_IS_ID"    ))] = node_item.c.id,
        [tonumber(ffi.cast("enum meta_type", "META_IS_CHOICE"))] = node_item.c.choice,
        [tonumber(ffi.cast("enum meta_type", "META_IS_BASIC" ))] = node_item.c.basic,
    }
    return table[node_item.meta]
end

function AST.walk(node,parent,indent)
    if isnull(node) then return nil end
    if not indent then indent = 0 end

    local fields = ffi.fields(node)
    local mytype = ffi.typeof(node)
    local mytag  = ffi.tagof(node)
    local myns   = ffi.nsof(node)

    if myns == "union" then

        --print "XXX UNIMPLEMENTED"
        if parent.idx > 0 then
			--for q=0,indent do io.write(indenter) end
            --print(node[fields[parent.idx]])
            AST.walk(node[fields[parent.idx]], parent, indent)
        end

    elseif myns == "struct" then

        --local ntype  = ffi.cast("struct node *", node).node_type
        -- segfault when unnamed (union-wrapping) struct
        --local nname = ffi.string(libast.node_recs[ntype].name)
        for k,v in ipairs(fields) do
            -- k is the one-based index of the ordered fields in 'node'
            -- i is the zero-based index corresponding to k
            -- j is the zero-based index corresponding to k, with 'base' discounted
            local i = k - 1
            local j = i - 1
            local child = node[v]
            --print(k,j,v,type(child),myns,child)
            --if indent then for i=1,indent do io.write(indenter) end else indent = 0 end
			for q=0,indent do io.write(indenter) end
            print(v,child)
            -- abort trap when we're a cdata but not a node
            if type(child) == "cdata" and ffi.nsof(child) then
                AST.walk(child,node,indent+1)
            end
        end

    else
        print "XXX ERRAZ"
    end

end

