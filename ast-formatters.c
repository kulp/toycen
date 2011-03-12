#include "ast-ids.h"
#include "ast-pre.h"

#include "ast-ids-priv.h"

#include "ast-formatters-priv.h"

#include "util.h"

#include <stdio.h>
#include <string.h>
#include <stddef.h>
#include <errno.h>

#define MAKE(Sc,Key,...)        MAKE_##Sc(Key,__VA_ARGS__)

static int _format_BASIC(const struct type_formatter *fmt, int *size, char buf[*size], void *data)
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

static int _format_ID(const struct type_formatter *fmt, int *size, char buf[*size], void *data)
{
    if (fmt->meta != META_IS_ID ||
        fmt->type >= ID_TYPE_max ||
        size == NULL ||
        *size <= 0)
    {
        errno = EINVAL;
        return -1;
    }

    int need = -1;
    int idx = **(int**)data;

    char temp[*size + 2];
    #define PRINT(Type,Fmt,Expr) \
        need = snprintf(temp, sizeof temp, Fmt, Expr)
    switch (fmt->type) {
        #define MAKE_ID(Key,...) \
            case ID_TYPE_##Key: PRINT(Key,"%s",id_recs[ID_TYPE_##Key].values[idx].name); break;
        #define MAKE_PRIV(...)
        #define MAKE_NODE(Key,...)

        MAKE_ID(node_type,...)
        #include "ast.xi"

        #undef MAKE_ID
        #undef MAKE_PRIV
        #undef MAKE_NODE
        default:
            errno = EFAULT;
            return -1;
    }
    #undef PRINT

    if (need >= *size)
        *size = -1;
    else
        memcpy(buf, temp, *size = need + 1);

    return 0;
}

int fmt_call(enum meta_type meta, int type, int *size, char buf[*size], void *data)
{
    if (meta >= BASIC_TYPE_max || meta == META_IS_INVALID) {
        errno = EINVAL;
        return -1;
    }

    const struct type_formatter *formatter = &type_formatters[meta][type];
    return formatter->format(formatter, size, buf, data);
}

const struct type_formatter *type_formatters[] = {
    [META_IS_BASIC] = (struct type_formatter[]){
        #define R_(Type,...) [BASIC_TYPE_##Type] = { .meta = META_IS_BASIC, \
                                                     .type = BASIC_TYPE_##Type, \
                                                     .format = _format_BASIC },
        #include "basic-types-printf.xi"
        #undef R_
    },
    [META_IS_ID] = (struct type_formatter[]){
        #define MAKE_ID(Key,...) [ID_TYPE_##Key] = { .meta = META_IS_ID, \
                                                     .type = ID_TYPE_##Key, \
                                                     .format = _format_ID },
        #define MAKE_PRIV(...)
        #define MAKE_NODE(Key,...)

        MAKE_ID(node_type,...)
        #include "ast.xi"

        #undef MAKE_ID
        #undef MAKE_PRIV
        #undef MAKE_NODE

        #undef R_
    }
};

#undef MAKE

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
