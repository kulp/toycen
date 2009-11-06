#ifndef AST_H
#define AST_H

#include <stddef.h>
#include <stdbool.h>

/// @todo
enum node_type { NT_max };

struct node {
    enum node_type type;
};

enum type_class {
    TC_INVALID, TC_VOID, TC_INT, TC_FLOAT, TC_STRUCT, TC_UNION, TC_max
};

enum primary_expression_type {
    PRET_IDENTIFIER,
    PRET_INTEGER,
    PRET_CHARACTER,
    PRET_FLOATING,
    PRET_STRING,
    PRET_PARENTHESIZED
};

enum expression_type {
    ET_CAST_EXPRESSION,
    ET_MULTIPLICATIVE_EXRESSION,
    ET_max
};

enum unary_operator {
    UO_ADDRESS_OF     = '&',
    UO_DEREFERENCE    = '*',
    UO_PLUS           = '+',
    UO_MINUS          = '-',
    UO_BITWISE_INVERT = '~',
    UO_LOGICAL_INVERT = '!'
};

enum binary_operator {
    BO_max
    /// @todo but what about multi-character operators
};

enum increment_operator {
    IO_INCREMENT,
    IO_DECREMENT
};

struct expression {
    enum expression_type type;
};

struct type_name {
    char *name;
    //struct type *type;  ///< NULL until looked up
};

/// @todo
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
    /// @todo support wchars ?
    size_t size;
    char *value;
};

struct primary_expression {
    enum primary_expression_type type;
    union {
        struct identifier id;
        struct integer i;
        struct character c;
        struct floating f;
        struct string s;
        struct expression *e;
    } me;
};

struct postfix_expression {
    struct primary_expression me;
    enum postfix_expression_type {
        PET_PRIMARY,
        PET_ARRAY_INDEX,
        PET_FUNCTION_CALL,
        PET_AGGREGATE_SELECTION,
        PET_AGGREGATE_PTR_SELECTION,
        PET_POSTINCREMENT
    } type;
    struct postfix_expression *left;
};

struct unary_expression {
    struct postfix_expression me;
    enum unary_expression_type {
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
    struct unary_expression base;
    struct cast_expression *ce;
    struct type_name *tn;
};

struct multiplicative_expression {
    struct cast_expression right;
    struct multiplicative_expression *left; ///< may be NULL
    enum binary_operator bop;               ///< if @c is NULL, nonsensical
};

struct additive_expression {
    struct multiplicative_expression right;
    struct additive_expression *left;       ///< may be NULL
    enum binary_operator bop;               ///< if @c is NULL, nonsensical
};

struct logical_and_expression {
    bool TODO;
};

struct logical_or_expression {
    struct logical_and_expression base;
    struct logical_or_expression *prev;
};

struct conditional_expression {
    struct logical_or_expression base;
    bool is_ternary;
    struct expression *if_expr;
    struct conditional_expression *else_expr;
};

struct constant_expression {
    struct conditional_expression base;
    char dummy; ///< to avoid warnings about empty initializer braces, since there is nothing to initialize
};

struct aggregate_definition {
    bool TODO;
};

struct aggregate_definition_list {
    struct aggregate_definition *me;
    struct aggregate_definition_list *prev;
};

struct aggregate_declaration {
    bool TODO;
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
    /// @todo fields
    struct enumerator *me;
    struct enumerator_list *prev;
};

struct enum_specifier {
    struct node base;
    bool has_id;
    struct identifier *id;
    bool has_list;
    struct enum_list *list;
};

struct type_specifier {
    struct node base;
    enum type_specifier_type {
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

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

