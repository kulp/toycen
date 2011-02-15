#define MAKE(Sc,Key,...)        DEF_##Sc(Key,__VA_ARGS__);
#define DEF(Sc,Key,Name,...)    DEF_##Sc(Key,__VA_ARGS__)
#define REF(Sc,Key)             REF_##Sc(Key)

#define CHOICE(Name,...)        UNION_KEYWORD { __VA_ARGS__ } Name

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

#define ENUM_VAL(X,V)           X = V


