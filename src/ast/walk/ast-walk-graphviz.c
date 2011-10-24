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

    printf("level=\t%d\tflags=\t%d\n",ud->level,flags & ~32);

    if (ud->level == 0) {
        ud->rec = calloc(1, sizeof *ud->rec);
    }

    if (flags & AST_WALK_BEFORE_CHILDREN) {
        ud->level++;
        if (!ud->rec->next) {
            ud->rec->next = calloc(1, sizeof *ud->rec->next);
            ud->rec->next->prev = ud->rec;
        }
    }

    int level = ud->level;

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

        struct nodedata *temp;

        temp = ud->rec->list;
        ud->rec->list = malloc(sizeof *ud->rec->list);
        *ud->rec->list = (struct nodedata){ .list = temp };

        // push onto stack
        ud->stack->next = malloc(sizeof *ud->stack->next);
        *ud->stack->next = (struct nodedata){ .prev = ud->stack };
        ud->stack = ud->stack->next;

        // insert rec into parent's children
        temp = parent->list;
        parent->list = malloc(sizeof *parent->list);
        *parent->list = (struct nodedata){ .list = temp };
    }

    if (flags & AST_WALK_AFTER_CHILDREN) {
        struct nodedata *temp;

        temp = ud->stack->next;
        ud->stack->next = ud->stack;
        free(temp);
        ud->stack->next = NULL;

        temp = ud->rec->next;
        ud->rec->next = ud->rec;
        free(temp);
        ud->rec->next = NULL;
    }

    if (flags & AST_WALK_AFTER_CHILDREN) {
        ud->level--;
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
    //ud.rec = calloc(1, sizeof *ud.rec);

    int flags = AST_WALK_BEFORE_CHILDREN | AST_WALK_AFTER_CHILDREN | AST_WALK_BETWEEN_CHILDREN;
    rc = ast_walk((struct node*)top, walk_cb, flags, &ud);

    return rc;
}

int (*main_walk_op)(const struct translation_unit *) = walk_top_graphviz;

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
