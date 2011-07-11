-- AST-specific functions / methods / setup goes here
--module "AST"

local ffi = require "ffi"
AST = { }
local indenter = " "

ffi.cdef(io.input("ast-one.h"):read("*a"))
ffi.cdef[[
    extern const struct node_rec node_recs[];
    //extern const struct node_parentage node_parentages[];
    int fmt_call(enum meta_type meta, int type, int *size, char buf[], void *data);
]]
libast = ffi.load("libast.so")

-- TODO move to toycen.c ?
Tp_translation_unit = ffi.typeof("T_translation_unit*")

-- XXX naughty ?
local function isnull(what)
    if not what then return true end
    if type(what) == "nil" then return true end
    return ffi.cast('void*',what) == ffi.cast('void*',0)
    --return ffi.cast('intptr_t',ffi.cast('void*',what)) == 0
end

function nodetype(str)
    return ffi.cast("enum node_type",str)
end

function decode_node_item(node_item,parent)
    local table = {
        [tonumber(ffi.cast("enum meta_type", "META_IS_NODE"  ))] = node_item.c.node,
        [tonumber(ffi.cast("enum meta_type", "META_IS_PRIV"  ))] = node_item.c.priv,
        [tonumber(ffi.cast("enum meta_type", "META_IS_ID"    ))] = node_item.c.id,
        -- XXX
        --[tonumber(ffi.cast("enum meta_type", "META_IS_CHOICE"))] = node_item.c.choice[parent.idx],
        [tonumber(ffi.cast("enum meta_type", "META_IS_BASIC" ))] = node_item.c.basic,
    }
    return table[node_item.meta]
end

function ffi.sameptr(a,b)
    return ffi.cast('void*',a) == ffi.cast('void*',b)
end

function type_from_node_enum(x)
    return ffi.typeof("T_" .. ffi.string(libast.node_recs[x].name))
end

function AST.walk(node,nodetype,parent,indent)
    if isnull(node) then return nil end
    if not indent then indent = 0 end

    local fields = ffi.fields(node)
    local mytype = ffi.typeof(node)
    local mytag  = ffi.tagof(node)
    local myns   = ffi.nsof(node)

    if myns == "union" then

        --print "XXX UNIMPLEMENTED"
        if parent.idx > 0 then
            --for q=1,indent do io.write(indenter) end
            --print(node[fields[parent.idx]])
            local child = node[fields[parent.idx]]
            for q=1,indent do io.write(indenter) end
            print(fields[parent.idx],child)
            AST.walk(child, nil, parent, indent+1)
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
            local itemindex = j
            --if ffi.istype("struct node *",node) then itemindex = i else itemindex = k end
            if ffi.istype("struct node",node) then itemindex = 0 end
            local child = node[v]
            --print(k,j,v,type(child),myns,child)
            --if indent then for i=1,indent do io.write(indenter) end else indent = 0 end
            for q=1,indent do io.write(indenter) end
            --print(ffi.sameptr(node, child))

            local printed
----[[
            local base = ffi.cast("struct node *", node)
            local mytag = ffi.tagof(node)
            --print("mytag = ", mytag)
            --if type(tonumber(mytag)) ~= nil then
            if not mytag:find("%d+") then
                local mytype = ffi.typeof("T_" .. mytag)
                --print("mytype = ", mytype)
                local myrec = libast.node_recs[ffi.cast("enum node_type", "NODE_TYPE_" .. mytag)]
                --print("myrec = ", myrec)
                local me = libast.node_recs[myrec.type]
                --local me = libast.node_recs[base.node_type]
                --nodetype = nodetype or type_from_node_enum(base.node_type)
                nodetype = nodetype or type_from_node_enum(myrec.type)
                --print("THE TYPE IS ", nodetype)

    ----[[
                local item = me.items[itemindex]
                --print("itemindex",itemindex)
                if itemindex >= 0 then
                    --print("XXX", dump(ffi.fields(me)))
                    --print("XXX", i,itemindex,k)
                    --print("meta=", item.meta)
                    local qqq = { idx = 0 }
    ----[[
                    local dc = decode_node_item(item,qqq)
                        --print "GGG"
                        --print(dc)
                        --print(type(dc) == "nil")
                        --print(item)
                    if dc and not isnull(dc) then
                        --print "GGG"
                        local size = 100;
                        local psize = ffi.new("int[1]", size)
                        --local buf = ffi.gc(ffi.C.malloc(size),ffi.C.free)
                        local buf = ffi.new("char[?]", size)
                        local data2, data
                        local what = child
                        if type(what) == "number" then data2 = ffi.new("uint64_t[1]", what);
                        --elseif ffi.istype("uint64_t", what) then data2 = ffi.new("uint64_t[1]", what)
                        elseif ffi.istype("uint64_t", what) then data = ffi.new("uint64_t[1]", what)
                        elseif ffi.istype("const char *", what) then data2 = what
                        --else data2 = ffi.new("void*[1]", what)
                        end
                        data = data or ffi.new("void*[1]", data2)
                        --local data = ffi.new("void*[1]", ffi.cast('void*',child))

                        local result = libast.fmt_call(item.meta, dc.type, psize, buf, data)
                        --local result = libast.fmt_call("META_IS_ID", 2, psize, buf, data)
                        --print("YYY",result,ffi.string(buf))
                        if result >= 0 then
                            print(v,ffi.string(buf))
                        else
                            print(v,child)
                        end
                        printed = true
                    end
    --]]
                end
    --]]

                local childtype
                if type(child) == "cdata" and ffi.sameptr(node, child) then
                    childtype = type_from_node_enum(libast.node_parentages[me.type].base)
                else
                    if dc and not isnull(dc) then
                        -- segfault (no more ?)
                        --print "PRE"
                        childtype = type_from_node_enum(dc.type)
                        --print "POST"
                    end
                end
                --print("THE CHILD TYPE IS ", childtype)
            end

            if not printed then
                print(v,child)
            end
            -- abort trap when we're a cdata but not a node
            if type(child) == "cdata" and ffi.nsof(child) then
                AST.walk(child,childtype,node,indent+1)
            end
        end

    else
        print "XXX ERRAZ"
    end

end

