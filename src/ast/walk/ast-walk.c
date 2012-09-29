#include "ast-walk.h"
#include "ast-ids-priv.h"

#include <assert.h>
#include <errno.h>
#include <stdlib.h>

#define countof(X) (sizeof (X) / sizeof (X)[0])

struct ast_walk_data {
    struct stack {
        const struct node_item *item;
        const char *name;
        struct stack *next;
    } *stack;
};
struct ast_xattrs;

//typedef struct ast_walk_data *walkdata;

static int recurse_priv(enum priv_type type, void *priv, ast_walk_cb cb,
        int flags, struct ast_walk_ops *ops, void *userdata, struct ast_walk_data *cookie);

static int recurse_node(enum node_type type, struct node *node, ast_walk_cb cb,
        int flags, struct ast_walk_ops *ops, void *userdata, struct ast_walk_data *cookie);

static int recurse_any(const struct node_item *parent, void *what, ast_walk_cb
        cb, int flags, struct ast_walk_ops *ops, void *userdata, struct ast_walk_data *cookie)
{
    int result   = -1,
        // TODO use cbresult
        cbresult = -1;

    if (!what) {
        errno = EFAULT;
        return -1;
    }

    void *deref = *(void**)what;

    switch (parent->meta) {
        case META_IS_PRIV:
            result = recurse_priv(parent->c.priv->type, what, cb, flags, ops,
                    userdata, cookie);
            break;
        case META_IS_NODE:
            if (deref)
                result = recurse_node(((struct node*)deref)->node_type,
                        deref, cb, flags, ops, userdata, cookie);
            break;
        case META_IS_ID:
        case META_IS_BASIC:
            cbresult = cb(flags & ~7, parent->meta, parent->c.node->type,
                    what, userdata, ops, cookie);
            break;
        case META_IS_CHOICE: {
            if (flags & AST_WALK_BEFORE_CHILDREN)
                cbresult = cb(AST_WALK_BEFORE_CHILDREN, parent->meta,
                        parent->c.node->type, what, userdata, ops, cookie);
			#if INHIBIT_INTROSPECTION
			// inhibited introspection prevents us from knowing which CHOICE
			// branch to follow
			#error "Inspection introhibited: can't walk"
			#endif
            // CHOICE structs wrappers have as their first member an int
            // describing which member is selected.
            // TODO ensure this cast is portable
            struct { int idx; union { alignment_type dummy; } c; } *generic = deref;
            // Zero means none ...
            if (generic->idx > 0) {
                // ... so we subtract one from the index.
                const struct node_item *citem = &parent->c.choice[generic->idx - 1];
                struct stack *s = calloc(1, sizeof *s);
                s->item = citem;
                s->name = citem->name;
                s->next = cookie->stack;
                cookie->stack = s;

                result = recurse_any(citem, &generic->c, cb, flags &
                        ~AST_WALK_IS_BASE, ops, userdata, cookie);

                s = cookie->stack;
                cookie->stack = s->next;
                free(s);
            }
            if (flags & AST_WALK_AFTER_CHILDREN)
                cbresult = cb(AST_WALK_AFTER_CHILDREN, parent->meta,
                        parent->c.node->type, what, userdata, ops, cookie);
            break;
        }
        // TODO remaining META_IS_*
        default:
            break;
    }

    return result;
}

// combine common parts of recurse_priv() and recurse_node()
static int recurse_priv_or_node(enum meta_type meta, int type, void *thing,
        ast_walk_cb cb, int flags, struct ast_walk_ops *ops, void *userdata,
        struct ast_walk_data *cookie)
{
    // TODO move parent-handling based on flags
    // TODO do something with results
    int cbresult = -1,
        result   = -1;

    bool am_priv = meta == META_IS_PRIV;

    const struct node_rec *rec = &(am_priv ? priv_recs : node_recs)[type];

    if (flags & AST_WALK_BEFORE_CHILDREN)
        cbresult = cb((flags & ~7) | AST_WALK_BEFORE_CHILDREN, meta, type,
                thing, userdata, ops, cookie);

