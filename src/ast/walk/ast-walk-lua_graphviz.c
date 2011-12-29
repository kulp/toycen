#include "lexer.h"
#include "pp_lexer.h"
#include "parser.h"

#include <luajit.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdbool.h>
#include <stdlib.h>

#include <readline/readline.h>
#include <readline/history.h>

#define mydo(L,what,result) \
    do { \
        result = luaL_dofile(L, what); \
        if (result) \
            if (lua_isstring(L, -1)) \
                fprintf(stderr, "%s\n", lua_tostring(L, -1)); \
    } while (0)

static int lua_top_op(const struct translation_unit *top)
{
    int result = 0;

    lua_State *L = luaL_newstate();
	if (!L) {
		fprintf(stderr, "Failed to allocate Lua state\n");
		return -1;
	}
    luaL_openlibs(L);

    char *str = NULL;
    const char *prompt = "> ";
	extern bool is_interactive;
    bool shouldread = is_interactive;

    mydo(L,"setup.lua",result);
    mydo(L,"ast.lua",result);

    // TODO make ffi local
    // TODO use C API instead of dostring
    luaL_dostring(L, "ffi = require \"ffi\"");
    luaL_dostring(L, "Tp_translation_unit = ffi.typeof(\"T_translation_unit*\")");
    lua_getglobal(L, "Tp_translation_unit");
    lua_pushlightuserdata(L, (void*)top);
    lua_pcall(L, 1, 1, 0);
    lua_setglobal(L, "ast");

    mydo(L,"flow.lua",result);

    while (shouldread && (str = readline(prompt))) {
        if (luaL_dostring(L, str)) {
            prompt = "!>";
            if (lua_isstring(L, -1))
                fprintf(stderr, "%s\n", lua_tostring(L, -1));
        } else {
            prompt = "> ";
        }

        free(str);
    }

    lua_close(L);

    return result;
}

int (*main_walk_op)(const struct translation_unit *) = lua_top_op;

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
