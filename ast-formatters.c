#include "ast-ids.h"

#include <stdio.h>
#include <string.h>
#include <stddef.h>
#include <errno.h>

struct type_formatter {
    enum meta_type meta;
    unsigned type;
    int (*format)(struct type_formatter *fmt, int *size, char buf[*size], void *data);
};

int _format_BASIC(struct type_formatter *fmt, int *size, char buf[*size], void *data)
{
    if (fmt->meta != META_IS_BASIC ||
        fmt->type >= BASIC_TYPE_max ||
        size == NULL ||
        *size <= 0)
    {
        errno = EINVAL;
        return -1;
    }

    int need = -1;

    char temp[*size + 2];
    #define R_(Type,Fmt,Expr) case BASIC_TYPE_##Type: PRINT(Type,Fmt,Expr); break;
    #define P_(Expr) Expr
    #define DATA(Type) (*(Type*)data)
    #define PRINT(Type,Fmt,Expr) \
        need = snprintf(temp, sizeof temp, Fmt, Expr)
    switch (fmt->type) {
        #include "basic-types-printf.xi"
        default:
            errno = EFAULT;
            return -1;
    }
    #undef DATA
    #undef PRINT
    #undef P_
    #undef R_

    if (need >= *size)
        *size = -1;
    else
        memcpy(buf, temp, *size = need + 1);

    return 0;
}

const struct type_formatter *type_formatters[] = {
    [META_IS_BASIC] = (struct type_formatter[]) {
        #define R_(Type,...) [BASIC_TYPE_##Type] = { .meta = META_IS_BASIC, \
                                                     .type = BASIC_TYPE_##Type, \
                                                     .format = _format_BASIC },
        #include "basic-types-printf.xi"
        #undef R_
    },
};

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