    if (!am_priv) {
        /// @todo give flags control of BASE recursing
        enum node_type parent_type = node_parentages[type].base;
        if (parent_type != NODE_TYPE_INVALID) {
            struct stack *s = calloc(1, sizeof *s);
            s->item = NULL; // XXX is this a problem ?
            s->name = "base";
            s->next = cookie->stack;
            cookie->stack = s;

            result = recurse_node(parent_type, thing, cb, flags |
                    AST_WALK_IS_BASE, ops, userdata, cookie);

            s = cookie->stack;
            cookie->stack = s->next;
            free(s);
        }
    }

    /// @todo what if flags doesn't contain a BEFORE or AFTER ?
    for (int i = 0; rec->items[i].meta != META_IS_INVALID; i++) {
        int flags_ = flags; // localise
        const struct node_item *item = &rec->items[i];
        void *childaddr = (char*)thing + (*rec->offp)[i];
        void *child;
        bool has_allocation = !!item->is_pointer;

        if (has_allocation)
            flags_ |= AST_WALK_HAS_ALLOCATION;

        if (has_allocation || item->meta == META_IS_BASIC) {
            // if BASIC, unwrap, because we rewrap in recurse_any()
            child = *(void**)childaddr;
        } else {
            child = childaddr;
        }

        struct stack *s = calloc(1, sizeof *s);
        s->item = item;
        s->name = item->name;
        s->next = cookie->stack;
        cookie->stack = s;

        result = recurse_any(item, &child, cb, flags_, ops, userdata, cookie);

        if (flags_ & AST_WALK_BETWEEN_CHILDREN)
            cbresult = cb((flags_ & ~7) | AST_WALK_BETWEEN_CHILDREN, meta,
                    type, thing, userdata, ops, cookie);

        s = cookie->stack;
        cookie->stack = s->next;
        free(s);
    }

    if (flags & AST_WALK_AFTER_CHILDREN)
        cbresult = cb((flags & ~7) | AST_WALK_AFTER_CHILDREN, meta, type, thing, userdata, ops, cookie);

    return result;
}

static int recurse_priv(enum priv_type type, void *priv, ast_walk_cb cb,
        int flags, struct ast_walk_ops *ops, void *userdata, struct ast_walk_data *cookie)
{
    return recurse_priv_or_node(META_IS_PRIV, type, priv, cb, flags, ops, userdata, cookie);
}

static int recurse_node(enum node_type type, struct node *node, ast_walk_cb cb,
        int flags, struct ast_walk_ops *ops, void *userdata, struct ast_walk_data *cookie)
{
    return recurse_priv_or_node(META_IS_NODE, type, node, cb, flags, ops, userdata, cookie);
}

static int get_name(walkdata cookie, const char **name)
{
    struct ast_walk_data *data = cookie;

    if (!data->stack) {
        errno = EFAULT;
        return -1;
    }

    *name = data->stack->name;

    return 0;
}

static int get_childcnt(walkdata cookie, int *count)
{
    struct ast_walk_data *data = cookie;

    if (!data->stack) {
        errno = EFAULT;
        return -1;
    }

    struct node_item *item = data->stack->item->c.node->items;
    int tick = 0;
    do tick++; while ((item++)->meta != META_IS_INVALID);

    *count = tick;

    return 0;
}

static int get_xattrs(walkdata cookie, struct ast_xattrs *attrs)
{
    struct ast_walk_data *data = cookie;

    if (!data->stack) {
        errno = EFAULT;
        return -1;
    }

    // XXX in which cases will item be NULL ? there is a 
    //assert(data->stack->item != NULL);
    if (data->stack->item) {
        attrs->is_pointer = data->stack->item->is_pointer;
    }

    return 0;
}

int ast_walk(struct node *top, ast_walk_cb cb, int flags, void *userdata)
{
    struct ast_walk_data cookie = { 0 };
    struct ast_walk_ops ops = {
        .get_name     = get_name,
        .get_childcnt = get_childcnt,
        .get_xattrs   = get_xattrs,
    };

    if (top->node_type > NODE_TYPE_max ||
        top->node_type == NODE_TYPE_INVALID)
    {
        errno = EINVAL;
        return -1;
    }

    return recurse_node(top->node_type, top, cb, flags, &ops, userdata, &cookie);
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

