#ifndef AST_IDS_H_
#define AST_IDS_H_

#include <stdbool.h>
#include <stddef.h>

#include "ast-nodes-pre.h"
enum node_type {
    NODE_TYPE_INVALID,
    #include "ast.xi"
    NODE_TYPE_max
};
#include "ast-nodes-post.h"

#include "ast-privs-pre.h"
enum priv_type {
    PRIV_TYPE_INVALID,
    #include "ast.xi"
    PRIV_TYPE_max
};
#include "ast-privs-post.h"

#include "ast-ids-pre.h"
enum id_type {
    ID_TYPE_INVALID,
    ID_TYPE_node_type,
    #include "ast.xi"
    ID_TYPE_max
};
#include "ast-ids-post.h"

enum basic_type {
    BASIC_TYPE_INVALID,
    #define R_(X) BASIC_TYPE_##X,
    #include "basic-types.xi"
    #undef R_
    BASIC_TYPE_max
};

enum meta_type {
    META_IS_INVALID,    ///< also marks end of list
    META_IS_NODE,
    META_IS_ID,
    META_IS_CHOICE,
    META_IS_PRIV,
    META_IS_BASIC,
    META_IS_max
};

struct node_rec {
    enum node_type type;
    const char *name;
    size_t * const * const offp; ///< pointer to array due to limitations in preprocessor
    struct node_item *items;
};

struct priv_rec {
    enum priv_type type;
    const char *name;
    size_t * const * const offp; ///< pointer to array due to limitations in preprocessor
    struct node_item *items;
};

struct id_rec {
    enum id_type type;
    const char *name;
};

struct basic_rec {
    enum basic_type type;
    const char *defname;
    /// this is different only for _Bool so far. do we really want it ?
    const char *rawname;
    size_t size;
};

struct node_item {
    enum meta_type meta;
    bool is_pointer;
    const char *name;
    // we would like to have here the size for this node, but we don't have the
    // argument passed to the REF_*() macro that would tell us the first
    // argument to offsetof(), so we keep a parallel array in the node_recs[]
    #if 0
    size_t **offp; ///< pointer to an array parallel to the one containing me
    // this is to reduce the number of things that need to be passed around in
    // ast-walk
    #endif
    union {
        const struct node_rec *node;
        const struct priv_rec *priv;
        const struct id_rec *id;
        const struct node_item *choice;
        const struct basic_rec *basic;
    } c;
};

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

