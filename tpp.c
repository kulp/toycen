/**
 * @file
 * tpp is the C preprocessor in the Toycen C compiler suite.
 *
 * Expects (besides options) exactly two arguments, infile and outfile, either
 * of which may be "-" to represent stdin or stdout, respectively.
 */

#include <ctype.h>
#include <getopt.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "hash_table.h"
#include "debug.h"
#include "pp_lexer.h"

//------------------------------------------------------------------------------
// Global declarations
//------------------------------------------------------------------------------

static hash_table_t *defines;
static FILE *instream;
FILE *outstream;

/// @todo remove if its use no longer exists
static const char * const keywords[] = {
     [K_DEFINE ] = "define", [K_UNDEF ] = "undef",
     [K_IFDEF  ] = "ifdef",  [K_IFNDEF] = "ifndef",
     [K_IF     ] = "if",     [K_ELSE  ] = "else",   [K_ELIF] = "elif", [K_ENDIF] = "endif",
     [K_INCLUDE] = "include",
};

//------------------------------------------------------------------------------
// Function definitions
//------------------------------------------------------------------------------

extern inline void output(const char *line)
{
    fputs(line, outstream);
}

void usage(const char *me)
{
    printf("Usage:\n"
           "  %s infile outfile\n"
           "\n", me);
}

int main(int argc, char *argv[])
{
    int result;

    outstream = stdout;

    defines = hash_table_create(0);

    /// @todo use getopt_long()
    if (argc == 3) {
        if (!strcmp(argv[2], "-")) {
            outstream = stdout;
        } else {
            outstream = fopen(argv[2], "w");
            if (!outstream) {
                perror("fopen");
                fprintf(stderr, "failing filename was '%s'\n", argv[2]);
            }
        }

        int rc = switch_to_input_file(argv[1]);
        if (rc) return rc;
    } else {
        fprintf(stderr, "You must supply an 'infile' and an 'outfile' argument.");
        usage(argv[0]);
        result = -1;
    }

    int a;
    do a = yylex(); while (a);

    hash_table_destroy(defines);

    return result;
}

//--------------------------------------------------------------------------------
void add_define(const char *key, const char *val)
{
    _debug(3, "'%s' = '%s'", key, val);
    /// @todo warn / error on redefinition
    /// @todo watch for memory leaks from this strdup()
    hash_table_put(defines, key, strdup(val));
}

void* get_define(const char *key)
{
    void *val = hash_table_get(defines, key);
    _debug(3, "'%s' = %p", key, val);
    return val;
}

void del_define(const char *key)
{
    void *val = hash_table_delete(defines, key);
    _debug(3, "'%s' = %p", key, val);
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
