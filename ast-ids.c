#include "ast-pre.h"
#include "ast-ids.h"
#include "ast-ids-priv.h"
#include "ast.h"

#define STR_(Str) STR__(Str)
#define STR__(Str) #Str

#define MAKE(Sc,Key,...)        MAKE_##Sc(Key,__VA_ARGS__)

//------------------------------------------------------------------------------

#define MAKE_ID(Key,...)        [ID_TYPE_##Key] = { ID_TYPE_##Key, STR_(Key) },
#define MAKE_PRIV(...)
#define MAKE_NODE(Key,...)

const struct id_rec id_recs[] = {
    [ID_TYPE_node_type] = { ID_TYPE_node_type, "node" },
    #include "ast.xi"
};

#undef MAKE_ID
#undef MAKE_PRIV
#undef MAKE_NODE

//------------------------------------------------------------------------------

const struct basic_rec basic_recs[] = {
    #define R_(X) [BASIC_TYPE_##X] = { BASIC_TYPE_##X, #X, STR_(X), sizeof(X) },
    #include "basic-types.xi"
    #undef R_
};

//------------------------------------------------------------------------------

#define DEFITEM(...)
#define BASE(Key)               .base     = NODE_TYPE_##Key, \
                                .base_ptr = &node_parentages[NODE_TYPE_##Key],
#define MAKE_ID(Key,...)
#define MAKE_PRIV(...)
#define MAKE_NODE(Key,...) \
    [NODE_TYPE_##Key] = { .type = NODE_TYPE_##Key, \
                          .size = sizeof(struct Key), \
                          __VA_ARGS__ },

struct node_parentage node_parentages[] = {
    #include "ast.xi"
};

#undef BASE
#undef DEFITEM

#undef MAKE_ID
#undef MAKE_PRIV
#undef MAKE_NODE

//------------------------------------------------------------------------------

#define BASE(Key)
#define MAKE_ID(Key,...)
#define MAKE_PRIV(...)

// end-of-chain sentinel
#define EOC { .meta = META_IS_INVALID }

#define BASIC(T)                .meta = META_IS_BASIC, .c = { .basic = &basic_recs[BASIC_TYPE_##T] },
#define DEFITEM(...)            { __VA_ARGS__ },
#define CHOICE(Name,...)        .meta = META_IS_CHOICE, \
                                .name = STR_(Name), \
                                .c = { .choice = (struct node_item[]){ __VA_ARGS__ EOC } },
#define TYPED(T,X)              .name = STR_(X), T
#define REF_NODE(Key)           .meta = META_IS_NODE, \
                                .c = { .node = &node_recs[NODE_TYPE_##Key] },
#define REF_ID(Key)             .meta = META_IS_ID, \
                                .c = { .id   =   &id_recs[  ID_TYPE_##Key] },
#define REF_PRIV(Key)           .meta = META_IS_PRIV, \
                                .c = { .priv = &priv_recs[PRIV_TYPE_##Key] },
#define PTR(...)                .is_pointer = true, __VA_ARGS__
#define MAKE_NODE(Key,...) \
    [NODE_TYPE_##Key] = { .type  = NODE_TYPE_##Key, \
                          .name  = STR_(Key), \
                          .items = (struct node_item[]){ __VA_ARGS__ EOC } },

const struct node_rec node_recs[] = {
    #include "ast.xi"
};

#undef MAKE_NODE
#define MAKE_NODE(...)
#undef MAKE_PRIV
#define MAKE_PRIV(Key,...) \
    [PRIV_TYPE_##Key] = { .type  = PRIV_TYPE_##Key, \
                          .name  = STR_(Key), \
                          .items = (struct node_item[]){ __VA_ARGS__ EOC } },

const struct priv_rec priv_recs[] = {
    #include "ast.xi"
};

#undef BASE
#undef DEFITEM
#undef CHOICE
#undef TYPED
#undef PTR
#undef REF_NODE
#undef REF_ID

#undef EOC

#undef MAKE_ID
#undef MAKE_PRIV
#undef MAKE_NODE

// TODO offsetof ?

//------------------------------------------------------------------------------

#undef MAKE

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

