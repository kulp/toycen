#ifndef PARSER_H_
#define PARSER_H_

#include "ast.h"
#include "debug.h"
#include "parser_gen.h"
#include "hash_table.h"

#define LINE_LEN 512

/// @todo define appropriately
struct parser_state {
    struct translation_unit *top;
    hash_table_t types_hash;
    /// temporary pointer for debugging output in NN(...)
    // XXX this may break reentrancy a bit ?
    void *_tptr;

    void *bufstate;

    hash_table_t globals;
    struct {
        hash_table_t strings;
    } constants;

    void *scanner;
    struct {
        unsigned savecol;
        char saveline[LINE_LEN];
    } lexstate;
};

#define DEFAULT_SYMBOL_TABLE_SIZE       1024
#define DEFAULT_CONSTANTS_TABLE_SIZE    1024

int toycen_error(YYLTYPE *locp, struct parser_state *ps, const char *s);

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

