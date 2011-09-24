#include <assert.h>

#include "lauxlib.h"
#include "lj_ctype.h"
#include "lj_err.h"

static CType *my_lj_ctype_rawref(CTState *cts, CTypeID id)
{
    CType *ct = ctype_get(cts, id);
    while (ctype_isattrib(ct->info) || ctype_isref(ct->info))
        ct = ctype_child(cts, ct);
    return ct;
}

static int ffi_fields(lua_State *L)
{
    CTState *cts = ctype_cts(L);
    luaL_dostring(L, "my_ffi = require \"ffi\"");
    lua_getfield(L, LUA_GLOBALSINDEX, "my_ffi");
    lua_getfield(L, -1, "typeof");
    lua_remove(L, -2);
    lua_pushstring(L, "struct translation_unit");
    lua_call(L, 1, 1);

    TValue *o = L->base;
    if (!(o < L->top)) {
        abort(); // XXX
        //lj_err_argtype(L, 1, "C type");
    }
    GCcdata *cd = cdataV(o);
    assert(cd != NULL);
    CTypeID id = cd->typeid == CTID_CTYPEID ? *(CTypeID *)cdataptr(cd) : cd->typeid;

    CType *ct = my_lj_ctype_rawref(cts, id); // XXX

    lua_pop(L,1);
    lua_pop(L,1);

    while (ctype_isptr(ct->info)) ct = ctype_rawchild(cts, ct);
    if (ctype_isstruct(ct->info) && ct->size != CTSIZE_INVALID) {
        int i=0;
        lua_createtable(L,0,0);
        while (ct->sib) {
            ct = ctype_get(cts, ct->sib);
            while (ctype_isptr(ct->info)) ct = ctype_rawchild(cts, ct);
            // I want to do something like this, but I don't know the LuaJIT GC well
            // enough to keep it from failing :
            //      setstrV(L, L->top++, gcrefp(ct->name, GCstr));
            // so we do this instead:
            lua_pushstring(L, strdata(strref(ct->name)));
            lua_rawseti(L, -2, ++i);
        }
        return 1;
    } else {
        abort(); // XXX
        //lj_err_argtype(L, 1, "ctype or cdata"); // XXX
    }
    return 0;
}

int luaopen_libljffifields(lua_State *L) {
    lua_register(L,"ffi_fields", ffi_fields);
    return 1;
}

