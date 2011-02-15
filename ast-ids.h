#ifndef AST_IDS_H_
#define AST_IDS_H_

#include "ast-ids-pre.h"
enum node_type {
	#include "ast.xi"
};
#include "ast-ids-post.h"

extern const char *node_type_names[];

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

