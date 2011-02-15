#if 1
#include <stdbool.h>
#include <stddef.h>
#endif

#if DEBUG
// easier to debug structs than unions when calloc()ed
#define UNION_KEYWORD struct
#else
#define UNION_KEYWORD union
#endif

#define MAKE(Sc,Key,...)        DEF_##Sc(Key,__VA_ARGS__); MAKE_TYPE(Sc,Key);
#define MAKE_TYPE(Sc,Key)       typedef REF_##Sc(Key) T_##Key
#define DEF(Sc,Key,Name,...)    DEF_##Sc(Key,__VA_ARGS__)
#define REF(Sc,Key,Name,...)    REF_##Sc(Key) Name

#define CHOICE(...)             UNION_KEYWORD { __VA_ARGS__ } c

#define DEF_ID(Key,...)         enum Key { __VA_ARGS__ }
#define REF_ID(Key)             enum Key
#define DEF_NODE(Key,...)       struct Key { enum node_type type; __VA_ARGS__ }
#define REF_NODE(Key)           struct Key
#define DEF_PRIV(Key,...)       struct Key { __VA_ARGS__ }
#define REF_PRIV(Key)           struct Key

#define PTR(X)                  X*
#define TYPED_(T,X)             T X
#define REFITEM_(...)           __VA_ARGS__,
#define DEFITEM_(...)           __VA_ARGS__;

#define ENUM_VAL(X,V)           X = V

/// @todo

MAKE(ID,node_type,
        REFITEM_(NT_max)
    )

MAKE(NODE,node,
        /* only node_type, already there */
    )

MAKE(ID,assignment_operator,
        REFITEM_(AO_INVALID)
        REFITEM_(AO_MULEQ)
        REFITEM_(AO_DIVEQ)
        REFITEM_(AO_MODEQ)
        REFITEM_(AO_ADDEQ)
        REFITEM_(AO_SUBEQ)
        REFITEM_(AO_SLEQ)
        REFITEM_(AO_SREQ)
        REFITEM_(AO_ANDEQ)
        REFITEM_(AO_XOREQ)
        REFITEM_(AO_OREQ)
        REFITEM_(ENUM_VAL(AO_EQ,'='))
    )

MAKE(PRIV,assignment_inner_,
        DEFITEM_(TYPED_(PTR(REF_NODE(unary_expression)),left))
        DEFITEM_(TYPED_(REF_ID(assignment_operator),op))
        DEFITEM_(TYPED_(PTR(REF_NODE(assignment_expression)),right))
    )

#if 0
DEF_NODE(node,REF(ID,node,node_type))

DEF(NODE,node,REF(ID,node,node_type))

struct node {
    enum node_type type;
};
#endif

enum type_class {
    TC_INVALID,
    TC_VOID,
    TC_INT,
    TC_FLOAT,
    TC_STRUCT,
    TC_UNION,
    TC_max
};

enum primary_expression_type {
    PRET_INVALID,
    PRET_IDENTIFIER,
    PRET_INTEGER,
    PRET_CHARACTER,
    PRET_FLOATING,
    PRET_STRING,
    PRET_PARENTHESIZED
};

enum expression_type {
    ET_INVALID,
    ET_CAST_EXPRESSION,
    ET_MULTIPLICATIVE_EXRESSION,
    /// @todo fill in the rest
    ET_max
};

enum unary_operator {
    UO_INVALID,
    UO_ADDRESS_OF     = '&',
    UO_DEREFERENCE    = '*',
    UO_PLUS           = '+',
    UO_MINUS          = '-',
    UO_BITWISE_INVERT = '~',
    UO_LOGICAL_INVERT = '!'
};

enum binary_operator {
    /// @todo but what about multi-character operators
    BO_INVALID,
    BO_ADD            = '+',
    BO_SUBTRACT       = '-',
    BO_MULTIPLY       = '*',
    BO_DIVIDE         = '/',
    BO_MODULUS        = '%',
    BO_BITWISE_AND    = '&',
    BO_max
};

enum increment_operator {
    IO_INCREMENT,
    IO_DECREMENT
};

