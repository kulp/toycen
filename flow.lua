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

local function gvcb(ud,flags,level,k,v)
    local before  = bit.band(flags, AST.WALK_BEFORE_CHILDREN ) ~= 0
    local after   = bit.band(flags, AST.WALK_AFTER_CHILDREN  ) ~= 0
    local between = bit.band(flags, AST.WALK_BETWEEN_CHILDREN) ~= 0
    local base    = bit.band(flags, AST.WALK_IS_BASE         ) ~= 0
    -- TODO don't cast scalars to void*
    local safeaddr = tonumber(ffi.cast("uintptr_t", ffi.cast("void*", v)))

    local _name = ffi.tagof(v)
    --print("_name=",_name)

    -- once-per-graph stuff
    if level == 0 and before then
        print "digraph abstract_syntax_tree {\
              graph [rankdir=TB];\
              node [shape=none];\
              "
    end

    --print(flags,k,v)

    -- per-node stuff
    if before then
        local prefix = ""
        local suffix = ""
        if not base then
            prefix = "struct_" .. safeaddr .. " [label=<"
            suffix = ">];"
        end

        local me = { bet = {}, level = 1 }
        -- TODO formatting
        me.pre = _name--[[prefix .. "\
            <table>\
                <tr>\
                    <td colspan='2' port='_name' bgcolor='#dddddd'><font point-size='10'>" .. _name .. "</font></td>\
                </tr>\
                <tr>\
            " .. suffix
            --]]
        ud.rec[ud.level] = me
        ud.level = ud.level + 1
        --table.insert(ud.rec, me)
        --print(flags,k,v)
    elseif after then

        if ud.level > 1 then
            ud.level = ud.level - 1
            if level == 0 then
                for p,me in ipairs(ud.rec) do
                    --local me = ud.rec[ud.level - 1]
                    -- TODO ordering of printout is backward
                    --if not base then
                        --print(flags,k,v)
                        print(me.pre)
                        --while me.level > 1 do
                        --for i = 1, me.level - 1 do
                        for i,b in ipairs(me.bet) do
                            print(b)
                            --print(me.bet[i])
                            --me.level = me.level - 1
                            --print(table.remove(me.bet, 1))
                        end
                        --me.level = 1
                        --print("</td></tr></table><!-- " .. _name .. " -->")
                        print("> <end " .. me.pre .. ">")
                    --end
                end
            end
        end

    elseif between then
        --print "BETWEEN"
        local me = ud.rec[ud.level - 1]
        table.insert(me.bet, { key = k, val = nil })
        --table.insert(me.bet, "key=" .. k .. ", value=")
        --table.insert(me.bet, "<td>" .. k .. "</td><td>")
        --me.bet[me.level] = "<td>" .. k .. "</td><td>"
        --me.level = me.level + 1
    end

    if level == 0 and after then
        -- TOOD print all connections
        print "}"
    end

end

local function format_field_name(ud,flags,level,name)
    --return "<td port='port_name_" .. name .. "'>" .. name .. "</td>"
    return "<td port='" .. name .. "'>" .. name .. "</td>"
end

local function format_field_value(ud,flags,level,value)
    --return "<td port='port_val_" .. "TODO" .. "'>" .. value .. "</td>"
    return "<td port='" .. "TODO" .. "'>" .. value .. "</td>"
end

local function format_field(ud,flags,level,k,v)
    return "<tr>"
        .. format_field_name(ud,flags,level,k)
        .. "\t"
        .. format_field_value(ud,flags,level,v)
        .. "</tr>\n"
end

local function _print_node_inner(ud,flags,level,i,me)
    local result = ""
    --for L = 1,level do result = result .. "\t" end
    local base    = bit.band(flags, AST.WALK_IS_BASE         ) ~= 0
    local simple = not base and not me.type
    if not simple then result = result .. "\n<table>\n" end
    --print_node(ud,flags,level,i,me)
    --result = result .. format_field(ud,flags,level,me.name,"foo")
    if me.children then
        for i,me in ipairs(me.children) do
            result = result .. format_field(id,flags,level+1,me.name,_print_node_inner(ud,flags,level+1,i,me));
            --print(format_field(ud,flags,level,me.name,"foo"))
            --print(format_field(ud,flags,level,me.name,"foo"))
            --print "QQQQ<"
            --for name,value in pairs(node) do
            --    print(format_field(ud,flags,level,me.name,"foo"))
            --end
            --print ">QQQQ"
        end
    end
    if not simple then result = result .. "</table>\n" end
    return result
end

local function print_node(ud,flags,level,i,node)
    print("struct_" .. node.addr .. " [label=<");
    --if node then
    --[[
        for i,me in pairs(node.children) do
            print(_print_node_inner(ud,flags,level,i,me))
        end
    --]]
    print(_print_node_inner(ud,flags,level + 1,i,node))
    --end
    print ">];";
end

-- TODO what we need is an is_pointer in the walk flags or arguments
local function gv2(ud,flags,level,k,v)
    local before  = bit.band(flags, AST.WALK_BEFORE_CHILDREN ) ~= 0
    local after   = bit.band(flags, AST.WALK_AFTER_CHILDREN  ) ~= 0
    local between = bit.band(flags, AST.WALK_BETWEEN_CHILDREN) ~= 0
    local base    = bit.band(flags, AST.WALK_IS_BASE         ) ~= 0
    local alloc   = bit.band(flags, AST.WALK_HAS_ALLOCATION  ) ~= 0
    local safeaddr = tonumber(ffi.cast("uintptr_t", ffi.cast("void*", v)))

    local _name = ffi.tagof(v)

    -- once-per-graph stuff
    if level == 1 and before then
        ud.top = {
            addr      = safeaddr,
            type      = _name,
            children  = { },
            contained = false,
            name      = "top",
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
        rec = { addr = safeaddr, type = _name, name = k, contained = base }

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
        print_node(ud,flags,1,0,ud.top)
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
    nodes = {}, -- top-level nodes
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

