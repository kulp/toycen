#include "lexer.h"
#include "pp_lexer.h"
#include "parser.h"
#include "hash_table.h"
#include "ast-walk.h"
#include "ast-ids-priv.h"
#include "ast-formatters.h"

#include <stdio.h>
#include <stdlib.h>

extern int yyparse();

int DEBUG_LEVEL = 2;
FILE* DEBUG_FILE;

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
    switch (meta) {
        case META_IS_NODE: {
            const struct node_rec *rec = &node_recs[type];
            if (data && flags & AST_WALK_BEFORE_CHILDREN)
                printf("node name = %s\n", rec->name);
            break;
        }
        case META_IS_BASIC: {
            int size = 128;
            char buf[size];
            int result = fmt_call(meta, type, &size, buf, data);
            printf("result = %d, val = %s, type = %s/%s\n", result, buf,
                    basic_recs[type].defname, basic_recs[type].rawname);
            break;
        }
        default:
            // TODO implement
            abort();
    }

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

    ast_walk((struct node*)top, walk_cb, AST_WALK_BEFORE_CHILDREN, 0);

    parser_teardown(&ps);
    lexer_teardown();

    return result;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