#if 0
struct assignment_expression {
    bool has_op;
    union {
        struct conditional_expression *right;
        struct {
            struct unary_expression *left;
            enum assignment_operator {
                AO_INVALID,
                AO_MULEQ,
                AO_DIVEQ,
                AO_MODEQ,
                AO_ADDEQ,
                AO_SUBEQ,
                AO_SLEQ,
                AO_SREQ,
                AO_ANDEQ,
                AO_XOREQ,
                AO_OREQ,
                AO_EQ = '='
            } op;
            struct assignment_expression *right;
        } assn;
    } val;
};
#endif

MAKE(NODE,assignment_expression,
        DEFITEM_(TYPED_(bool,has_op))
        DEFITEM_(CHOICE(
            DEFITEM_(TYPED_(PTR(REF_NODE(conditional_expression)),right))
            DEFITEM_(TYPED_(REF_NODE(assignment_inner_),assn))
        ))
    )

struct expression {
    struct assignment_expression right;
    struct expression *left;
};

struct specifier_qualifier_list {
    enum { SQ_HAS_TYPE_SPEC, SQ_HAS_TYPE_QUAL } type;
    struct specifier_qualifier_list *next;
};

enum type_qualifier {
    TQ_INVALID,
    TQ_CONST,
    TQ_VOLATILE
};

struct type_qualifier_list {
    enum type_qualifier me;
    struct type_qualifier_list *left;
};

struct pointer {
    struct type_qualifier_list *tq;
    struct pointer *right;
};

struct direct_abstract_declarator {
    enum direct_abstract_declarator_subtype {
        DA_INVALID,
        DA_PARENTHESIZED,
        DA_ARRAY_INDEX,
        DA_FUNCTION_CALL,
    } type;
    union {
        struct abstract_declarator *abs;
        struct {
            struct direct_abstract_declarator *left;
            struct constant_expression *idx;
        } array;
        struct {
            struct direct_abstract_declarator *left;
            struct parameter_type_list *params;
        } function;
    } me;
};

struct abstract_declarator {
    struct pointer *ptr;
    struct direct_abstract_declarator *right;
};

struct type_name {
    struct specifier_qualifier_list *list;
    struct abstract_declarator *decl;
};

struct identifier {
    size_t len;
    char *name;
};

struct integer {
    size_t size;
    bool is_signed;
    union {
        short s;
        int i;
        long l;
        long long ll;
        signed short ss;
        signed int si;
        signed long sl;
        signed long long sll;
        unsigned short us;
        unsigned int ui;
        unsigned long ul;
        unsigned long long ull;
    } me;
};

struct character {
    /// @todo support wchars ?
    //size_t size;
    bool has_signage;
    bool is_signed;
    union {
        char c;
        signed char lc;
        unsigned char uc;
    } me;
};

struct floating {
    size_t size;
    union {
        float f;
        double d;
        long double ld;
    } me;
};

struct string {
    size_t size;
    struct character *value;
    char *cached;
};

struct _expression_having_type {
    enum expression_type type;
};

struct primary_expression {
    struct _expression_having_type base;
    enum primary_expression_type type;
    union {
        struct identifier *id;
        struct integer *i;
        struct character *c;
        struct floating *f;
        struct string *s;
        struct expression *e;
    } me;
};

struct argument_expression_list {
    struct assignment_expression base;
    struct argument_expression_list *left;
};

struct postfix_expression {
    //struct primary_expression me;
    enum postfix_expression_type {
        PET_INVALID,
        PET_PRIMARY,
        PET_ARRAY_INDEX,
        PET_FUNCTION_CALL,
        PET_AGGREGATE_SELECTION,
        PET_AGGREGATE_PTR_SELECTION,
        PET_POSTINCREMENT,
        PET_POSTDECREMENT
    } type;
    union {
        struct primary_expression *pri;
        struct postfix_expression *left;
        struct {
            struct postfix_expression *left;
            struct expression *index;
        } array;
        struct {
            struct postfix_expression *left;
            struct argument_expression_list *ael;
        } function;
        struct {
            struct postfix_expression *left;
            struct identifier *designator;
        } aggregate;
    } me;
    //struct postfix_expression *left;
};

struct unary_expression {
    struct postfix_expression me;
    enum unary_expression_type {
        UET_INVALID,
        UET_POSTFIX,
        UET_PREINCREMENT,
        UET_PREDECREMENT,
        UET_UNARY_OP,
        UET_SIZEOF_EXPR,
        UET_SIZEOF_TYPE
    } type;
    union {
        struct unary_expression *ue;
        struct {
            enum unary_operator uo;
            struct cast_expression *ce;
        } ce;
        struct type_name *tn;
    } val;
};

