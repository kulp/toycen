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
#include <inttypes.h>
#include <assert.h>
#include <stdbool.h>

extern int yyparse();

int DEBUG_LEVEL = 2;
FILE* DEBUG_FILE;

struct nodedata {
    struct link {
        struct {
            char node[64];
            const char *port;
        } from, to;
        struct link *next;
    } *links;
    struct parent {
        // TODO either unify rec and type or distinguish them
        enum node_type type;
        struct node *node;
        const struct node_rec *rec;
        const char *name;
        struct label {
            const char *tag;
            char before[128],
                 after [128];
            struct label *next;
        } *labels;
        struct parent *next;
    } *ancestry;
};

static int collect_node(const char *name, enum node_type type, struct node *node, struct nodedata *nodes)
{
    struct parent *p = nodes->ancestry;
    bool rooted = !p;
    bool has_parent = !rooted && p->next;
    bool not_parent = has_parent && node != p->next->node;
    bool recursing_base = has_parent && !not_parent && type != p->next->node->node_type;

    assert(!rooted);
    // XXX wrong
    //assert(has_parent);

    //const struct node_rec *rec = &node_recs[type];

    if (!has_parent) {
        // XXX this is wrong
        printf("_%" PRIxPTR "_%s [label=<", (uintptr_t)p->node, p->name);
    }

    // don't draw arrows to ourselves
    if (not_parent) {
        struct link *link = calloc(1, sizeof *link);
        const char *realname = node_recs[type].name;
        const char *pname = node_recs[p->next->node->node_type].name;
        snprintf(link->from.node, sizeof link->from.node, "_%" PRIxPTR "_%s", (uintptr_t)p->next->node, pname);
        snprintf(link->to  .node, sizeof link->to  .node, "_%" PRIxPTR "_%s", (uintptr_t)node, realname);

        link->from.port = p->name;
        link->to.port   = name;

        link->next = nodes->links;
        nodes->links = link;
    } else if (recursing_base) {
        // base
        // TODO
        struct label *lab = calloc(1, sizeof *lab);
        //int len = snprintf(lab->before, sizeof lab->before, "{ <%s> %s | }", name, name);
        int len = snprintf(lab->before, sizeof lab->before,
                "<tr>"
                    "<td port=\"base\">"
                #if STYLE
                       "<font face=\"courier\" color=\"#777777\">"
                #endif
                            "base"
                #if STYLE
                       "</font>"
                #endif
                    "</td>"
                    "<td>"
                        //"<table>"
                );
        snprintf(lab->after, sizeof lab->after,
                        //"</table>"
                    "</td>"
                "</tr>"
                );
        assert(len <= (signed)sizeof lab->before); // XXX <
        lab->tag = node_recs[type].name;
        lab->next = p->labels;
        p->labels = lab;
    }

    struct label *lab = calloc(1, sizeof *lab);
    //int len = snprintf(lab->before, sizeof lab->before, "{ <%s> %s | }", name, name);
    int len = snprintf(lab->before, sizeof lab->before,
            "<tr>"
                "<td port=\"%s\">"
            #if STYLE
                   "<font face=\"courier\" color=\"#777777\">"
            #endif
                        "%s"
            #if STYLE
                   "</font>"
            #endif
                "<td>*</td>"
            "</tr>"
            , name, name);
    assert(len <= (signed)sizeof lab->before); // XXX <
    lab->tag = node_recs[type].name;
    lab->next = p->labels;
    p->labels = lab;

    return 0;
}

static int collect_basic(const char *name, enum basic_type type, void *data, struct nodedata *nodes)
{
    char buf[128];
    int size = sizeof buf;
    int result = fmt_call(META_IS_BASIC, type, &size, buf, data);
    struct label *label = calloc(1, sizeof *label);
    //int len = snprintf(label->before, sizeof label->before, "{ <%s> %s | %s }", name, name, buf);
    int len = snprintf(label->before, sizeof label->before,
            "<tr>"
            "    <td port=\"%s\">"
            #if STYLE
            "       <font face=\"courier\" color=\"#777777\">"
            #endif
                        "%s"
            #if STYLE
            "       </font>"
            #endif
            "    </td>"
            "    <td>%s</td>"
            "</tr>"
            , name, name, buf);
    assert(len <= (signed)sizeof label->before); // XXX <
    label->tag = name;
    label->next = nodes->ancestry->labels;
    nodes->ancestry->labels = label;
    return result;
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
    int result = 0;

    struct nodedata *nodes = userdata;

    switch (meta) {
        case META_IS_NODE: {
            const struct node_rec *rec = &node_recs[type];
            if (flags & AST_WALK_BEFORE_CHILDREN) {
                const char *name = NULL;
                ops->get_name(cookie, &name);
                struct parent *p = calloc(1, sizeof *p);
                p->node = data;
                p->rec = rec;
                p->type = type;
                p->next = nodes->ancestry;
                p->name = name;
                nodes->ancestry = p;

                if (!p->next) {
                    printf("_%" PRIxPTR "_%s [label=<", (uintptr_t)p->node, p->name);
                }
            } else if (flags & AST_WALK_AFTER_CHILDREN) {
                struct parent *p = nodes->ancestry;
                nodes->ancestry = p->next;
                // TODO print things
                // can't just use address due to BASE and namespace clash
                printf("<table"
                       #if STYLE
                       "       cellpadding=\"4\""
                       "       cellspacing=\"0\""
                       "       border=\"0\""
                       #endif
                       ">");
                struct label *label = p->labels;
                struct label *back = label;
                while (label) {
                    if (label->before[0])
                        printf("%s", label->before);
                    label = label->next;
                    // TODO fix backward list
                    back->next = label;
                    if (back->next)
                        back->next->next = NULL;
                }

                while (back) {
                    if (back->after[0])
                        printf("AFTER:%s", back->after);
                    back = back->next;
                    // TODO free
                }

                printf("</table>\n");
                free(p);
                if (!p->next) {
                    printf(">];\n");
                }
            }

            if (data && (flags & AST_WALK_BEFORE_CHILDREN)) {
                collect_node(nodes->ancestry->name, type, data, userdata);
                //printf("node name = %s\n", rec->name);
            }
            break;
        }
        case META_IS_BASIC: {
            if (flags & AST_WALK_AFTER_CHILDREN) {
                int size = 128;
                char buf[size];
                result = fmt_call(meta, type, &size, buf, data);
                #if 0
                printf("result = %d, val = %s, type = %s/%s\n", result, buf,
                        basic_recs[type].defname, basic_recs[type].rawname);
                #endif
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

    return result;
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
    puts("    node [shape=none];");
    ast_walk((struct node*)top, walk_cb, AST_WALK_BEFORE_CHILDREN | AST_WALK_AFTER_CHILDREN, &nodes);
    struct link *link = nodes.links;
    while (link) {
        //printf("%s:%s -> %s:%s;\n", link->from.node, link->from.port, link->to.node, link->to.port);
        // XXX remove to-port from struct
        printf("%s:%s -> %s:_name;\n", link->from.node, link->from.port, link->to.node);
        link = link->next;
    }
    puts("}");

    parser_teardown(&ps);
    lexer_teardown();

    return result;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
