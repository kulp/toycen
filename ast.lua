-- AST-specific functions / methods / setup goes here
--module "AST"

local serpent = require "3rdparty/serpent/src/serpent"

local ffi = require "ffi"
local bit = require "bit"
require "ffi_introspection"
require "utils"

AST = { walkers = { }, flag_names = { } }

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
    return table[tonumber(node_item.meta)]
end

local function is_private(tag)
    return tag:sub(-1) == "_"
end

local function node_table(tag)
    local table = is_private(tag) and "priv_recs" or "node_recs"
    return libast[table]
end

-- XXX hokey priv-detection (trailing underscore ? is this official ?)
local function rec_from_tag(tag)
    local stem = is_private(tag) and "priv_type" or "node_type"
    return node_table(tag)[ffi.cast("enum "..stem, stem:upper()..'_'..tag)]
end

local function node_record(tag)
    return node_table(tag)[ rec_from_tag(tag).type ]
end

-- XXX hokey check for anonymous aggregate
local function is_anonymous(tag) return tag:find("%d+") end

-- XXX shouldn't show this externally
function is_enum(cd)
    return ffi.nsof(cd) == "enum"
end

-- XXX get rid of special cases
local function box_child(child)
    local data, pdata
        if type(child) == "number"       then  data = box(child, "int")
    elseif is_enum(child)                then  data = box(tonumber(child), "int")
    elseif ffi.istype("char *"  , child) then  data = child
    elseif ffi.istype("uint64_t", child) then pdata = box(child, "uint64_t")
    end

    return pdata or box(data, "void*")
end

local function doformat(userdata, flags, callbacks, k, v, node, child, parent, item, unwrap)
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

    -- print .idx of choice
    if is_anonymous(ffi.tagof(node)) and k == 1 then
        callbacks.walk(userdata, flags, v, tostring(child))
        done = true
    elseif item or (not is_anonymous(tag) and itemindex >= 0) then -- when is itemindex < 0 ?
        if not item then
            item = node_record(tag).items[ itemindex ]
        end
        local dc = decode_node_item(item)
        if item.is_pointer then
            flags = bit.bor(bit.band(flags, bit.bnot(AST.WALK_IS_BASE)), AST.WALK_HAS_ALLOCATION)
        end
        if not ffi.isnull(dc) then
            local size  = 128
            local psize = ffi.new("int[1]", size)
            local buf   = ffi.new("char[?]", size)

            local temp
            -- XXX explicit box type is not general enough FIXME
            if unwrap then temp = box(child, "int") else temp = box_child(child) end
            local result = libast.fmt_call(item.meta, dc.type, psize, buf, temp)
            if result >= 0 then
                -- subtract one from *size to not print trailing '\0'
                callbacks.walk(userdata, flags, v, ffi.string(buf, unbox(psize) - 1))
                done = true
            end
        end
    end

    if not done then
        callbacks.walk(userdata, flags, v, child)
    end
end

local function should_walk(node)
    return type(node) == "cdata"
        and not ffi.isnull(node)
        and (ffi.nsof(node) == "struct" or ffi.nsof(node) == "union")
end

function AST.walkers.struct(node, userdata, callbacks, flags, parent, pitem)

    local fields = ffi.fields(node)
    for k, v in ipairs(fields) do
        local flags = flags
        local child = node[v]
        local cflags = bit.bor(flags, AST.WALK_BETWEEN_CHILDREN)

        if k == 1 and type(child) == "cdata" then
            flags = bit.bor(flags, AST.WALK_IS_BASE)
        elseif k ~= 1 then
            flags = bit.band(flags, bit.bnot(AST.WALK_IS_BASE))
        end

        local pitem = pitem -- shadow argument for local changes per child
        -- only upgrade parent to pitem when we are dealing with a named
        -- struct
        local is_idx = false
        local should_recurse = false
        if is_anonymous(ffi.tagof(node)) then
            is_idx = k == 1
            should_recurse = true
        elseif (AST.verbose and AST.verbose > 0) or (ffi.tagof(child)) ~= "node" then
            -- don't print `struct node` by default
            local itemindex = ffi.istype("struct node", node) and k - 1 or k - 2
            -- note that pitem is not always meaningful ; it might be
            -- garbage, but it's only accessed (in the union branch above)
            -- if it is meaningful
            pitem = node_record(ffi.tagof(node)).items[ itemindex ].c.choice
            should_recurse = true
        end

        if should_recurse then
            doformat(userdata, cflags, callbacks, k, v, node, child, parent, nil, is_idx)
            AST.walk(child, userdata, callbacks, flags, node, pitem)
        end

    end

end

function AST.walkers.union(node, userdata, callbacks, flags, parent, pitem)

    local fields = ffi.fields(node)
    if parent.idx > 0 then
        if parent.idx >= #fields then
            callbacks.error(userdata,"bad index " .. parent.idx)
            return nil
        end
        local child = node[fields[parent.idx]]
        local item = pitem[parent.idx - 1] -- switch to C (zero-based) indexing
        local cflags = bit.bor(flags, AST.WALK_BETWEEN_CHILDREN)
        if item.is_pointer then
            cflags = bit.bor(cflags, AST.WALK_HAS_ALLOCATION)
        else
            cflags = bit.band(cflags, bit.bnot(AST.WALK_HAS_ALLOCATION))
        end
        -- XXX hack
        -- basic elements inside a choice act funny
        -- TODO make this work for .idx in choices too
        local basic = item.meta == tonumber(ffi.cast("enum meta_type", "META_IS_BASIC"))
        doformat(userdata, cflags, callbacks, 0, fields[parent.idx], node, child, node, item, basic)
        AST.walk(child, userdata, callbacks, flags, parent, pitem)
    end

end

-- the "pitem" is necessary to support / work around the anonymous unions
-- and structs that make up CHOICE elements ; the pitem will be a struct
-- with a tag, so it can be looked up in libast.node_recs / libast.priv_recs
-- the "pitem" element is not of the same type as "parent" : parent is a
-- cdata node, pitem is a node_rec element
function AST.walk(node, userdata, _callbacks, flags, parent, pitem)
    if not should_walk(node) then return nil end
    if not flags then flags = 0 end
    local callbacks = _callbacks
    callbacks.walk  = callbacks.walk  or function() end
    callbacks.error = callbacks.error or function() end

    -- TODO & ~7 (and elsewhere)
    callbacks.walk(userdata, bit.bor(flags, AST.WALK_BEFORE_CHILDREN), nil, node)

    local myns = ffi.nsof(node)
    if AST.walkers[myns] then
        AST.walkers[myns](node, userdata, callbacks, flags, parent, pitem)
    else
        callbacks.error(userdata,"Unsupported namespace:" .. myns)
    end

    callbacks.walk(userdata, bit.bor(flags, AST.WALK_AFTER_CHILDREN), nil, node)

end

-- vi:set ts=4 sw=4 et nocindent ai linebreak syntax=lua
