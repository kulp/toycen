#include "ast-walk.h"
#include "ast-ids-priv.h"
#include "ast-formatters.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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
    } flag_recs[8] = {
        [AST_WALK_BEFORE_CHILDREN ] = { "{ ",  4 },
        [AST_WALK_BETWEEN_CHILDREN] = { "| ",  0 },
        [AST_WALK_AFTER_CHILDREN  ] = { "} ", -4 },
    };

    bool isbase  = flags & AST_WALK_IS_BASE;
    flags &= 0x7; // XXX
    bool before  = flags & AST_WALK_BEFORE_CHILDREN;
    bool after   = flags & AST_WALK_AFTER_CHILDREN;
    bool between = flags & AST_WALK_BETWEEN_CHILDREN;

    const char *name = NULL;
    if (isbase)
        name = "base";
    else
        ops->get_name(cookie, &name);

    const struct flag_rec *f = &flag_recs[flags & 0x7];
    assert(c->indent >= 0);
    assert(c->indent < 256);
    char spaces[c->indent + 1];
    memset(spaces, ' ', sizeof spaces);
    spaces[c->indent] = 0;
    fputs(spaces, stdout);
    c->indent += f->indent;

    if (f->prefix)
        printf("%s", f->prefix);

    if (before || meta == META_IS_BASIC || meta == META_IS_ID)
        printf("%s = ", name ? name : "[top]");

    if (before)
        printf("%s, ", meta_names[meta]);

    switch (meta) {
        case META_IS_PRIV: {
            const struct node_rec *rec = &priv_recs[type];
            if (before)
                printf("%s, ", rec->name);
            break;
        }
        case META_IS_NODE: {
            const struct node_rec *rec = &node_recs[type];
            if (before)
                printf("%s, ", rec->name);
            break;
        }
        case META_IS_BASIC: {
            char buf[128];
            int size = sizeof buf;
            int result = fmt_call(meta, type, &size, buf, data);
            printf("(%s) %s, ", basic_recs[type].defname, buf);
            break;
        }
        case META_IS_ID: {
            char buf[128];
            int size = sizeof buf;
            int result = fmt_call(meta, type, &size, buf, data);
            //if (before)
                printf("ID_TYPE_%s, %s", id_recs[type].name, buf);
            break;
        }
        case META_IS_CHOICE:
            break;
        default:
            // TODO handle
            abort();
    }

    puts("");

    return 0;
}

static int demo_top_op(const struct translation_unit *top)
{
    int result;

    struct mydata data = { 0 };
    result = ast_walk((struct node*)top, walk_cb, AST_WALK_BEFORE_CHILDREN |
                                                  AST_WALK_AFTER_CHILDREN, &data);

    return result;
}

int (*main_walk_op)(const struct translation_unit *) = demo_top_op;

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
