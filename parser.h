#ifndef PARSER_H_D0BAB84A620FF56F821864BE64C127E0
#define PARSER_H_D0BAB84A620FF56F821864BE64C127E0

#include "ast.h"
#include "debug.h"
#include "parser_internal.h"
#include "hash_table.h"

/// @todo define appropriately
typedef struct parser_state_s {
    hash_table_t *globals;
} parser_state_t;

void parser_setup(parser_state_t *ps);
void parser_teardown(parser_state_t *ps);

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

