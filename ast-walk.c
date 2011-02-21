#include "ast-walk.h"
#include "ast-ids-priv.h"

#include <errno.h>

struct ast_walk_data {
    int dummy;
};

static int ast_walk_recursive(struct node *node, ast_walk_cb cb, int flags, struct
        ast_walk_ops *ops, void *userdata, void *cookie)
{
    // TODO move parent-handling based on flags
    // TODO do something with results
    int cbresult, result;

    cbresult = cb(AST_WALK_BEFORE_CHILDREN, META_IS_NODE, node->node_type, node, userdata, ops, cookie);

    const struct node_rec *rec = &node_recs[node->node_type];
    int i = 0;
//#define HANDLE_PARENT
    /// @todo what if flags doesn't contain a BEFORE or AFTER ?
    while (rec->items[i].meta != META_IS_INVALID) {
        struct node_item *item = &rec->items[i];
        void *child = *(void**)(((char*)node) + (*rec->offp)[i]);
        switch (item->meta) {
            case META_IS_NODE:
                cbresult = cb(AST_WALK_BETWEEN_CHILDREN, item->meta, item->c.node->type, child, userdata, ops, cookie);
                if (child)
                    result = ast_walk_recursive(child, cb, flags, ops, userdata, cookie);
                break;
            // TODO
            //case META_IS
        }
        i++;
    }

    return -1;
}

int ast_walk(struct node *top, ast_walk_cb cb, int flags, void *userdata)
{
    struct ast_walk_data cookie = { 0 };
    struct ast_walk_ops ops = { .prune = 0 };

    if (top->node_type > NODE_TYPE_max ||
        top->node_type == NODE_TYPE_INVALID)
    {
        errno = EINVAL;
        return -1;
    }

    return ast_walk_recursive(top, cb, flags, &ops, userdata, &cookie);
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

