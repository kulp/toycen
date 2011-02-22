#include "lexer.h"
#include "pp_lexer.h"
#include "parser.h"
#include "hash_table.h"
#include "ast-walk.h"
#include "ast-ids-priv.h"
#include "ast-formatters.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

extern int yyparse();

int DEBUG_LEVEL = 2;
FILE* DEBUG_FILE;

struct nodedata {
    struct parent {
        enum node_type type;
        struct node *parent;
        const struct node_rec *rec;
        struct label {
            const char *tag;
            char *label;
            struct label *next;
        } *labels;
        struct link {
            struct {
                char node[64];
                const char *port;
            } from, to;
            struct link *next;
        } *links;
        struct parent *next;
    } *ancestry;
};

static int collect_node(const char *name, enum node_type type, struct node *node, struct nodedata *nodes)
{
    struct parent *p = nodes->ancestry;

    if (p) {
        //struct link *L = p->links;
        if (p->next) {
            const struct node_rec *rec = &node_recs[type];
            struct link *L = calloc(1, sizeof *L);
            // XXX
            const char *realname = node_recs[type].name;
            snprintf(L->from.node, sizeof L->from.node, "_%lu_%s", (long)(uintptr_t)p->parent, realname);
            snprintf(L->to  .node, sizeof L->to  .node, "_%lu_%s", (long)(uintptr_t)node     , realname);

            L->from.port = node_recs[p->next->type].name;
            L->to.port   = node_recs[         type].name;

            char *longer = NULL;
            // XXX stop using asprintf
            asprintf(&longer, "{ <%s> %s | }", name, name);
            struct label *lab = calloc(1, sizeof *lab);
            lab->tag = node_recs[type].name;
            lab->label = longer;
            lab->next = nodes->ancestry->labels;
            nodes->ancestry->labels = lab;
        }
    }

    return 0;
}

static int collect_basic(const char *name, enum basic_type type, void *data, struct nodedata *nodes)
{
    char buf[128];
    int size = sizeof buf;
    int result = fmt_call(META_IS_BASIC, type, &size, buf, data);
    char *longer = NULL;
    // XXX stop using asprintf
    asprintf(&longer, "{ <%s> %s | %s }", name, name, buf);
    struct label *L = calloc(1, sizeof *L);
    L->tag = name;
    L->label = longer;
    L->next = nodes->ancestry->labels;
    nodes->ancestry->labels = L;
    return 0;
}

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
    struct nodedata *nodes = userdata;

    switch (meta) {
        case META_IS_NODE: {
            const struct node_rec *rec = &node_recs[type];
            if (flags & AST_WALK_BEFORE_CHILDREN) {
                struct parent *p = calloc(1, sizeof *p);
                p->parent = data;
                p->rec = rec;
                p->type = type;
                p->next = nodes->ancestry;
                nodes->ancestry = p;
            } else if (flags & AST_WALK_AFTER_CHILDREN) {
                struct parent *p = nodes->ancestry;
                nodes->ancestry = p->next;
                // TODO print things
                // can't just use address due to BASE and namespace clash
                printf("_%lu_%s [label=\"", (long)(uintptr_t)p->parent, rec->name);
                struct label *L = p->labels;
                while (L) {
                    printf("%s", L->label);
                    L = L->next;
                    if (L)
                        printf(" | ");
                }
                printf("\"];\n");
                free(p);
            }

            if (data && (flags & AST_WALK_BEFORE_CHILDREN)) {
                char *name = NULL;
                ops->get_name(cookie, &name);
                collect_node(name, type, data, userdata);
                printf("node name = %s\n", rec->name);
            }
            break;
        }
        case META_IS_BASIC: {
            if (flags & AST_WALK_AFTER_CHILDREN) {
                int size = 128;
                char buf[size];
                int result = fmt_call(meta, type, &size, buf, data);
                printf("result = %d, val = %s, type = %s/%s\n", result, buf,
                        basic_recs[type].defname, basic_recs[type].rawname);
                const char *name = NULL;
                ops->get_name(cookie, &name);
                collect_basic(name, type, data, userdata);
            }
            break;
        }
        case META_IS_CHOICE:
            break;
        default:
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

    struct nodedata nodes;
    memset(&nodes, 0, sizeof nodes);

    puts("digraph structs {");
    puts("    node [shape=record];");
    ast_walk((struct node*)top, walk_cb, AST_WALK_BEFORE_CHILDREN | AST_WALK_AFTER_CHILDREN, &nodes);
    puts("}");

    parser_teardown(&ps);
    lexer_teardown();

    return result;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
