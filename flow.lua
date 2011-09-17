-- "main program" from the lua POV
local ffi = require "ffi"
local bit = require "bit"

require "tmp/dumper"
--[[
function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
--]]
function dump(...) return DataDumper(...) end

--local function debug(...) print(...) end
local function debug(...) end

--print(ffi.typeof(ast.base.node_type))

local function printcb(ud,flags,level,k,v)
    local indenter = " "
    if 1 or bit.band(flags, AST.WALK_BETWEEN_CHILDREN) ~= 0 then
        for q=1,level do io.write(indenter) end
        print(flags,k,v)
        --print(AST.flag_names[flags],k,v)
        --print(k,v)
        ud.level = level
        ud.path[level+2] = nil
        ud.path[level+1] = k
    end
end

-- TODO stop passing ud/flags/level if not needed
local function format_field_name(ud,flags,level,name)
    return "<td port='" .. name .. "'><font face='courier' color='#777777'>" .. name .. "</font></td>"
end

-- TODO stop passing ud/flags/level if not needed
local function format_field_value(ud,flags,level,i,namespace,value)
    return "<td cellpadding='1' port='port_" .. namespace .. "_" .. i .. "'>" .. value .. "</td>"
end

local function format_field(ud,flags,level,obj,i,k,v)
    return "<tr>"
        .. format_field_name(ud,flags,level,k)
        .. "\t"
        .. format_field_value(ud,flags,level,i,obj,v)
        .. "</tr>\n"
end

local table_format = ' border="0" cellborder="1" cellspacing="0" cellpadding="4"'

local print_node -- to allow mutual recursion with _print_node_inner

local function _print_node_inner(ud,flags,level,i,me)
    local result = ""
    --for L = 1,level do result = result .. "\t" end
    -- TODO pull up
    local base    = bit.band(me.flags, AST.WALK_IS_BASE         ) ~= 0
    local alloc   = bit.band(me.flags, AST.WALK_HAS_ALLOCATION  ) ~= 0

    -- XXX encapsulation
    local anonymous = (me.type or ""):find("%d+")
    local close_table = false

    local simple = not me.type and me.printable
    if simple then
        result = result .. me.printable
    else
        local content = me.type or "XXX" -- TODO trap
        if me.children or alloc and me.null then
            result = result .. "\n<table" .. table_format .. ">\n"
            close_table = true
            if me.children and not anonymous then
                result = result .. "\n<tr><td colspan='2' port='_name' bgcolor='#dddddd'><font point-size='12'>" .. content .. "</font></td></tr>"
            end
            if alloc and me.null then
                result = result .. "<tr><td colspan='2'>NULL</td></tr>"
            end
        end
        if me.children then
            for j,ye in ipairs(me.children) do
                local inner
                if ye.contained then
                    inner = _print_node_inner(ud,flags,level+1,j,ye)
                else
                    table.insert(ud.nodes, print_node(ud,flags,level + 1,j,ye))
                    local linkval = "struct_" .. me.addr .. ":" .. "port_" .. me.type .. "_" .. j .. " -> " ..
                                    "struct_" .. ye.addr .. ":" .. "_name"
                    if not me.null and not ye.null then
                        table.insert(ud.links, linkval)
                    end
                    -- TODO pull up
                    local alloc   = bit.band(ye.flags, AST.WALK_HAS_ALLOCATION  ) ~= 0
                    if alloc then
                        if ye.null then inner = "NULL" else inner = "*" end
                    else
                        inner = ye.printable
                    end
                end
                result = result .. format_field(ud,flags,level+1,me.type,j,ye.name,inner)
            end
        end
        if close_table then result = result .. "</table>\n" end
    end

    return result
end

function print_node(ud,flags,level,i,node)
    if node.null then return "" else return
            "struct_" .. node.addr .. " [label=<"
        .. _print_node_inner(ud,flags,level + 1,i,node)
        .. ">];"
    end
end