struct cast_expression {
    union {
        struct unary_expression *unary;
        struct {
            struct cast_expression *ce;
            struct type_name *tn;
        } cast;
    } me;
};

struct multiplicative_expression {
    struct cast_expression right;
    struct multiplicative_expression *left; ///< may be NULL
    enum binary_operator op;                ///< if @c is NULL, nonsensical
};

struct additive_expression {
    struct multiplicative_expression right;
    struct additive_expression *left;       ///< may be NULL
    enum binary_operator op;                ///< if @c is NULL, nonsensical
};

struct shift_expression {
    struct additive_expression base;
    enum shift_operator { SO_LSH, SO_RSH } op;
    struct shift_expression *left;
};

struct relational_expression {
    struct shift_expression right;
    enum relational_operator { RO_LT, RO_GT, RO_LTEQ, RO_GTEQ } op;
    struct relational_expression *left;
};

struct equality_expression {
    struct relational_expression right;
    bool eq;
    struct equality_expression *left;
};

struct and_expression {
    struct equality_expression right;
    struct and_expression *left;
};

struct exclusive_or_expression {
    struct and_expression right;
    struct exclusive_or_expression *left;
};

struct inclusive_or_expression {
    struct exclusive_or_expression right;
    struct inclusive_or_expression *left;
};

struct logical_and_expression {
    struct inclusive_or_expression right;
    struct logical_and_expression *left;
};

struct logical_or_expression {
    struct logical_and_expression right;
    struct logical_or_expression *left;
};

struct conditional_expression {
    struct logical_or_expression right;
    bool is_ternary;
    struct expression *if_expr;
    struct conditional_expression *else_expr;
};

struct constant_expression {
    struct conditional_expression right;
    char dummy; ///< to avoid warnings about empty initializer braces, since there is nothing to initialize
};

struct aggregate_definition {
    bool TODO; /// @todo
};

struct aggregate_definition_list {
    struct aggregate_definition *me;
    struct aggregate_definition_list *prev;
};

struct aggregate_declaration {
    struct specifier_qualifier_list *sq;
    struct aggregate_declarator_list *decl;
};

struct aggregate_declaration_list {
    struct aggregate_declaration *me;
    struct aggregate_declaration_list *prev;
};

struct aggregate_specifier {
    struct node base;
    enum aggregate_type { AT_UNION, AT_STRUCT } type;
    bool has_id;
    struct identifier *id;
    bool has_list;
    struct aggregate_declaration_list *list;
};

struct enumerator {
    struct identifier *id;
    struct constant_expression *val;
};

struct enumerator_list {
    struct enumerator *me;
    struct enumerator_list *prev;
};

struct enum_specifier {
    struct node base;
    bool has_id;
    struct identifier *id;
    bool has_list;
    struct enumerator_list *list;
};

struct type_specifier {
    struct node base;
    enum type_specifier_type {
        TS_INVALID,
        TS_VOID,
        TS_CHAR,
        TS_SHORT,
        TS_INT,
        TS_LONG,
        TS_FLOAT,
        TS_DOUBLE,
        TS_SIGNED,
        TS_UNSIGNED,
        TS_STRUCT_OR_UNION_SPEC,
        TS_ENUM_SPEC,
        TS_TYPEDEF_NAME
    } type;
    union {
        struct aggregate_specifier *as;
        struct enum_specifier *es;
        struct type_name *tn;
    } val;
};

enum storage_class_specifier {
    SCS_INVALID,
    SCS_TYPEDEF,
    SCS_EXTERN,
    SCS_STATIC,
    SCS_AUTO,
    SCS_REGISTER
};

struct declaration_specifiers {
    enum declaration_specifiers_subtype { DS_HAS_STORAGE_CLASS, DS_HAS_TYPE_SPEC, DS_HAS_TYPE_QUAL } type;
    union {
        enum storage_class_specifier scs;
        struct type_specifier *ts;
        enum type_qualifier tq;
    } me;
    struct declaration_specifiers *right;
};

