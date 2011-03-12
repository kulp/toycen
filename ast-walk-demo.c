#include "lexer.h"
#include "pp_lexer.h"
#include "parser.h"
#include "hash_table.h"
#include "ast-walk.h"
#include "ast-ids-priv.h"
#include "ast-formatters.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

extern int yyparse();

int DEBUG_LEVEL = 2;
FILE* DEBUG_FILE;

static const char *flags_names[] = {
    #define R_(X) [AST_WALK_##X] = #X,
    R_(BEFORE_CHILDREN)
    R_(AFTER_CHILDREN)
    R_(BETWEEN_CHILDREN)
    #undef R_
};

static const char *meta_names[] = {
    #define R_(X) [META_IS_##X] = #X,
    R_(INVALID)
    R_(NODE)
    R_(ID)
    R_(CHOICE)
    R_(PRIV)
    R_(BASIC)
    #undef R_
};

struct mydata {
    int indent;
};

static int walk_cb(
        int flags,
        enum meta_type meta,
        unsigned type,
        void *data,
        void *userdata,
        struct ast_walk_ops *ops,
        walkdata cookie
    )
{
    struct mydata *c = userdata;

    static const struct flag_rec {
        char *prefix;
        signed indent;
    } flag_recs[] = {
        [AST_WALK_BEFORE_CHILDREN ] = { "{ " ,  4 },
        [AST_WALK_BETWEEN_CHILDREN] = { " | ",  0 },
        [AST_WALK_AFTER_CHILDREN  ] = { " }" , -4 },
    };

    bool before  = flags & AST_WALK_BEFORE_CHILDREN;
    bool after   = flags & AST_WALK_AFTER_CHILDREN;
    bool between = flags & AST_WALK_BETWEEN_CHILDREN;

    bool ignore = true;

    #if 0
    switch (meta) {
        case META_IS_ID:
        case META_IS_BASIC:
            //if (before)
        case META_IS_CHOICE:
        case META_IS_NODE:
                ignore = false;
            break;
        default:
            break;
    }
    #else
    ignore = false;
    #endif

    //printf("%s | %s | ", flags_names[flags & 0x7], meta_names[meta]);
    const struct flag_rec *f = &flag_recs[flags & 0x7];
    assert(c->indent < 128);
    char spaces[c->indent + 1];
    memset(spaces, ' ', sizeof spaces);
    spaces[c->indent] = 0;
    printf(spaces);
    c->indent += f->indent;

    printf("%s", f->prefix);

    if (!ignore && before)
        printf("%s, ", meta_names[meta]);

    switch (meta) {
        case META_IS_NODE: {
            const struct node_rec *rec = &node_recs[type];
            if (before)
                printf("%s, ", rec->name);
            break;
        }
        case META_IS_BASIC: {
            int size = 128;
            char buf[size];
            int result = fmt_call(meta, type, &size, buf, data);
            if (before)
                printf(" = (%s) %s, ", basic_recs[type].defname, buf);
            break;
        }
        case META_IS_ID:
            if (before)
                printf("ID_TYPE_%s, ", id_recs[type].name);
            break;
        case META_IS_CHOICE:
            // TODO implement
            break;
        default:
            // TODO handle
            abort();
    }

    if (!ignore)
        puts("");

    return 0;
}

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

    struct mydata data = { 0 };
    ast_walk((struct node*)top, walk_cb, AST_WALK_BEFORE_CHILDREN | AST_WALK_BETWEEN_CHILDREN | AST_WALK_AFTER_CHILDREN, &data);

    parser_teardown(&ps);
    lexer_teardown();

    return result;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
