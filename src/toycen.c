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
#include "parser.h"
#include "parser_primitives.h"
#include "hash_table.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <getopt.h>

extern int yyparse();

int DEBUG_LEVEL = 2;
FILE* DEBUG_FILE;

// XXX
bool is_interactive = false;

// common variable, another object sets it
int (*main_walk_op)(const struct translation_unit *);

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

    if (main_walk_op)
        result = main_walk_op(top);

    teardown_ast(&ps, &top);

    return result;
}

/* vi:ts=4 sw=4 et syntax=c.doxygen: */
