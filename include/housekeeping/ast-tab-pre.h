#define MAKE(Sc,Key,...)        DEF_##Sc(Key,__VA_ARGS__);
#define DEF(Sc,Key,Name,...)    DEF_##Sc(Key,__VA_ARGS__)
#define REF(Sc,Key)             REF_##Sc(Key)

#if INHIBIT_INTROSPECTION
#define CHOICE(Name,...)        union { __VA_ARGS__ alignment_type alignment_dummy_; } Name
#else
#define CHOICE(Name,...)        struct { int idx; union { __VA_ARGS__ alignment_type alignment_dummy_; } choice; } Name
#endif

#define BASE(Key)               DEFITEM(TYPED(REF_NODE(Key),base))

#define DEF_ID(Key,...)         enum Key { __VA_ARGS__ }
#define REF_ID(Key)             enum Key
#define DEF_NODE(Key,...)       struct Key { __VA_ARGS__ }
#define REF_NODE(Key)           struct Key
#define DEF_PRIV(Key,...)       struct Key { __VA_ARGS__ }
#define REF_PRIV(Key)           struct Key

#define BASIC(T)                T
#define PTR(X)                  X*
#define TYPED(T,X)              T X
#define REFITEM(X)              X,
#define DEFITEM(X)              X;

#define ENUM_VAL(P,K,V)         P##_##K = V
#define ENUM_DFL(P,K)           P##_##K

