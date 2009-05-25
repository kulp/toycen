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

//------------------------------------------------------------------------------
// Type and macro definitions
//------------------------------------------------------------------------------

/// horizontal space characters
#define HSPACE " \t"
/// vertical space characters
#define VSPACE "\n\v"
/// all space characters
#define ASPACE HSPACE VSPACE

typedef enum keyword {
    K_DEFINE, K_UNDEF, K_IF, K_IFDEF, K_IFNDEF, K_ELSE, K_ENDIF, K_INCLUDE
} keyword_t;

//------------------------------------------------------------------------------
// Global declarations
//------------------------------------------------------------------------------

static hash_table_t *defines;
static FILE *instream, *outstream;

/// @todo this needs to be treated as a one in some cases
static const char DEFAULT_DEFINITION[] = "";

static const char * const keywords[] = {
     [K_DEFINE ] = "define", [K_UNDEF ] = "undef",
     [K_IFDEF  ] = "ifdef",  [K_IFNDEF] = "ifndef",
     [K_IF     ] = "if",     [K_ELSE  ] = "else",   [K_ENDIF] = "endif",
     [K_INCLUDE] = "include",
};

//------------------------------------------------------------------------------
// Function definitions
//------------------------------------------------------------------------------

static inline void output(const char *line)
{
    fputs(line, outstream);
}

/// state machine that finds the keyword
static keyword_t check_keyword(int len, const char *str)
{
/// @todo check that the isspace() part is correct
/// @todo potential optimization : check only unchecked remainder
#define _IS(what,exp) \
    (!strncmp(what, keywords[exp], (temp = strlen(keywords[exp]))) \
     && (temp == len || isspace(*(what + temp))) ? exp : -1)

    /// @todo trap len increments so they don't overflow the string
    int idx = 0;
    int temp;   // prevents recomputation of strlen()
    switch (str[idx++]) {
    case 'i':
        switch (str[idx++]) {
        case 'n': return _IS(str, K_INCLUDE);
        case 'f':
            if (_IS(str, K_IF) == K_IF) return K_IF;
            switch (str[idx++]) {
                case 'd' : return _IS(str, K_IFDEF);
                case 'n' : return _IS(str, K_IFNDEF);
                default  : return -1;
            }
        default: return -1;
        }
    case 'e':
        switch (str[idx++]) {
        case 'l': return _IS(str, K_ELSE);
        case 'n': return _IS(str, K_ENDIF);
        default : return -1;
        }
    case 'd': return _IS(str, K_DEFINE);
    case 'u': return _IS(str, K_UNDEF);
    default: return -1;
    }
#undef _IS
}

/// note that line is not null-terminated
static int dispatch_line(int len, char line[len])
{
#if DEBUG
    {
        char buf[50] = { 0 };
        bool ellipse = false;
        if (len > sizeof buf) {
            len = sizeof buf - 3;
            ellipse = true;
        }
        strncpy(buf, line, len - 1);
        if (ellipse)
            strcpy(&buf[sizeof buf - 4], "...");
        _debug(1, "%s on line '%s'", __func__, buf);
    }
#endif

    if (len > 0) {
        if (line[len - 1] == '\n') line[len-- - 1] = 0;  // chomp newline
        char *ptr = line;
#ifndef STRICT
        while (isspace(*ptr) && ptr - line < len) ptr++;
        if (ptr - line > len) return -1;
#endif
        if (ptr[0] == '#') {
            ptr += strspn(ptr + 1, HSPACE) + 1;
            keyword_t keyword = check_keyword(len - (ptr - line), ptr);
            /// main dispatch
            if (keyword != -1) {
                _debug(3, "keyword found : '%s'", keywords[keyword]);
                ptr += strlen(keywords[keyword]);   // skip keyword
                ptr += strspn(ptr, HSPACE);         // skip spaces
                int numthings = 0;
                // thing1 and thing2 are the two potential arguments to a preprocessor directive
                char *thing1, *thing2;
                int len = strcspn(ptr, ASPACE);    // skip spaces
                /// @todo this logic needs sophistication for function-like macros
                if (len) {
                    // extend len if spaces are inside a macro param list
                    char *start_paren, *end_paren;
                    if ((start_paren = strchr(ptr, '(')) && start_paren - ptr < len) {
                        len = strchr(ptr, ')') - ptr + 1;
                        if ((start_paren = strchr(start_paren + 1, '(')) && start_paren < end_paren) {
                            _error("syntax error: '(' may not occur in macro parameters list");
                        }
                    }

                    thing1 = ptr;
                    thing1[len] = 0;
                    numthings++;    // we have a first param
                    /// @todo rewrite this more compactly / elegantly
                    thing2 = thing1 + len + strspn(thing1 + len + 1, HSPACE) + 1;
                    /// @todo properly handle comments inside a macro (?)
                    /// @todo create a proper tokenizing function
                    int len2;
                    if ((len2 = strcspn(thing2, VSPACE))) {
                        thing2[len2] = 0;
                        numthings++;    // have a second param of nonzero length
                    }
                }

                switch (keyword) {
                case K_DEFINE:
                {
                    char *key = strdup(thing1);
                    char *val = (numthings == 2) ? strdup(thing2) : (char*)DEFAULT_DEFINITION;
                    _debug(3, "'%s' = '%s'", key, val);
                    hash_table_put(defines, key, val);
                    break;
                }
                case K_UNDEF:
                {
                    if (numthings) {
                        /// @todo useful messages on syntax error
                        _debug(1, "syntax error");
                    }
                    void *what = hash_table_delete(defines, thing1);
                    if (what != DEFAULT_DEFINITION) free(what);
                    break;
                }
                case K_IF:
                case K_IFDEF:
                case K_IFNDEF:
                case K_ELSE:
                case K_ENDIF:
                case K_INCLUDE:
                    break;
                default:
                    break;
                }
            }
        }
    }

    return 0;
}

static int dispatch_stream(FILE *instream)
{
    _debug(1, "%s on stream %p", __func__, (void*)instream);

    int result = 0;
    size_t len = 0;
    char *line;

    while ((line = fgetln(instream, &len)) && !result)
        result = dispatch_line(len, line);

    return result;
}

static int dispatch_file(const char *filename)
{
    FILE *instream = fopen(filename, "r");
    if (!instream) {
        perror("fopen");
        return -1;
    }

    int result = dispatch_stream(instream);

    fclose(instream);

    return result;
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

    int a = yylex();

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

        if (!strcmp(argv[1], "-")) {
            instream = stdin;
            dispatch_stream(instream);
        } else {
            dispatch_file(argv[1]);
        }
    } else {
        fprintf(stderr, "You must supply an 'infile' and an 'outfile' argument.");
        usage(argv[0]);
        result = -1;
    }

    hash_table_destroy(defines);

    return result;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
