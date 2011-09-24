-- AST-specific functions / methods / setup goes here
--module "AST"

local ffi = require "ffi"
local bit = require "bit"
require "ffi_introspection"
require "utils"

AST = { flag_names = { } }

include_h("ast-one.h")

-- TODO pull from ast-walk.h
AST.WALK_BEFORE_CHILDREN  =  1; AST.flag_names[AST.WALK_BEFORE_CHILDREN ] = "WALK_BEFORE_CHILDREN"
AST.WALK_AFTER_CHILDREN   =  2; AST.flag_names[AST.WALK_AFTER_CHILDREN  ] = "WALK_AFTER_CHILDREN"
AST.WALK_BETWEEN_CHILDREN =  4; AST.flag_names[AST.WALK_BETWEEN_CHILDREN] = "WALK_BETWEEN_CHILDREN"
AST.WALK_PRUNE_SIBLINGS   =  8; AST.flag_names[AST.WALK_PRUNE_SIBLINGS  ] = "WALK_PRUNE_SIBLINGS"
AST.WALK_IS_BASE          = 16; AST.flag_names[AST.WALK_IS_BASE         ] = "WALK_IS_BASE"
AST.WALK_HAS_ALLOCATION   = 32; AST.flag_names[AST.WALK_HAS_ALLOCATION  ] = "WALK_HAS_ALLOCATION"

AST.fl = {
    is_before  = function (x) return bit.band(x, AST.WALK_BEFORE_CHILDREN ) ~= 0 end,
    is_after   = function (x) return bit.band(x, AST.WALK_AFTER_CHILDREN  ) ~= 0 end,
    is_between = function (x) return bit.band(x, AST.WALK_BETWEEN_CHILDREN) ~= 0 end,
    is_prune   = function (x) return bit.band(x, AST.WALK_PRUNE_SIBLINGS  ) ~= 0 end,
    is_base    = function (x) return bit.band(x, AST.WALK_IS_BASE         ) ~= 0 end,
    is_alloc   = function (x) return bit.band(x, AST.WALK_HAS_ALLOCATION  ) ~= 0 end,
}

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
    local stem = (tag:sub(-1) == "_") and "priv_type" or "node_type"
    return libast.node_recs[ffi.cast("enum "..stem, stem:upper()..'_'..tag)]
end

-- XXX hokey check for anonymous aggregate
local function is_anonymous(tag) return tag:find("%d+") end

-- XXX get rid of special cases
local function box_child(child)
    local data, pdata
        if type(child) == "number"       then  data = box(child, "int")
    elseif ffi.istype("char *"  , child) then  data = child
    elseif ffi.istype("uint64_t", child) then pdata = box(child, "uint64_t")
    end

    return pdata or box(data, "void*")
end

local function doformat(userdata, flags, callbacks, level, k, v, node, child, parent, item, unwrap)
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
    -- is itemindex ever < 0 ? when ?
    if item or (not is_anonymous(tag) and itemindex >= 0) then
        if not item then
            item = libast.node_recs[ rec_from_tag(tag).type ].items[ itemindex ]
        end
        local dc = decode_node_item(item)
        if not ffi.isnull(dc) then
            local size  = 128
            local psize = ffi.new("int[1]", size)
            local buf   = ffi.new("char[?]", size)
            if item.is_pointer then flags = bit.bor(flags, AST.WALK_HAS_ALLOCATION) end

            --if unwrap then child = unbox(child) end
            local temp
            if unwrap then temp = box(child, "int") else temp = box_child(child) end
            --print("item.name=", ffi.string(item.name),child, temp)
            local result = libast.fmt_call(item.meta, dc.type, psize, buf, temp)
            if result >= 0 then
                -- subtract one from *size to not print trailing '\0'
                callbacks.walk(userdata, flags, level, v, ffi.string(buf, unbox(psize) - 1))
                done = true
            end
        end
    end

    if not done then
        callbacks.walk(userdata, flags, level, v, child)
    end
end

-- the "pitem" is necessary to support / work around the anonymous unions
-- and structs that make up CHOICE elements ; the pitem will be a struct
-- with a tag, so it can be looked up in libast.node_recs
-- the "pitem" element is not of the same type as "parent" : parent is a
-- cdata node, pitem is a node_rec element
function AST.walk(node, userdata, callbacks, flags, parent, level, pitem)
    if type(node) ~= "cdata" or not ffi.nsof(node) or ffi.isnull(node) then return nil end
    if not level then level = 1 end -- 1-based for array indexing
    if not flags then flags = 0 end
    -- TODO don't change incoming callbacks table
    callbacks.walk  = callbacks.walk  or function() end
    callbacks.error = callbacks.error or function() end

    callbacks.walk(userdata, bit.bor(flags, AST.WALK_BEFORE_CHILDREN), level, nil, node)

    local fields = ffi.fields(node)
    local myns   = ffi.nsof(node)

    if myns == "union" then

        if parent.idx > 0 then
            if parent.idx >= #fields then
                callbacks.error(userdata,"bad index " .. parent.idx)
                return nil
            end
            local child = node[fields[parent.idx]]
            local item = pitem[parent.idx - 1] -- switch to C (zero-based) indexing
            local cflags = bit.bor(flags, AST.WALK_BETWEEN_CHILDREN)
            if item.is_pointer then cflags = bit.bor(cflags, AST.WALK_HAS_ALLOCATION) end
            -- XXX hack
            -- basic elements inside a choice act funny
            -- TODO make this work for .idx in choices too
            local basic = item.meta == tonumber(ffi.cast("enum meta_type", "META_IS_BASIC"))
            doformat(userdata, cflags, callbacks, level, 0, fields[parent.idx], node, child, parent, item, basic)
            AST.walk(child, userdata, callbacks, flags, parent, level + 1, pitem)
        end

    elseif myns == "struct" then

        for k, v in ipairs(fields) do
            local flags = flags
            local child = node[v]
            if k == 1 and type(child) == "cdata" then
                flags = bit.bor(flags, AST.WALK_IS_BASE)
            elseif k ~= 1 then
                flags = bit.band(flags, bit.bnot(AST.WALK_IS_BASE))
            end
            local cflags = bit.bor(flags, AST.WALK_BETWEEN_CHILDREN)

            local pitem = pitem -- shadow argument for local changes per child
            -- only upgrade parent to pitem when we are dealing with a named
            -- struct
            if not is_anonymous(ffi.tagof(node)) then
                local itemindex = ffi.istype("struct node", node) and k - 1 or k - 2
                -- note that pitem is not always meaningful ; it might be
                -- garbage, but it's only accessed (in the union branch above)
                -- if it is meaningful
                pitem = libast.node_recs[ rec_from_tag(ffi.tagof(node)).type ].items[ itemindex ].c.choice
            end

            doformat(userdata, cflags, callbacks, level, k, v, node, child, parent)
            AST.walk(child, userdata, callbacks, flags, node, level + 1, pitem)
        end

    else
        callbacks.error(userdata,"Unsupported namespace:" .. myns)
    end

    callbacks.walk(userdata, bit.bor(flags, AST.WALK_AFTER_CHILDREN), level, nil, node)

end

-- vi:set ts=4 sw=4 et nocindent ai linebreak syntax=lua
