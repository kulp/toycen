/*
 * Copyright (c) 1997 Sandro Sigala <ssigala@globalnet.it>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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

extern int yylex();
extern void yyerror(const char *s);
void* _alloc_node(size_t size, void *data);
/// copies data into old at offset
void* _copy_node(void *old, void *data, size_t size, size_t off);

/// size of type
#define SoT(Type) sizeof(struct Type)

/// temporary pointer for debugging output in NN(...)
extern void *_tptr;

/// new node
#define NN(Type, ...) \
    ( (_tptr = (struct Type*)_alloc_node(SoT(Type), PAnon(Type, __VA_ARGS__)), \
      (debug(2, "allocating %p as %-25s with " #__VA_ARGS__, _tptr, #Type)), \
	  (((struct node*)_tptr)->node_type = NODE_TYPE_##Type), \
      _tptr) \
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
      (debug(2, "upgrading  %p to %-25s with " #__VA_ARGS__, Old, #Type)), \
      (_tptr = (struct Type*)_copy_node(my_realloc(Old, SoT(Type)), PAnon(Type, __VA_ARGS__), SoT(Type), sizeof *Old)), \
	  (((struct node*)_tptr)->node_type = NODE_TYPE_##Type), \
	  (_tptr) \
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

void debug(int level, const char *fmt, ...);

parser_state_t *get_parser_state(void);
void set_parser_state(parser_state_t *ps);

struct string* intern_string(parser_state_t *ps, const char *str);

#endif

