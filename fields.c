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
  //CTypeID id = ffi_checkctype(L, cts); // XXX
  //lua_pushstring(L, "print");
  /*
  lua_getfield(L, LUA_GLOBALSINDEX, "print");
  lua_pushstring(L, "print");
  lua_call(L, 1, 0);
  */
  //luaL_dostring(L, "print(\"hi\")");
  luaL_dostring(L, "my_ffi = require \"ffi\"");
  //luaL_dostring(L, "my_ffi.typeof(\"struct foo\")");
  lua_getfield(L, LUA_GLOBALSINDEX, "my_ffi");
  lua_getfield(L, -1, "typeof");
  lua_remove(L, -2);
  lua_pushstring(L, "struct translation_unit");
  lua_call(L, 1, 1);

  TValue *o = L->base;
  if (!(o < L->top)) {
  err_argtype:
    abort();
    //lj_err_argtype(L, 1, "C type");
    ;
  }
  GCcdata *cd = cdataV(o);
  CTypeID id = cd->typeid == CTID_CTYPEID ? *(CTypeID *)cdataptr(cd) : cd->typeid;

  /*
  lua_getfield(L, LUA_GLOBALSINDEX, "print");
  lua_insert(L, -2);
  lua_call(L, 1, 0);
  */
  //return 0;
  //CTypeID id = 0;
  CType *ct = my_lj_ctype_rawref(cts, id); // XXX

  lua_pop(L,1);
  lua_pop(L,1);

  printf("top = %d\n", lua_gettop(L));
  //CType *ct = 0; // XXX

  while (ctype_isptr(ct->info)) ct = ctype_rawchild(cts, ct);
  if (ctype_isstruct(ct->info) && ct->size != CTSIZE_INVALID) {
    int i=0;
    lua_createtable(L,0,0);
    while (ct->sib) {
      ct = ctype_get(cts, ct->sib);
      while (ctype_isptr(ct->info)) ct = ctype_rawchild(cts, ct);
      setstrV(L, L->top++, gcrefp(ct->name, GCstr));
      lua_rawseti(L, -2, ++i);
    }
    return 1;
  } else {
    //lj_err_argtype(L, 1, "ctype or cdata"); // XXX
  }
  return 0;
}

int luaopen_libfields(lua_State *L) {
  lua_register(L,"ffi_fields", ffi_fields);
  return 1;
}

