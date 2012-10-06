#ifndef PARSER_PRIMITIVES_H_
#define PARSER_PRIMITIVES_H_

#include "parser.h"

#include <assert.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

extern int DEBUG_LEVEL;
extern FILE* DEBUG_FILE;

void* _alloc_node(size_t size, void *data);
/// copies data into old at offset
void* _copy_node(void *old, void *data, size_t size, size_t off);

/// size of type
#define SoT(Type) sizeof(struct Type)

/// new node
#define NN(Type, ...) \
    ( (ps->_tptr = (struct Type*)_alloc_node(SoT(Type), PAnon(Type, __VA_ARGS__)), \
      (debug(2, "allocating %p as %-25s with " #__VA_ARGS__, ps->_tptr, #Type)), \
      (((struct node*)ps->_tptr)->node_type = NODE_TYPE_##Type), \
      ps->_tptr) \
    )

/*
/// child node (descend from existing node)
#define CN(Type, Old, ...) \
    ( (assert(Old != NULL)), \
      (debug(2, "creating '" #Type "' by descent with { " #__VA_ARGS__ " }")), \
      ((struct Type*)memcpy(NN(Type, __VA_ARGS__), Old, sizeof *Old)) \
    )
*/

/// upgrade node (descend from existing node, replacing old node)
#define UN(Type, Old, ...) \
    ( (assert(Old != NULL)), \
      (debug(2, "upgrading  %p to %-25s with " #__VA_ARGS__, (void*)Old, #Type)), \
      (ps->_tptr = (struct Type*)_copy_node(my_realloc(Old, SoT(Type)), PAnon(Type, __VA_ARGS__), SoT(Type), sizeof *Old)), \
      (((struct node*)ps->_tptr)->node_type = NODE_TYPE_##Type), \
      (ps->_tptr) \
    )

/// @todo real lookup
/// looks up a type name from a string
#define str2type_name(Str) NN(type_name, .name = strdup(Str))

/// free node
#define FN(NODE) my_free((void*)NODE)

/// @todo find a better prefix
/// @todo implement a better allocator for such small nodes
void *my_realloc(void*, size_t);
void *my_calloc(size_t, size_t);
void *my_malloc(size_t);
void my_free(void*);

#define AsPtr(Type) (struct Type*)(uintptr_t)
#define Anon(Type,...) ((struct Type){ __VA_ARGS__ })
#define PAnon(Type,...) &Anon(Type,__VA_ARGS__)

#define debug(...) _debug(__VA_ARGS__)

struct parser_state *get_parser_state(void);

struct string* intern_string(struct parser_state *ps, const char *str);

// see ast-gen-pre.h's CHOICE(...)
#if INHIBIT_INTROSPECTION
#define CHOICE(Idx,Name,...) { .Name = __VA_ARGS__ }
#define CHOICE_REF(Ptr,Field) ((Ptr)->Field)
#else
// TODO permit Idx to be computed symbolically instead of specified literally
// Idx = 0 means "none"
#define CHOICE(Idx,Name,...) { .idx = (Idx + 1), .choice.Name = __VA_ARGS__ }
#define CHOICE_REF(Ptr,Field) ((Ptr)->choice.Field)
#endif

#endif

