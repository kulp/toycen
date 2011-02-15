#ifndef AST_IDS_H_
#define AST_IDS_H_

#include "ast-nodes-pre.h"
enum node_type {
	#include "ast.xi"
};
#include "ast-nodes-post.h"

#include "ast-ids-pre.h"
enum id_type {
	ID_TYPE_node_type,
	#include "ast.xi"
};
#include "ast-ids-post.h"

struct node_parentage {
	enum node_type type,
				   base;
	size_t size;
	struct node_parentage *base_ptr; ///< for walking convenience
};

enum meta_type {
	META_IS_INVALID,	///< also marks end of list
	META_IS_NODE,
	META_IS_ID,
	META_IS_CHOICE,
	META_IS_PRIV,
	META_IS_BASIC,
};

struct node_item {
	enum meta_type meta;
	bool is_pointer;
	const char *name;
	union {
		enum node_type node_type;
		enum id_type id_type;
		struct node_item *choice;
	} c;
};

struct node_field {
	enum node_type type;
	struct node_item *items;
};

#if EXPOSE
extern const char *node_type_names[];
extern const char *id_type_names[];
extern struct node_parentage node_parentages[];
#endif

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

