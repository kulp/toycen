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

#define DEFITEM(X)
#define BASE(Key)               .base     = NODE_TYPE_##Key, \
                                .base_ptr = &node_parentages[NODE_TYPE_##Key],
#define MAKE_ID(Key,...)
#define MAKE_PRIV(...)
#define MAKE_NODE(Key,...) \
    [NODE_TYPE_##Key] = { .type = NODE_TYPE_##Key, \
                          .size = sizeof(T_##Key), \
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

#include "ast-recurse.h"
#define ONE_(Key,F) offsetof(T_##Key, F)

#define NARGS(...) NARGS_IMPL(__VA_ARGS__,9,8,7,6,5,4,3,2,1)
#define NARGS_IMPL(_1,_2,_3,_4,_5,_6,_7,_8,_9,N,...) N

#define BASE(X) /* always at 0 */
#define CHOICE(Name,...) Name /* don't need to recurse, union => same offset */
#define TYPED(T,X) X
#define DEFITEM(X) X,

#define MAKE_ID(...)
#define MAKE_NODE(...) MAKE2(NODE,__VA_ARGS__)
#define MAKE_PRIV(...)
#define MAKE2(Sc,Key,...) \
    [Sc##_TYPE_##Key] = { .type  = Sc##_TYPE_##Key, \
                          .items = (size_t[]){ OFF_(NARGS(__VA_ARGS__))(Key,__VA_ARGS__) } },

const struct node_offset node_offsets[] = {
    #include "ast.xi"
};

#undef MAKE_PRIV
#undef MAKE_NODE
#define MAKE_NODE(...)
#define MAKE_PRIV(...) MAKE2(PRIV,__VA_ARGS__)

const struct priv_offset priv_offsets[] = {
    #include "ast.xi"
};

#undef MAKE_PRIV

#undef MAKE2

#undef DEFITEM
#undef OFF_
#undef CAT
#undef NARGS_IMPL
#undef NARGS

#undef BASE
#undef CHOICE

#undef OFF_1
#undef OFF_2
#undef OFF_3
#undef OFF_4
#undef OFF_5
#undef OFF_6
#undef OFF_7
#undef ONE_

#undef MAKE_NODE
#undef MAKE_PRIV
#undef MAKE_ID
#undef TYPED

//------------------------------------------------------------------------------

#define BASE(Key)
#define MAKE_ID(Key,...)
#define MAKE_PRIV(...)

// end-of-chain sentinel
#define EOC { .meta = META_IS_INVALID }

#define BASIC(T)                .meta = META_IS_BASIC, .c = { .basic = &basic_recs[BASIC_TYPE_##T] },
#define DEFITEM(X)              { X },
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
#define MAKE2(Sc,sc,Key,...) \
    [Sc##_TYPE_##Key] = { .type  = Sc##_TYPE_##Key, \
                          .name  = STR_(Key), \
                          .offp = &sc##_offsets[Sc##_TYPE_##Key].items, \
                          .items = (struct node_item[]){ __VA_ARGS__ EOC } },

#define MAKE_NODE(...) MAKE2(NODE,node,__VA_ARGS__)
#define MAKE_PRIV(...)

const struct node_rec node_recs[] = {
    #include "ast.xi"
};

#undef MAKE_NODE
#undef MAKE_PRIV
#define MAKE_NODE(...)
#define MAKE_PRIV(...) MAKE2(PRIV,priv,__VA_ARGS__)

const struct priv_rec priv_recs[] = {
    #include "ast.xi"
};

#undef MAKE2
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

