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
    (void)top;

    {
        lua_State *L = luaL_newstate();
        //lua_Debug ar = { 0 };
        luaL_openlibs(L);

        char *str = NULL;
        const char *prompt = "> ";

        result = luaL_dofile(L, "setup.lua");
        if (result)
            abort();

        //lua_getstack(L, 0, &ar);
        //lua_setlocal(L, &ar, "k
        lua_pushlightuserdata(L, top);
        lua_setglobal(L, "ast");

        while ((str = readline(prompt))) {
            if (luaL_dostring(L, str)) {
                prompt = "!>";
            } else {
                prompt = "> ";
            }
        }

        lua_close(L);
    }

    parser_teardown(&ps);
    lexer_teardown();

    return result;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