struct parameter_declaration {
    struct declaration_specifiers base;
    enum parameter_declaration_subtype { PD_HAS_NONE, PD_HAS_DECL, PD_HAS_ABSTRACT_DECL } type;
    union {
        struct declarator *decl;
        struct abstract_declarator *abstract;
    } decl;
};

struct parameter_list {
    struct parameter_declaration base;
    struct parameter_list *left;
};

struct parameter_type_list {
    struct parameter_list base;
    bool has_ellipsis;
};

struct identifier_list {
    struct identifier base;
    struct identifier_list *left;
};

struct direct_declarator {
    enum direct_declarator_type {
        DD_INVALID,
        DD_IDENTIFIER,
        DD_PARENTHESIZED,
        DD_ARRAY,
        DD_FUNCTION,
    } type;
    union {
        struct identifier *id;
        struct declarator *decl;
        struct {
            struct direct_declarator *left;
            struct constant_expression *index;
        } array;
        struct {
            struct direct_declarator *left;
            enum function_declarator_subtype { FD_HAS_NONE, FD_HAS_PLIST, FD_HAS_ILIST } type;
            union {
                struct parameter_type_list *param;
                struct identifier_list *ident;
            } list;
        } function;
    /// @todo unify "me" and "val" synonyms / overlap
    } val;
};

struct declarator {
    struct direct_declarator base;
    bool has_pointer;
};

struct initializer {
    enum initializer_subtype { I_ASSIGN, I_INIT_LIST } type;
    union {
        struct assignment_expression *ae;
        struct initializer_list *il;
    } me;
};

struct initializer_list {
    struct initializer me;
    struct initializer_list *left;
};

struct init_declarator {
    struct declarator base;
    struct initializer *init;
};

struct init_declarator_list {
    struct init_declarator base;
    struct init_declarator_list *left;
};

struct declaration {
    struct declaration_specifiers base;
    struct init_declarator_list *decl;
};

struct aggregate_declarator {
    bool has_decl;
    struct declarator *decl;
    bool has_bitfield;
    struct constant_expression *bf;
};

struct aggregate_declarator_list {
    struct aggregate_declarator base;
    struct aggregate_declarator_list *prev;
};

// control

struct expression_statement {
    struct expression *expr;
};

struct selection_statement {
    enum selection_statement_subtype { ES_IF, ES_SWITCH } type;
    struct expression *cond;
    struct statement *if_stat;
    struct statement *else_stat;
};

struct labeled_statement {
    enum labeled_statement_subtype {
        LS_LABELED,
        LS_CASE
        // LS_CASE with case_id == NULL means default
    } type;
    struct statement *right;
    union {
        struct identifier *id;
        struct constant_expression *case_id;
    } me;
};

struct declaration_list {
    struct declaration base;
    struct declaration_list *left;
};

struct compound_statement {
    /// @todo support mixed declarations and statements as C99 demands
    struct declaration_list *dl;
    struct statement_list *st;
};

struct iteration_statement {
    enum iteration_statement_subtype {
        IST_WHILE, IST_DO_WHILE, IST_FOR
    } type;
    struct statement *action;
    struct expression *before_expr;
    struct expression *while_expr;
    struct expression *after_expr;
};

struct jump_statement {
    enum jump_statement_subtype {
        JS_GOTO, JS_CONTINUE, JS_BREAK, JS_RETURN
    } type;
    union {
        struct identifier *goto_id;
        struct expression *return_expr;
    } me;
};

struct statement {
    enum statement_type {
        ST_LABELED,
        ST_COMPOUND,
        ST_EXPRESSION,
        ST_SELECTION,
        ST_ITERATION,
        ST_JUMP
    } type;
    union {
        struct labeled_statement *ls;
        struct compound_statement *cs;
        struct expression_statement *es;
        struct selection_statement *ss;
        struct iteration_statement *is;
        struct jump_statement *js;
    } me;
};

struct statement_list {
    struct statement* st;
    struct statement_list *prev;
};

// top-levels

struct external_declaration {
    enum external_declaration_subtype { ED_FUNC_DEF, ED_DECL } type;
    union {
        struct function_definition *func;
        struct declaration *decl;
    } me;
};

struct translation_unit {
    struct external_declaration *right;
    struct translation_unit *left;
};

struct function_definition {
    struct declaration_specifiers *decl_spec;
    struct declarator *decl;
    struct declaration_list *decl_list;
    struct compound_statement *stat;
};

