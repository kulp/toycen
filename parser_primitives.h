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

/// pointer to anonymous
#define PtA(Type, ...) &(struct Type){ __VA_ARGS__ }

/// size of type
#define SoT(Type) sizeof(struct Type)

/// new node
#define NN(Type, ...) \
    ( (debug(2, "allocating '" #Type "' with { " #__VA_ARGS__ " }")), \
      (_alloc_node(SoT(Type), PtA(Type, __VA_ARGS__))) \
    )

/// child node (descend from existing node)
#define CN(Type, Old, ...) \
    ( (assert(Old != NULL)), \
      (debug(2, "creating '" #Type "' by descent with { " #__VA_ARGS__ " }")), \
      (memcpy(NN(Type, __VA_ARGS__), Old, sizeof *Old)) \
    )

/// upgrade node (descend from existing node, replacing old node)
#define UN(Type, Old, ...) \
    ( (assert(Old != NULL)), \
      (debug(2, "upgrading %p to '" #Type "' with { " #__VA_ARGS__ " }", Old)), \
      (_copy_node(my_realloc(Old, SoT(Type)), PtA(Type, __VA_ARGS__), SoT(Type), sizeof(Old) - SoT(Type))) \
    )

/// @todo real lookup
/// looks up a type name from a string
#define str2type_name(Str) NN(type_name, .name = strdup(Str))

/// free node
#define FN(NODE) my_free(AsPtr(node)NODE)

/// @todo find a better prefix
/// @todo implement a better allocator for such small nodes
#define my_realloc realloc
#define my_calloc calloc
#define my_malloc malloc
#define my_free free

#define AsPtr(Type) (struct Type*)(uintptr_t)
#define Anon(Type,Val) ((struct Type){ Val })

void debug(int level, const char *fmt, ...);

#endif

