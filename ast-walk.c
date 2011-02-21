#include "ast-walk.h"
#include "ast-ids-priv.h"

#include <errno.h>

struct ast_walk_data {
    int dummy;
};

static int recurse_node(enum node_type type, struct node *node, ast_walk_cb cb,
        int flags, struct ast_walk_ops *ops, void *userdata, void *cookie);

static int recurse_any(enum meta_type meta, const struct node_item *parent, void *what, ast_walk_cb
        cb, int flags, struct ast_walk_ops *ops, void *userdata, void *cookie)
{
    #define CALLBACK(Mode) \
        cb(Mode, meta, parent->c.node->type, what, userdata, ops, cookie)

    int result   = -1,
        cbresult = -1;

    switch (meta) {
        case META_IS_NODE:
            cbresult = CALLBACK(AST_WALK_BETWEEN_CHILDREN);
            if (what)
                result = recurse_node(((struct node*)what)->node_type, what, cb, flags, ops, userdata, cookie);
            break;
        // TODO
        case META_IS_BASIC:
            //cbresult = CALLBACK(AST_WALK_BETWEEN_CHILDREN);
            cb(AST_WALK_BETWEEN_CHILDREN, meta, parent->c.node->type, &what, userdata, ops, cookie);
            break;
        case META_IS_CHOICE: {
            // CHOICE structs wrappers have as their first member an int
            // describing which member is selected. Zero means none ...
            int type = *(int*)what;
            if (type > 0) {
                // ... so we subtract one from the index.
                const struct node_item *citem = &parent->c.choice[type - 1];
                // XXX offset what by how much ? alignment issues
                struct { int dummy; union { struct anything* inner; } c; } *temp = what;
                result = recurse_any(citem->meta, citem, temp->c.inner, cb, flags, ops, userdata, cookie);
            }
            break;
        }
        default:
            break;
    }

    #undef CALLBACK

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
        void *child = item->is_pointer ? *(void**)childaddr : childaddr;
        result = recurse_any(item->meta, item, child, cb, flags, ops, userdata, cookie);
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

