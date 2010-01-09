#ifndef PARSER_H_D0BAB84A620FF56F821864BE64C127E0
#define PARSER_H_D0BAB84A620FF56F821864BE64C127E0

#include "ast.h"
#include "debug.h"
#include "parser_internal.h"
#include "hash_table.h"

/// @todo define appropriately
typedef struct parser_state_s {
    hash_table_t globals;
    struct {
        hash_table_t strings;
    } constants;
} parser_state_t;

void parser_setup(parser_state_t *ps);
void parser_teardown(parser_state_t *ps);

struct translation_unit* get_top_of_parse_result(void);

#define DEFAULT_SYMBOL_TABLE_SIZE       1024
#define DEFAULT_CONSTANTS_TABLE_SIZE    1024

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

