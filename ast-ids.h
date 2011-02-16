#ifndef AST_IDS_H_
#define AST_IDS_H_

#include "ast-nodes-pre.h"
enum node_type {
    #include "ast.xi"
};
#include "ast-nodes-post.h"

#include "ast-privs-pre.h"
enum priv_type {
    #include "ast.xi"
};
#include "ast-privs-post.h"

#include "ast-ids-pre.h"
enum id_type {
    ID_TYPE_node_type,
    #include "ast.xi"
};
#include "ast-ids-post.h"

enum basic_type {
    #define R_(X) BASIC_TYPE_##X,
    #include "basic-types.xi"
    #undef R_
};

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

