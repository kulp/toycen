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
        -- We don't decode choices because those are handled otherwise
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

local function doformat(indent,k,v,node,nodetype,child,parent)
    for q=1,indent do io.write(indenter) end

    local i = k - 1
    local j = i - 1
    local itemindex = j
    if ffi.istype("struct node",node) then itemindex = 0 end

    local printed
    local mytag = ffi.tagof(node)
    if not mytag:find("%d+") then
        -- TODO breaks on inners (like assignment_inner_)
        local myrec = libast.node_recs[ffi.cast("enum node_type", "NODE_TYPE_" .. mytag)]
        local me = libast.node_recs[myrec.type]
        nodetype = nodetype or type_from_node_enum(myrec.type)

        local item = me.items[itemindex]
        if itemindex >= 0 then
            local dc = decode_node_item(item)
            if dc and not isnull(dc) then
                local size = 100;
                local psize = ffi.new("int[1]", size)
                local buf = ffi.new("char[?]", size)
                local data, pdata

                -- XXX get rid of special cases
                if type(child) == "number" then data = ffi.new("int[1]", child);
                elseif ffi.istype("uint64_t", child) then pdata = ffi.new("uint64_t[1]", child)
                elseif ffi.istype("const char *", child) then data = child
                end

                pdata = pdata or ffi.new("void*[1]", data)

                local result = libast.fmt_call(item.meta, dc.type, psize, buf, pdata)
                if result >= 0 then
                    print(v,ffi.string(buf))
                    printed = true
                end
            end
        end

        local childtype
        if type(child) == "cdata" and ffi.sameptr(node, child) then
            childtype = type_from_node_enum(libast.node_parentages[me.type].base)
        else
            if dc and not isnull(dc) then
                childtype = type_from_node_enum(dc.type)
            end
        end
    end

    if not printed then
        print(v,child)
    end
end


function AST.walk(node,nodetype,parent,indent)
    if isnull(node) then return nil end
    if not indent then indent = 0 end

    local fields = ffi.fields(node)
    local myns   = ffi.nsof(node)

    if myns == "union" then

        if parent.idx > 0 then
            local child = node[fields[parent.idx]]
            for q=1,indent do io.write(indenter) end
            print(fields[parent.idx],child)
            AST.walk(child, nil, parent, indent+1)
        end

    elseif myns == "struct" then

        for k,v in ipairs(fields) do
            -- k is the one-based index of the ordered fields in 'node'
            -- i is the zero-based index corresponding to k
            -- j is the zero-based index corresponding to k, with 'base' discounted
            local child = node[v]
            doformat(indent,k,v,node,nodetype,child,parent)
            if type(child) == "cdata" and ffi.nsof(child) then
                AST.walk(child,childtype,node,indent+1)
            end
        end

    else
        print "XXX ERRAZ"
    end

end

