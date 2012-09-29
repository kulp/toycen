#include "ast-walk.h"
#include "ast-ids-priv.h"
#include "ast-formatters.h"

#include <stdio.h>
#include <stdlib.h>

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
    (void)(userdata,ops,cookie);

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
        case META_IS_CHOICE:
            // TODO implement
            break;
        default:
            // TODO handle
            abort();
    }

    return 0;
}

static int test_top_op(const struct translation_unit *top)
{
    int result;

    result = ast_walk((struct node*)top, walk_cb, AST_WALK_BEFORE_CHILDREN, 0);

    return result;
}

int (*main_walk_op)(const struct translation_unit *) = test_top_op;

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
