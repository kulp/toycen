-- AST-specific functions / methods / setup goes here
--module "AST"

local ffi = require "ffi"
require "ffi_introspection"
require "utils"

AST = { }

include_h("ast-one.h")

local libast = ffi.load("libast.so")

local function decode_node_item(node_item)
    local table = {
        [tonumber(ffi.cast("enum meta_type", "META_IS_NODE"  ))] = node_item.c.node,
        [tonumber(ffi.cast("enum meta_type", "META_IS_PRIV"  ))] = node_item.c.priv,
        [tonumber(ffi.cast("enum meta_type", "META_IS_ID"    ))] = node_item.c.id,
        -- We don't decode choices because those are handled otherwise
        [tonumber(ffi.cast("enum meta_type", "META_IS_BASIC" ))] = node_item.c.basic,
    }
    return table[node_item.meta]
end

-- XXX hokey priv-detection (trailing underscore ? is this official ?)
local function rec_from_tag(tag)
    local stem = (tag:sub(-1) == "_") and "priv_type"  or "node_type"
    return libast.node_recs[ffi.cast("enum "..stem, stem:upper()..'_'..tag)]
end

-- XXX hokey check for anonymous aggregate
local function is_anonymous(tag) return not tag:find("%d+") end

-- XXX get rid of special cases
local function box_child(child)
    local data, pdata
        if type(child) == "number"       then  data = box(child, "int")
    elseif ffi.istype("char *"  , child) then  data = child
    elseif ffi.istype("uint64_t", child) then pdata = box(child, "uint64_t")
    end

    return pdata or box(data, "void*")
end

local function doformat(userdata, callbacks, indent, k, v, node, child, parent)
    -- k         is the one -based index of the ordered fields in 'node'
    -- itemindex is the zero-based index corresponding to k, with 'base' discounted
    -- itemindex indexes into the C structures (node_rec.items[])
    --
    -- in the case of a normal node, k starts at 1, but refers to base, so the
    -- counting as far as node_rec.items is concerned starts at 2. in the case
    -- of a `struct node' (the base type), there is no base, so we adjust.
    local itemindex = ffi.istype("struct node", node) and k - 1 or k - 2

    local done
    local tag = ffi.tagof(node)
    if is_anonymous(tag) and itemindex >= 0 then
        -- TODO breaks on inners (like assignment_inner_)
        local item = libast.node_recs[ rec_from_tag(tag).type ].items[ itemindex ]
        local dc = decode_node_item(item)
        if not ffi.isnull(dc) then
            local size  = 128
            local psize = ffi.new("int[1]", size)
            local buf   = ffi.new("char[?]", size)

            local result = libast.fmt_call(item.meta, dc.type, psize, buf, box_child(child))
            if result >= 0 then
                callbacks.walk(userdata, indent, v, ffi.string(buf, unbox(psize)))
                done = true
            end
        end
    end

    if not done then
        callbacks.walk(userdata, indent, v, child)
    end
end

function AST.walk(node, userdata, callbacks, parent, indent)
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
            callbacks.walk(userdata, indent, fields[parent.idx], child)
            AST.walk(child, userdata, callbacks, parent, indent+1)
        end

    elseif myns == "struct" then

        for k, v in ipairs(fields) do
            local child = node[v]
            doformat(userdata, callbacks, indent, k, v, node, child, parent)
            AST.walk(child, userdata, callbacks, node, indent + 1)
        end

    else
        callbacks.error(userdata,"Unsupported namespace:" .. myns)
    end

end

