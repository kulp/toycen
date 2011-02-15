#if DEBUG
// easier to debug structs than unions when calloc()ed
#define UNION_KEYWORD struct
#else
#define UNION_KEYWORD union
#endif

#define MAKE(Sc,Key,...)        DEF_##Sc(Key,__VA_ARGS__); MAKE_TYPE(Sc,Key);
#define MAKE_TYPE(Sc,Key)       typedef REF_##Sc(Key) T_##Key
#define DEF(Sc,Key,Name,...)    DEF_##Sc(Key,__VA_ARGS__)
#define REF(Sc,Key)             REF_##Sc(Key)

#define CHOICE(Name,...)        UNION_KEYWORD { __VA_ARGS__ } Name

#define BASE(Key) 				REF_NODE(Key) base;

#define DEF_ID(Key,...)         enum Key { __VA_ARGS__ }
#define REF_ID(Key)             enum Key
#define DEF_NODE(Key,...)       struct Key { __VA_ARGS__ }
#define REF_NODE(Key)           struct Key
#define DEF_PRIV(Key,...)       struct Key { __VA_ARGS__ }
#define REF_PRIV(Key)           struct Key

#define PTR(X)                  X*
#define TYPED(T,X)              T X
#define REFITEM(...)            __VA_ARGS__,
#define DEFITEM(...)            __VA_ARGS__;

#define ENUM_VAL(X,V)           X = V

