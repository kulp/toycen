#define MAKE(Sc,Key,...)        MAKE_##Sc(Key,__VA_ARGS__)
#define MAKE_ID(Key,...)        ID_TYPE_##Key,
#define MAKE_PRIV(...)
#define MAKE_NODE(Key,...)
