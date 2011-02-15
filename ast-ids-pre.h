#define MAKE(Sc,Key,...)        MAKE_##Sc(Key,__VA_ARGS__)
#define MAKE_ID(...)
#define MAKE_PRIV(...)
#define MAKE_NODE(Key,...)		NODE_TYPE_##Key,
