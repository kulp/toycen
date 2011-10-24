-- "main program" from the lua POV
local ffi = require "ffi"
local bit = require "bit"

require "3rdparty/dumper"

local function prettify(what)
    if (should_prettify) then
        require "htmltidy"

        local tidy = htmltidy.new()
        -- indentation is really the only reason we use Tidy at all
        tidy:setOpt(htmltidy.opt.IndentContent, "auto")
        -- if we parse as HTML Tidy will "fix" things and break them
        tidy:setOpt(htmltidy.opt.XmlTags, true)
        -- wide formatting is ok ; disable wrapping
        tidy:setOpt(htmltidy.opt.WrapLen, 0)

        -- throw away error stuff
        local out, etext, evalue = tidy:easyClean(what)

        return out
    else
        return what
    end
end

-- XXX should not be necessary to do anonymous checks at this level of
-- abstraction
local function is_anonymous(tag) return tag:find("%d+") end

local function format_field_name(name)
    return "<td port='" .. name .. "'><font face='courier' color='#777777'>" .. name .. "</font></td>"
end

local function format_field_value(i,namespace,value)
    return "<td cellpadding='1' port='port_" .. namespace .. "_" .. i .. "'>" .. value .. "</td>"
end

local function format_field(obj,k,v)
    return "<tr>"
        .. format_field_name(k)
        .. format_field_value(k,obj,v)
        .. "</tr>"
end

local format_node -- to allow mutual recursion with _format_node_inner

local function _format_node_inner(ud,flags,me)
    local result = ""
    local close_table = false

    -- simple case
    if not me.type and me.printable then
        result = result .. me.printable
        return result
    end

    -- complex case
    local content = me.type or "XXX" -- TODO trap
    if #me.children > 0 or AST.fl.is_alloc(me.flags) and me.null then
        local table_format = ' border="0" cellborder="1" cellspacing="0" cellpadding="4"'
        result = result .. "<table" .. table_format .. ">"
        close_table = true
        if #me.children > 0 and not is_anonymous(me.type or "") then
            result = result .. "<tr><td colspan='2' port='_name' bgcolor='#dddddd'><font point-size='12'>" .. content .. "</font></td></tr>"
        end
        if AST.fl.is_alloc(me.flags) and me.null then
            result = result .. "<tr><td colspan='2'>NULL</td></tr>"
        end
    end

    for j,ye in ipairs(me.children) do
        -- used to use me.type tout court as the namespace for the port
        -- name, but me.type can be a generated value for anonymous
        -- aggregates. we really want to have the namespace be the last
        -- "real" node so we search up the parent chain.
        local t = me
        while t.type and is_anonymous(t.type) do
            t = t.parent
        end

        local inner
        if ye.contained then
            inner = _format_node_inner(ud,flags,ye)
        else
            table.insert(ud.nodes, format_node(ud,flags,ye))
            if not me.null and not ye.null then
                local linkval =
                       "struct_" .. t.addr .. ":" .. "port_" .. t.type .. "_" .. ye.name
                    .. " -> "
                    .. "struct_" .. ye.addr .. ":" .. "_name"
                table.insert(ud.links, linkval)
            end
            if AST.fl.is_alloc(ye.flags) then
                inner = ye.null and "NULL" or "*"
            else
                inner = ye.printable
            end
        end

        result = result .. format_field(t.type,ye.name,inner)
    end

    if close_table then result = result .. "</table>" end

    return result
end

function format_node(ud,flags,node)
    return node.null and "" or
            "struct_" .. node.addr .. " [label=<"
        .. prettify(_format_node_inner(ud,flags,node))
        .. ">];"
end

local function graphvizcb(ud,flags,k,v)
    local ptr      = ffi.cast("uintptr_t", ffi.cast("void*", v))
    local isnull   = tonumber(ptr) == 0
    local safeaddr = isnull and "NULL" or tostring(ffi.cast("uint64_t",tonumber(ptr)))

    local _name = ffi.tagof(v)

    print("level=",ud.level,"flags=",flags)

    local rec = { }

    if AST.fl.is_before(flags) then
        ud.level = ud.level + 1
        --if not ud.rec[ud.level] then ud.rec[ud.level] = { { children = { } } } end
        if not ud.rec[ud.level] then
            --rec = { children = { } }
            ud.rec[ud.level] = { rec };
        end
        local up = ud.rec[ud.level - 1];
        if up and #up > 0 then
            up[#up].children = { rec }
        end
        --if not ud.stack[ud.level] then ud.stack[ud.level] = { children = { } } end
    end

    local level = ud.level

    -- once-per-graph stuff
    if level == 1 and AST.fl.is_before(flags) then
        ud.top = {
            addr      = safeaddr,
            children  = { },
            contained = false,
            flags     = flags,
            name      = "top",
            null      = isnull,
            type      = _name,
        }

        ud.rec[0] = { ud.top } -- XXX why
        --ud.rec[1] = ud.top.children
        --ud.rec[1] = { ud.top }
        --ud.rec[2] = ud.top.children
        --table.insert(ud.rec[level], ud.top)
        print("digraph abstract_syntax_tree {\n"
           .. "    graph [rankdir=LR];\n"
           .. "    node [shape=none];\n")
    end

    local indenter = "  "

    if AST.fl.is_between(flags) then
        --local parent = ud.stack[level]
        local up = ud.rec[level - 1];
        --local up = ud.rec[level - 1] or ud.rec[level - 2];
        local parent = up[#up]
        print("level=",level,"parent=",parent)
        local printable = type(v) == "string" and v or nil

        rec.addr      = safeaddr
        rec.children  = { }
        rec.contained = AST.fl.is_base(flags) or not AST.fl.is_alloc(flags)
        rec.flags     = flags
        rec.name      = k
        rec.null      = isnull
        rec.parent    = parent
        rec.printable = printable
        rec.type      = _name

        --table.insert(ud.rec[level], rec)
        -- ud.stack[level + 1] = ud.rec[level][-1]
        --ud.stack[level + 1] = rec
        --print("thelevel=",level)
        table.insert(parent.children,rec)
    end

    if AST.fl.is_after(flags) then
        -- clear out junk we don't need any to keep around
        --ud.stack[level + 1] = nil
        --ud.rec[level + 1] = nil
        ud.level = level - 1
    end

    if level == 1 and AST.fl.is_after(flags) then
        -- clear out junk we don't need any to keep around
        ud.level = nil
        --ud.stack = nil
        --ud.rec = nil
        print(DataDumper(ud))
        --print(format_node(ud,flags,ud.top))
        for i,n in ipairs(ud.nodes) do print(n) end
        for i,n in ipairs(ud.links) do print(n) end
        print "}"
    end

end

-- TODO define better API for errors
local function errorcb(ud,msg)
    ffi.cdef[[void abort()]]

    print(msg)
    -- TODO print "." vs. "->" correctly ("." is good enough for GDB) ?
    print("level is " .. ud.level .. ", path is top." .. table.concat(ud.path,"."))
    ffi.C.abort()
end

local ud = {
    level = 0,
    links = {}, -- connections between nodes, formatted
    nodes = {}, -- top-level nodes, formatted
    rec   = {},
    --stack = { { children = {} } },
}

AST.walk(ast,ud,{ walk = graphvizcb, error = errorcb })

-- vi:set ts=4 sw=4 et nocindent ai linebreak syntax=lua
