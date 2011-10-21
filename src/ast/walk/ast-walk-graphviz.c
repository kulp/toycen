#include "ast-walk.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <assert.h>
#include <stdbool.h>

struct nodedata {
    // TODO sort for optimal alignment
    uintptr_t addr;
    struct nodedata *children;
    bool contained;
    int flags;
    char *name;
    bool isnull;
    struct nodedata *parent;
    char *printable;
    struct node_rec *type;
};

static int walk_cb(
        int flags,
        enum meta_type meta,
        unsigned type,
        void *data,
        void *userdata,
        struct ast_walk_ops *ops,
        //struct ast_walk_meta *meta,
        walkdata cookie
    )
{
    int result = 0;

    struct nodedata *nodes = userdata;

    return result;
}

int walk_top_graphviz(const struct translation_unit *top)
{
    int rc = 0;

    struct nodedata nodes;
    memset(&nodes, 0, sizeof nodes);

    puts("digraph abstract_syntax_tree {\n"
         "    graph [rankdir=LR];\n"
         "    node [shape=none];\n");
    rc = ast_walk((struct node*)top, walk_cb, AST_WALK_BEFORE_CHILDREN | AST_WALK_AFTER_CHILDREN, &nodes);
    puts("}");

    return rc;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
