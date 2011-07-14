-- AST-specific functions / methods / setup goes here
--module "AST"

local ffi = require "ffi"
require "ffi_introspection"

AST = { }

ffi.cdef(io.input("ast-one.h"):read("*a"))
ffi.cdef[[
    extern const struct node_rec node_recs[];
    int fmt_call(enum meta_type meta, int type, int *size, char buf[], void *data);
]]
local libast = ffi.load("libast.so")

local function decode_node_item(node_item,parent)
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

-- TODO remove if not used
local function type_from_node_enum(x)
    return ffi.typeof("T_" .. ffi.string(libast.node_recs[x].name))
end

-- XXX hokey priv-detection (trailing underscore ? is this official ?)
local function rec_from_tag(mytag)
    local stem = (mytag:sub(-1) == "_") and "priv_type"  or "node_type"
    return libast.node_recs[ffi.cast("enum "..stem, stem:upper()..'_'..mytag)]
end

-- XXX hokey check for anonymous aggregate
local function is_anonymous(mytag)
    return not mytag:find("%d+")
end

local function doformat(userdata,callbacks,indent,k,v,node,child,parent)
    -- k         is the one -based index of the ordered fields in 'node'
    -- itemindex is the zero-based index corresponding to k, with 'base' discounted
    -- itemindex indexes into the C structures (node_rec.items[])
    local itemindex = k - 2
    -- XXX get rid of special ("base") case
    if ffi.istype("struct node",node) then itemindex = 0 end

    local done
    local mytag = ffi.tagof(node)
    if is_anonymous(mytag) and itemindex >= 0 then
        -- TODO breaks on inners (like assignment_inner_)
        local myrec = rec_from_tag(mytag)
        local me = libast.node_recs[myrec.type]

        local item = me.items[itemindex]
        local dc = decode_node_item(item)
        if not ffi.isnull(dc) then
            local size  = 128
            local psize = ffi.new("int[1]", size)
            local buf   = ffi.new("char[?]", size)
            local data, pdata

            -- XXX get rid of special cases
            if type(child) == "number" then data = ffi.new("int[1]", child);
            elseif ffi.istype("uint64_t", child) then pdata = ffi.new("uint64_t[1]", child)
            elseif ffi.istype("char *", child) then data = child
            end

            pdata = pdata or ffi.new("void*[1]", data)

            local result = libast.fmt_call(item.meta, dc.type, psize, buf, pdata)
            if result >= 0 then
                callbacks.walk(userdata,indent,v,ffi.string(buf))
                done = true
            end
        end
    end

    if not done then
        callbacks.walk(userdata,indent,v,child)
    end
end

function AST.walk(node,userdata,callbacks,parent,indent)
    if type(node) ~= "cdata" or not ffi.nsof(node) or ffi.isnull(node) then return nil end
    if not indent then indent = 0 end
    -- TODO don't change incoming callbacks table
    callbacks.walk  = callbacks.walk  or function() end
    callbacks.error = callbacks.error or function() end

    local fields = ffi.fields(node)
    local myns   = ffi.nsof(node)

    if myns == "union" then

        if parent.idx > 0 then
            if parent.idx >= #fields then
                callbacks.error(userdata,"bad index " .. parent.idx)
                return nil
            end
            local child = node[fields[parent.idx]]
            callbacks.walk(userdata,indent,fields[parent.idx],child)
            AST.walk(child,userdata,callbacks,parent,indent+1)
        end

    elseif myns == "struct" then

        for k,v in ipairs(fields) do
            local child = node[v]
            doformat(userdata,callbacks,indent,k,v,node,child,parent)
            AST.walk(child,userdata,callbacks,node,indent+1)
        end

    else
        callbacks.error(userdata,"Unsupported namespace:" .. myns)
    end

end

