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

enum basic_type {
	#define R_(X) BASIC_TYPE_##X,
	#include "basic-types.xi"
	#undef R_
};

struct id_rec {
	enum id_type type;
	const char *name;
};

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
		//enum node_type node_type;
		const struct node_rec *node;
		//enum id_type id_type;
		const struct id_rec *id;
		struct node_item *choice;
	} c;
};

struct node_rec {
	enum node_type type;
	const char *name;
	struct node_item *items;
};

#if EXPOSE
extern const struct node_rec node_recs[];
extern const struct id_rec id_recs[];
extern struct node_parentage node_parentages[];
#endif

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

