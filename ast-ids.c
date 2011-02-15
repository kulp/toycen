#include "ast-pre.h"
#include "ast-ids.h"

#define STR_(Str) STR__(Str)
#define STR__(Str) #Str

#define MAKE(Sc,Key,...)        MAKE_##Sc(Key,__VA_ARGS__)
#define MAKE_ID(Key,...)
#define MAKE_PRIV(...)
#define MAKE_NODE(Key,...)      [NODE_TYPE_##Key] = STR_(Key),

const char *node_type_names[] = {
    #include "ast.xi"
};

#undef MAKE
#undef MAKE_ID
#undef MAKE_PRIV
#undef MAKE_NODE

