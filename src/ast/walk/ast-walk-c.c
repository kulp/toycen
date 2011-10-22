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
    int last_idx;
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

    // we might have an empty union, in which case we shouldn't print anything
    // TODO ensure that this double dereference will never fail
    if (meta == META_IS_CHOICE && **(int**)data == 0)
        return 0;

    static const struct flag_rec {
        char *prefix;
        signed indent;
    } flag_recs[8] = {
        [AST_WALK_BEFORE_CHILDREN ] = { "{",  4 },
        [AST_WALK_AFTER_CHILDREN  ] = { "}", -4 },
    };

    struct ast_xattrs attrs = { 0 };

    int botmask = (AST_WALK_BEFORE_CHILDREN |
                   AST_WALK_BETWEEN_CHILDREN |
                   AST_WALK_AFTER_CHILDREN);
    bool before  = flags & AST_WALK_BEFORE_CHILDREN;
    bool after   = flags & AST_WALK_AFTER_CHILDREN;
    bool between = flags & AST_WALK_BETWEEN_CHILDREN;
    bool once    = !(flags & botmask);
    bool structp = (ops->get_xattrs(cookie, &attrs), attrs.is_pointer);

    const char *name = NULL;
    ops->get_name(cookie, &name);

    const struct flag_rec *f = &flag_recs[flags & botmask];
    assert(c->indent >= 0);
    assert(c->indent < 256);
    char spaces[c->indent + 1];
    memset(spaces, ' ', sizeof spaces);
    spaces[c->indent] = 0;
    fputs(spaces, stdout);
    c->indent += f->indent;

    if (name)
        if (before || meta == META_IS_BASIC || meta == META_IS_ID)
            printf(".%s = ", name);

    // type name
    const char *tname = NULL;

    switch (meta) {
        case META_IS_PRIV: {
            const struct node_rec *rec = &priv_recs[type];
            tname = rec->name;
            break;
        }
        case META_IS_NODE: {
            const struct node_rec *rec = &node_recs[type];
            tname = rec->name;
            break;
        }
        case META_IS_BASIC: {
            char buf[128];
            int size = sizeof buf;
            int result = fmt_call(meta, type, &size, buf, data);
            printf("%s", buf);
            break;
        }
        case META_IS_ID: {
            char buf[128];
            int size = sizeof buf;
            int result = fmt_call(meta, type, &size, buf, data);
            printf("%s", buf);
            break;
        }
        case META_IS_CHOICE: {
            c->last_idx = **(int**)data;
            break;
        }
        default:
            // TODO handle
            abort();
    }

    if (before) {
        if (!name) {
            printf("(struct %s)", tname);
        } else if (tname) {
            if (structp) {
                printf("&(struct %s)", tname);
            } else {
                printf("/* struct %s */ ", tname);
            }
        } else {
            printf("/* union */ { .idx = %d, .choice = ", c->last_idx);
        }
    } else if (after) {
        if (name && !tname) {
            // close out the union
            printf("} ");
        }
    }

    if (f->prefix)
        printf("%s", f->prefix);

    if ((after || once) && name)
        putchar(',');

    puts("");

    return 0;
}

static int c_top_op(const struct translation_unit *top)
{
    int result;

    struct mydata data = { .indent = 0, .last_idx = 0 };
    int flags = AST_WALK_BEFORE_CHILDREN | AST_WALK_AFTER_CHILDREN;
    ast_walk((struct node*)top, walk_cb, flags, &data);

    return result;
}

int (*main_walk_op)(const struct translation_unit *) = c_top_op;

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
