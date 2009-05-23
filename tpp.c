/**
 * @file
 * tpp is the C preprocessor in the Toycen C compiler suite.
 *
 * If arguments are provided, takes then as filenames to process; otherwise,
 * takes input on stdin. In either case, produces a single stream of
 * concatenated output on stdout. The filename "-" is taken to mean standard
 * input (so that standard input can be interleaved with other files);
 */

#include <ctype.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include "hash_table.h"
#include "debug.h"

typedef enum keyword {
    K_DEFINE, K_UNDEF, K_IF, K_IFDEF, K_IFNDEF, K_ELSE, K_ENDIF, K_INCLUDE
} keyword_t;

static hash_table_t *defines;
static FILE *instream, *outstream;

static const char * const keywords[] = {
     [K_DEFINE ] = "define", [K_UNDEF ] = "undef",
     [K_IFDEF  ] = "ifdef",  [K_IFNDEF] = "ifndef",
     [K_IF     ] = "if",     [K_ELSE  ] = "else",   [K_ENDIF] = "endif",
     [K_INCLUDE] = "include",
};

static inline void output(const char *line)
{
    fputs(line, outstream);
}

/// state machine that finds the keyword
static keyword_t check_keyword(int len, const char *str)
{
/// @todo check that the isspace() part is correct
/// @todo potential optimization : check only unchecked remainder
#define _IS(what,exp) ((!strncmp(what, keywords[exp], (temp = strlen(keywords[exp]))) && isspace(*(what + temp)) ? exp : -1))
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
        static char buf[50];
        bool ellipse = false;
        if (len > sizeof buf) {
            len = sizeof buf - 3;
            ellipse = true;
        }
        snprintf(buf, len, "%s", line);
        strncpy(buf, line, len - 1);
        if (ellipse)
            strcpy(&buf[sizeof buf - 4], "...");
        _debug(1, "%s on line '%s'", __func__, buf);
    }
#endif

    if (len > 0) {
        char *ptr = line;
#ifndef STRICT
        while (isspace(*ptr) && ptr - line < len) ptr++;
        if (ptr - line > len) return -1;
#endif
        if (ptr[0] == '#') {
            while (++ptr - line < len && isspace(*ptr)) ;
            keyword_t keyword = check_keyword(len - (ptr - line), ptr);
            /// @todo main dispatch
            if (keyword != -1) {
                _debug(3, "keyword found : '%s'", keywords[keyword]);
                switch (keyword) {
                case K_DEFINE:
                case K_UNDEF:
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

int main(int argc, char *argv[])
{
    int result;

    outstream = stdout;

    if (argc > 1) {
        for (int i = 1; i < argc; i++) {
            if (!strcmp(argv[i], "-")) {
                instream = stdin;
                dispatch_stream(instream);
            } else {
                dispatch_file(argv[i]);
            }
        }
    } else {
        instream = stdin;
        dispatch_stream(instream);
    }

    return result;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
