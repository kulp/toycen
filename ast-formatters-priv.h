#ifndef AST_FORMATTERS_PRIV_H_
#define AST_FORMATTERS_PRIV_H_

#include "ast-formatters.h"

struct type_formatter {
    enum meta_type meta;
    unsigned type;
    int (*format)(const struct type_formatter *fmt, int *size, char buf[*size], void *data);
};

extern const struct type_formatter *type_formatters[];

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */


