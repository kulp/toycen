#include "ast-walk.h"
#include "ast.h"

/**
 * Walks the abstract syntax tree starting at @p top.
 *
 * The callback function @p cb is called for each node / private structure /
 * choice / basic type / id in the tree below @p top. The callback will receive
 * parameters describing the current node, and can query additional properties
 * using the @c ops structure passed to it.
 *
 * @see ast_walk_cb
 * @see ast_walk_ops
 *
 * @param top       the starting node, often a translation_unit
 * @param cb        the callback function to call for each node
 * @param userdata  an opaque pointer for callback-private data
 *
 * @return 0 on success
 * @return -1 on error (check @c errno for details)
 */
// TODO or use void *top so a cast is not needed ?
int ast_walk(struct node *top, ast_walk_cb cb, void *userdata);

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

