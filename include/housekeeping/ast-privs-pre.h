#define MAKE(Sc,Key,...)        MAKE_##Sc(Key,__VA_ARGS__)
#define MAKE_ID(...)
#define MAKE_PRIV(Key,...)		PRIV_TYPE_##Key,
#define MAKE_NODE(...)
