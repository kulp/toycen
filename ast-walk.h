#include "ast.h"

/// 
typedef void *walkdata;

struct ast_walk_ops {
    /// not integrated into get_children because it is probably generated
    /// programmatically and potentially often unused by the walk callback
    int (*get_childcnt)(walkdata cookie, int *count);
    int (*get_children)(walkdata cookie, struct node_item **children);
    int (*get_parent  )(walkdata cookie, struct node_item **parent);

    int (*prune)(walkdata cookie, int flags);
};

enum ast_walk_flags {
    AST_WALK_DEFAULT = 0,

    AST_WALK_BEFORE_CHILDREN  = 1,
    AST_WALK_AFTER_CHILDREN   = 2,
    AST_WALK_BETWEEN_CHILDREN = 4,

    AST_WALK_PRUNE_SIBLINGS = 1,
};

/**
 * A callback invoked during the walking of an abstract syntax tree.
 *
 * @param flags     #ast_walk_flags appertaining to this callback invocation
 * @param meta      the metatype of the node
 * @param type      the type of the node (cast from the appropriate enum)
 * @param data      a pointer to the node / choice / id / priv / etc.
 * @param userdata  the user-supplied callback-private opaque pointer
 * @param ops       a set of operations available to the callback
 * @param cookie    an opaque pointer used by the ops in @p ops
 *
 * @return 0 on success
 * @return -1 on error (check @c errno for details)
 */
typedef int (*ast_walk_cb)(
        int flags,
        enum meta_type meta,
        unsigned type,
        void *data,
        void *userdata,
        struct ast_walk_ops *ops,
        walkdata cookie
    );

/**
 * Walks the abstract syntax tree starting at @p top.
 *
 * The callback function @p cb is called for each node / private structure /
 * choice / basic type / id in the tree below @p top. The callback will receive
 * parameters describing the current node, and can query additional properties
 * using the @c ops structure passed to it.
 *
 * @see ::ast_walk_cb
 * @see ast_walk_ops
 * @see #ast_walk_flags
 *
 * @param top       the starting node, often a translation_unit
 * @param cb        the callback function to call for each node
 * @param flags     flags modifying the behavior of the walk
 * @param userdata  an opaque pointer for callback-private data
 *
 * @return 0 on success
 * @return -1 on error (check @c errno for details)
 */
// TODO or use void *top so a cast is not needed ?
int ast_walk(struct node *top, ast_walk_cb cb, int flags, void *userdata);

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

