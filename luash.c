#include <luajit.h>
//#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include <stdio.h>
#include <stdlib.h>
#include <readline/readline.h>
#include <readline/history.h>

int main(void)
{
    int rc = EXIT_SUCCESS;

	lua_State *l;
	l = luaL_newstate();
    luaL_openlibs(l);

    char *str = NULL;
    const char *prompt = "> ";

    rc = luaL_dofile(l, "test.lua");
    if (rc) {
        abort();
    }

    while ((str = readline(prompt))) {
        if (luaL_dostring(l, str)) {
            prompt = "!>";
        } else {
            prompt = "> ";
        }
    }

    lua_close(l);

    return rc;
}

