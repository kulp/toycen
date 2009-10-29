#ifndef AST_H
#define AST_H

#include <stddef.h>
#include <stdbool.h>

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

enum expression_type { ET_CAST_EXPRESSION, ET_MULTIPLICATIVE_EXRESSION };

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
    char *name;
};

struct integer {
    size_t size;
    bool is_signed;
    union {
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

struct character{
    size_t size;
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
        UET_UNARY_OP,
        UET_SIZEOF_EXPR,
        UET_SIZEOF_TYPE
    } type;
    union {
        struct unary_expression *ue;
        struct cast_expression *ce;
        struct type_name *tn;
    } val;
};

struct cast_expression {
    struct unary_expression base;
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

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

