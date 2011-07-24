-- "main program" from the lua POV
local ffi = require "ffi"
local bit = require "bit"

--[[
require "dumper"
-- Define a shortcut function for testing
function dump(...)
  print(DataDumper(...), "\n---")
end
--]]

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
        me.pre = prefix .. "\
            <table>\
                <tr>\
                    <td colspan='2' port='_name' bgcolor='#dddddd'><font point-size='10'>" .. _name .. "</font></td>\
                </tr>\
                <tr>\
            " .. suffix
        ud.rec[ud.level] = me
        ud.level = ud.level + 1
        --table.insert(ud.rec, me)
        --print(flags,k,v)
    elseif after then

        if ud.level > 1 then
            local me = ud.rec[ud.level - 1]
            ud.level = ud.level - 1
            -- TODO ordering of printout is backward
            if true or not base then
                --print(flags,k,v)
                print(me.pre)
                while me.level > 1 do
                    print(me.bet[me.level - 1])
                    me.level = me.level - 1
                    --print(table.remove(me.bet, 1))
                end
                print("</td></tr></table><!-- " .. _name .. " -->")
            end
        end

    elseif between then
        --print "BETWEEN"
        local me = ud.rec[ud.level - 1]
        --table.insert(me.bet, "<td>" .. k .. "</td><td>")
        me.bet[me.level] = "<td>" .. k .. "</td><td>"
        me.level = me.level + 1
    end

    if level == 0 and after then
        -- TOOD print all connections
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
local ud = {
    path = {},
    rec = {},
    level = 1,
}

AST.walk(ast,ud,{ walk = gvcb, error = errorcb })
print(dump(ud))

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

