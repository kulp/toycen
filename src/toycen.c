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

#if TOYCEN_ENABLE_LUA
#include <luajit.h>
#include <lauxlib.h>
#include <lualib.h>

#include <readline/readline.h>
#include <readline/history.h>

#define mydo(L,what,result) \
    do { \
        result = luaL_dofile(L, what); \
        if (result) \
            if (lua_isstring(L, -1)) \
                fprintf(stderr, "%s\n", lua_tostring(L, -1)); \
    } while (0)

#endif

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <getopt.h>

extern int yyparse();

int DEBUG_LEVEL = 2;
FILE* DEBUG_FILE;

// XXX
static bool is_interactive = false;

#if TOYCEN_ENABLE_LUA
static int lua_top_op(struct translation_unit *top)
{
    int result = 0;

    lua_State *L = luaL_newstate();
    luaL_openlibs(L);

    char *str = NULL;
    const char *prompt = "> ";
    bool shouldread = is_interactive;

    mydo(L,"setup.lua",result);
    mydo(L,"ast.lua",result);

    // TODO make ffi local
    // TODO use C API instead of dostring
    luaL_dostring(L, "ffi = require \"ffi\"");
    luaL_dostring(L, "Tp_translation_unit = ffi.typeof(\"T_translation_unit*\")");
    lua_getglobal(L, "Tp_translation_unit");
    lua_pushlightuserdata(L, top);
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

static int (*top_op)(struct translation_unit *) = lua_top_op;
#else
static int nop_top_op() { }
static int (*top_op)(struct translation_unit *) = nop_top_op;
#endif

static int get_parsed_ast(void *ud, struct translation_unit **what)
{
    int result = 0;

    lexer_setup();
    parser_setup(ud);
    result = yyparse();

    *what = get_top_of_parse_result();

    return result;
}

static int teardown_parsed_ast(void *ud, struct translation_unit **what)
{
    int result = 0;

    parser_teardown(ud);
    lexer_teardown();

    return result;
}

extern int get_wrapped_ast(void *, struct translation_unit **);
extern int teardown_wrapped_ast(void *, struct translation_unit **);

static int (*get_ast)(void *, struct translation_unit **);
static int (*teardown_ast)(void *, struct translation_unit **);

int main(int argc, char *argv[])
{
    int result;

    DEBUG_FILE = stdout;

    #if ARTIFICIAL_AST
        get_ast = get_wrapped_ast;
        teardown_ast = teardown_wrapped_ast;
    #else
        get_ast = get_parsed_ast;
        teardown_ast = teardown_parsed_ast;
    #endif

    parser_state_t ps;

    extern int optind;
    int ch;
    while ((ch = getopt(argc, argv, "i")) != -1) {
        switch (ch) {
            case 'i': is_interactive = true; break;
            default: abort();
        }
    }

    if (optind < argc)
        switch_to_input_file(argv[optind]);

    struct translation_unit *top;
    get_ast(&ps, &top);

    result = top_op(top);

    teardown_ast(&ps, &top);

    return result;
}

/* vi:ts=4 sw=4 et syntax=c.doxygen: */
