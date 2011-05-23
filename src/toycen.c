/**
 * @file
 * Toycen is a toy C compiler. From "toy" the reader should infer not
 * that Toycen is completely useless, but that it doesn't take itself
 * very seriously. Toycen may become a pedagogical aid for those wishing to
 * introduce themselves to compiler theory and practice, but at the moment the
 * author is unwilling to propose himself as a teacher on those subjects,
 * considering the scantiness of his own pertient knowledge. Firm goals for
 * Toycen have not yet been set, but it is likely that it will attempt to
 * support as much of C99 as possible, while implementing no or very few
 * extensions.
 */

#include "lexer.h"
#include "pp_lexer.h"
#include "parser.h"
#include "hash_table.h"

#include <luajit.h>
#include <lauxlib.h>
#include <lualib.h>

#include <readline/readline.h>
#include <readline/history.h>

#include <stdio.h>
#include <stdlib.h>

extern int yyparse();

int DEBUG_LEVEL = 2;
FILE* DEBUG_FILE;

int main(int argc, char *argv[])
{
    int result;

    DEBUG_FILE = stdout;

    parser_state_t ps;

    if (argc > 1)
        switch_to_input_file(argv[1]);

    lexer_setup();
    parser_setup(&ps);
    result = yyparse();

    struct translation_unit *top = get_top_of_parse_result();

#if TOYCEN_ENABLE_LUA
    {
        lua_State *L = luaL_newstate();
        luaL_openlibs(L);

        char *str = NULL;
        const char *prompt = "> ";

        result = luaL_dofile(L, "setup.lua");
        if (result)
            if (lua_isstring(L, -1))
                fprintf(stderr, "%s\n", lua_tostring(L, -1));

        lua_getglobal(L, "Tp_translation_unit");
        lua_pushlightuserdata(L, top);
        lua_pcall(L, 1, 1, 0);
        lua_setglobal(L, "ast");

        while ((str = readline(prompt))) {
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
    }
#else
    (void)top;
#endif

    parser_teardown(&ps);
    lexer_teardown();

    return result;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
