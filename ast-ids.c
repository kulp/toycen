#include "ast-pre.h"
#include "ast-ids.h"
#include "ast.h"

#define STR_(Str) STR__(Str)
#define STR__(Str) #Str

#define MAKE(Sc,Key,...)        MAKE_##Sc(Key,__VA_ARGS__)
#define MAKE_ID(Key,...)
#define MAKE_PRIV(...)
#define MAKE_NODE(Key,...)      [NODE_TYPE_##Key] = STR_(Key),

const char *node_type_names[] = {
    #include "ast.xi"
};

#undef MAKE_ID
#undef MAKE_PRIV
#undef MAKE_NODE

#define MAKE_ID(Key,...)        [ID_TYPE_##Key] = STR_(Key),
#define MAKE_PRIV(...)
#define MAKE_NODE(Key,...)

const char *id_type_names[] = {
    #include "ast.xi"
};

#undef MAKE_ID
#undef MAKE_PRIV
#undef MAKE_NODE

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

#define BASE(Key)
#define MAKE_ID(Key,...)
#define MAKE_PRIV(...)

#define BASIC(T)                .meta = META_IS_BASIC, /*TODO*/
#define DEFITEM(...)            { __VA_ARGS__ },
#define CHOICE(Name,...)        .meta     = META_IS_CHOICE, \
                                .c.choice = (struct node_item[]){ __VA_ARGS__ { .meta = META_IS_INVALID } },
#define TYPED(T,X)              .name = STR_(X), T
#define REF_NODE(Key)           .meta = META_IS_NODE, .c.node_type = NODE_TYPE_##Key,
#define REF_ID(Key)             .meta = META_IS_ID  , .c.id_type   =   ID_TYPE_##Key,
#define REF_PRIV(Key)           /*TODO*/
#define PTR(...)                .is_pointer = true, __VA_ARGS__
#define MAKE_NODE(Key,...) \
    [NODE_TYPE_##Key] = { .type  = NODE_TYPE_##Key, \
                          .items = (struct node_item[]){ __VA_ARGS__ { .meta = META_IS_INVALID } } },

struct node_field node_fields[] = {
    #include "ast.xi"
};

#undef BASE
#undef DEFITEM
#undef CHOICE
#undef TYPED
#undef PTR
#undef REF_NODE
#undef REF_ID

#undef MAKE_ID
#undef MAKE_PRIV
#undef MAKE_NODE

//------------------------------------------------------------------------------

#undef MAKE