-- TODO what we need is an is_pointer in the walk flags or arguments
local function gv2(ud,flags,level,k,v)
    local before   = bit.band(flags, AST.WALK_BEFORE_CHILDREN ) ~= 0
    local after    = bit.band(flags, AST.WALK_AFTER_CHILDREN  ) ~= 0
    local between  = bit.band(flags, AST.WALK_BETWEEN_CHILDREN) ~= 0
    local base     = bit.band(flags, AST.WALK_IS_BASE         ) ~= 0
    local alloc    = bit.band(flags, AST.WALK_HAS_ALLOCATION  ) ~= 0
    local ptr      = ffi.cast("uintptr_t", ffi.cast("void*", v))
    local null     = tonumber(ptr) == 0
    local safeaddr = tostring(ptr)

    local _ns   = ffi.nsof(v)
    local _name = ffi.tagof(v)

    -- once-per-graph stuff
    if level == 1 and before then
        ud.top = {
            addr      = safeaddr,
            null      = null,
            ns        = _ns,
            type      = _name,
            children  = { },
            contained = false,
            name      = "top",
            flags     = flags,
        }
        ud.rec[1] = ud.top.children
        print "digraph abstract_syntax_tree {\
              graph [rankdir=TB];\
              node [shape=none];\
              "
    end

    local indenter = "  "

    if before then
        if not ud.rec[level] then ud.rec[level] = { } end
        --parent = ud.stack[level]
        ud.level = level
    end

    local parent = ud.stack[level]
    local rec

    if between then
        --debug(v)
        local printable = type(v) == "string" and v or nil
        rec = {
            addr      = safeaddr,
            null      = null,
            ns        = _ns,
            type      = _name,
            name      = k,
            printable = printable,
            --value     = v, -- TODO remove ?
            contained = base or not alloc,
            flags     = flags,
        }

        --[[
        for L = 1,level do io.write(indenter) end
        debug("rec       = ", rec)
        for L = 1,level do io.write(indenter) end
        debug(" level    = ", level)
        for L = 1,level do io.write(indenter) end
        debug(" k        = ", k)
        for L = 1,level do io.write(indenter) end
        debug(" base     = ", base)
        for L = 1,level do io.write(indenter) end
        debug(" alloc    = ", alloc)
        for L = 1,level do io.write(indenter) end
        debug(" parent   = ", parent)
        --for L = 1,level do io.write(indenter) end
        --debug(" children = ", #parent.children)
        for L = 1,level do io.write(indenter) end
        debug ""
        --]]

        --ud.rec[level]["node_" .. safeaddr] = rec
        table.insert(ud.rec[level], rec)
        --[[
        if not parent.base then
            table.insert(ud.nodes, rec)
        end
        --]]
        ud.stack[level + 1] = rec
        if parent.children then
            table.insert(parent.children,rec)
        else
            parent.children = { rec }
        end
    end

    if after then
        -- clear out junk we don't need any to keep around
        ud.stack[level + 1] = nil
        ud.rec[level + 1] = nil
    end

    if level == 1 and after then
        -- clear out junk we don't need any to keep around
        ud.level = nil
        ud.stack = nil
        ud.rec = nil
        -- TODO print all connections
        -- TODO print top, not top.children
        print(print_node(ud,flags,1,0,ud.top))
        for i,n in ipairs(ud.nodes) do print(n) end
        for i,n in ipairs(ud.links) do print(n) end
        print "}"
    end

end

ffi.cdef[[void abort()]]

-- TODO define better API for errors
local function errorcb(ud,msg)
    print(msg)
    -- TODO print "." vs. "->" correctly ("." is good enough for GDB) ?
    print("level is " .. ud.level .. ", path is top." .. table.concat(ud.path,"."))
    ffi.C.abort()
end

-- userdata for callbacks
--[[
local ud = {
    --path = {},
    rec = {},
    level = 1,
}
--]]

local ud = {
    --path = {},
    rec = {},
    stack = { { children = {} } },
    level = 1,
    nodes = {}, -- top-level nodes, formatted already TODO rename
    links = {},
}

AST.walk(ast,ud,{ walk = gv2, error = errorcb })
debug(dump(ud))

--[[
--print(AST.node_rec(1))
--rec = libast.node_recs[ffi.cast("enum node_type","NODE_TYPE_node")]
rec = libast.node_recs[nodetype("NODE_TYPE_integer")]
for k,v in pairs(ffi.fields(rec)) do
    print(k,v)
    print(rec[v])
end
print(rec.items[0])
print(ffi.string(rec.items[0].c.node.name))

local size = 100;
local psize = ffi.new("int[1]", size)
--local buf = ffi.gc(ffi.C.malloc(size),ffi.C.free)
local buf = ffi.new("char[?]", size)
local data = ffi.new("int[1]", 999);
--print(libast.fmt_call(0,0,nil,nil,nil))
print(libast.fmt_call("META_IS_BASIC",ffi.cast("enum basic_type","BASIC_TYPE_int"),psize,buf,data))
print(libast.fmt_call(5,6,psize,buf,data))
print(ffi.string(buf))
--]]

--print(libast.node_recs[1])

