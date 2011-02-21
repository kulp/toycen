#include "ast-walk.h"
#include "ast-ids-priv.h"

#include <errno.h>

struct ast_walk_data {
    int dummy;
};

static int recurse_node(enum node_type type, struct node *node, ast_walk_cb cb,
        int flags, struct ast_walk_ops *ops, void *userdata, void *cookie);

static int recurse_any(const struct node_item *parent, void *what, ast_walk_cb
        cb, int flags, struct ast_walk_ops *ops, void *userdata, void *cookie)
{
    int result   = -1,
        // TODO use cbresult
        cbresult = -1;

    void *deref = *(void**)what;

    switch (parent->meta) {
        case META_IS_NODE:
            cbresult = cb(AST_WALK_BETWEEN_CHILDREN, parent->meta,
                    parent->c.node->type, deref, userdata, ops, cookie);

            if (deref)
                result = recurse_node(((struct node*)deref)->node_type,
                        deref, cb, flags, ops, userdata, cookie);
            break;
        case META_IS_BASIC:
            // TODO correct flags
            cbresult = cb(AST_WALK_BETWEEN_CHILDREN, parent->meta,
                    parent->c.node->type, what, userdata, ops, cookie);
            break;
        case META_IS_CHOICE: {
            // CHOICE structs wrappers have as their first member an int
            // describing which member is selected.
            // TODO ensure this cast is portable; long double should ensure
            // alignment for any primitive ?
            struct { int idx; union { long double dummy; } c; } *generic = deref;
            // Zero means none ...
            if (generic->idx > 0) {
                // ... so we subtract one from the index.
                const struct node_item *citem = &parent->c.choice[generic->idx - 1];
                result = recurse_any(citem, &generic->c, cb, flags, ops,
                        userdata, cookie);
            }
            break;
        }
        // TODO remaining META_IS_*
        default:
            break;
    }

    return result;
}

static int recurse_node(enum node_type type, struct node *node, ast_walk_cb cb,
        int flags, struct ast_walk_ops *ops, void *userdata, void *cookie)
{
    // TODO move parent-handling based on flags
    // TODO do something with results
    int cbresult, result;

    cbresult = cb(AST_WALK_BEFORE_CHILDREN, META_IS_NODE, type, node, userdata, ops, cookie);

    const struct node_rec *rec = &node_recs[type];
    int i = 0;
    /// @todo give flags control of BASE recursing
    enum node_type parent_type = node_parentages[type].base;
    if (parent_type != NODE_TYPE_INVALID)
        result = recurse_node(parent_type, node, cb, flags, ops, userdata, cookie);

    /// @todo what if flags doesn't contain a BEFORE or AFTER ?
    while (rec->items[i].meta != META_IS_INVALID) {
        struct node_item *item = &rec->items[i];
        void *childaddr = (char*)node + (*rec->offp)[i];
        void *child;
        if (item->is_pointer || item->meta == META_IS_BASIC) {
            // if BASIC, unwrap, because we rewrap in recurse_any()
            child = *(void**)childaddr;
        } else {
            child = childaddr;
        }

        if (child)
            result = recurse_any(item, &child, cb, flags, ops, userdata, cookie);
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

    return recurse_node(top->node_type, top, cb, flags, &ops, userdata, &cookie);
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

