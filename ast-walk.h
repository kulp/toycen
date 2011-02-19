#include "ast-ids.h"

/// 
typedef void *walkdata;

struct ast_walk_ops {
    /// not integrated into get_children because it is probably generated
    /// programmatically and potentially often unused by the walk callback
    int (*get_childcnt)(walkdata cookie, int *count);
    int (*get_children)(walkdata cookie, struct node_item **children);
    int (*get_parent  )(walkdata cookie, struct node_item **parent);
};

/**
 * A callback invoked during the walking of an abstract syntax tree.
 *
 * @param meta      the metatype of the node
 * @param type      the type of the node (cast from the appropriate enum)
 * @param userdata  the user-supplied callback-private opaque pointer
 * @param ops       a set of operations available to the callback
 * @param cookie    an opaque pointer used by the ops in @p ops
 *
 * @return 0 on success
 * @return -1 on error (check @c errno for details)
 */
typedef int (*ast_walk_cb)(
        enum meta_type meta,
        unsigned type,
        void *userdata,
        struct ast_walk_ops *ops,
        walkdata cookie
    );

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

