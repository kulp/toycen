#include "ast-walk.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <assert.h>
#include <stdbool.h>

// XXX
#define STACK_LEVELS 10

struct graphvizdata {
    struct nodedata {
        // TODO sort for optimal alignment
        intptr_t addr;
        struct nodedata *children;
        bool contained;
        int flags;
        char name[32];
        bool isnull;
        struct nodedata *parent;
        char *printable;
        struct node_rec *type;

        bool valid; // to mark end of list

        // appropriate for rec
        struct nodedata *list;
        // appropriate for stack and rec
        struct nodedata *next, *prev;
    } *top, *rec, *stack;
    int level;
    struct link {
        char *string;
        struct link *next;
    } *links;
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

    // XXX
    const char *k = NULL;
    void *v = NULL;

    struct graphvizdata *ud = userdata;

    int level = ud->level;
    // TODO not sure this works
    if (flags & AST_WALK_BEFORE_CHILDREN) {
        level = ++ud->level;
    } else if (flags & AST_WALK_AFTER_CHILDREN) {
        level = --ud->level;
    }

    if (level == 1 && AST_WALK_BEFORE_CHILDREN) {
        ud->top = malloc(sizeof *ud->top);
        *ud->top = (struct nodedata){
            .name = "top",
            .children = calloc(1, sizeof *ud->top->children), // valid = false
        };

        ud->rec = calloc(1, sizeof *ud->rec),      // valid = false
        ud->stack = calloc(1, sizeof *ud->stack),  // valid = false

        ud->rec = ud->top->children;
        puts("digraph abstract_syntax_tree {\n"
             "    graph [rankdir=LR];\n"
             "    node [shape=none];\n");
    }

    if (flags & AST_WALK_BEFORE_CHILDREN) {
        if (!ud->rec->next)
            ud->rec->next = malloc(sizeof *ud->rec->next);
        // ud.level = level;
    }

    struct nodedata *rec;

    if (flags & AST_WALK_BETWEEN_CHILDREN) {
        struct nodedata *parent = ud->stack;
        // XXX
        char *printable = NULL;
        rec = malloc(sizeof *rec);
        *rec = (struct nodedata){
            .addr      = (intptr_t)v,
            .children  = NULL,
            .contained = ((flags & AST_WALK_IS_BASE) || !(flags & AST_WALK_HAS_ALLOCATION)),
            .flags     = flags,
            .name      = k,
            .isnull    = !v,
            .parent    = parent,
            .printable = printable,
            .type      = NULL, // TODO
        };

        struct nodedata *temp = ud->rec->list;
        ud->rec->list = malloc(sizeof *ud->rec->list);
        *ud->rec->list = (struct nodedata){ .list = temp };
    }

    if (flags & AST_WALK_AFTER_CHILDREN) {
        ud->stack = ud->stack->prev;
        free(ud->stack->next);
        ud->stack->next = NULL;

        ud->rec = ud->rec->prev;
        free(ud->rec->next);
        ud->rec->next = NULL;
    }

    if (level == 0 && flags && AST_WALK_AFTER_CHILDREN) {
        free(ud->stack);
        ud->stack = NULL;

        free(ud->rec);
        ud->rec = NULL;

        // TODO write nodes and free
        // TODO write links and free
        puts("}");
    }

    return result;
}

static int walk_top_graphviz(const struct translation_unit *top)
{
    int rc = 0;

    struct graphvizdata ud = { .level = 0 };

    int flags = AST_WALK_BEFORE_CHILDREN | AST_WALK_AFTER_CHILDREN;
    rc = ast_walk((struct node*)top, walk_cb, flags, &ud);

    return rc;
}

int (*main_walk_op)(const struct translation_unit *) = walk_top_graphviz;

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
