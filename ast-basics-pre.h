#define MAKE(Sc,Key,...)        MAKE_##Sc(Key,__VA_ARGS__)
#define MAKE_ID(Key,...)
#define MAKE_PRIV(...)
#define MAKE_NODE(Key,...)      __VA_ARGS__
#define DEFITEM(...)            __VA_ARGS__
#define BASIC(T)                R_(T)
#define TYPED(T,X)              T
#define PTR(X)                  X
#define BASE(X)
#define CHOICE(X,...)           __VA_ARGS__
#define REF_NODE(X)
#define REF_ID(X)
#define REF_PRIV(X)
