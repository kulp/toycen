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

#include "lexer_gen.h"
#include "parser_primitives.h"
#include "parser.h"
#include "hash_table.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include <getopt.h>

extern int toycen_parse();

int DEBUG_LEVEL = 2;
FILE* DEBUG_FILE;

// XXX
bool is_interactive = false;

// common variable, another object sets it
int (*main_walk_op)(const struct translation_unit *);

static int get_parsed_ast(struct parser_state *ps, struct translation_unit **what, void *ud)
{
    int result = 0;

    toycen_lex_init(&ps->scanner);
    toycen_set_extra(ps, ps->scanner);
    hash_table_create(&ps->types_hash, 0);

    if (ud)
        toycen_set_in(ud, ps->scanner);

    result = toycen_parse(ps);

    *what = ps->top;

    return result;
}

static int teardown_parsed_ast(struct parser_state *ps, struct translation_unit **what, void *ud)
{
    int result = 0;

    // TODO free what
    (void)what;
    (void)ud;

    toycen_lex_destroy(ps->scanner);
    hash_table_destroy(ps->types_hash);
    ps->types_hash = NULL;

    return result;
}

extern int get_wrapped_ast(struct parser_state *ps, struct translation_unit **, void *ud);
extern int teardown_wrapped_ast(struct parser_state *ps, struct translation_unit **, void *ud);

static int (*get_ast)(struct parser_state *ps, struct translation_unit **, void *ud);
static int (*teardown_ast)(struct parser_state *ps, struct translation_unit **, void *ud);

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

    struct parser_state _ps, *ps = &_ps;
    memset(ps, 0, sizeof *ps);

    extern int optind;
    int ch;
    while ((ch = getopt(argc, argv, "i")) != -1) {
        switch (ch) {
            case 'i': is_interactive = true; break;
            default: abort();
        }
    }

    FILE *in = NULL;
    if (optind < argc)
        in = fopen(argv[optind], "rb");

    struct translation_unit *top;
    get_ast(ps, &top, in);

    if (main_walk_op)
        result = main_walk_op(top);

    teardown_ast(ps, &top, NULL);

    if (in)
        fclose(in);

    return result;
}

/* vi:ts=4 sw=4 et syntax=c.doxygen: */
