/**
 * @file
 * tpp is the C preprocessor in the Toycen C compiler suite.
 *
 * If arguments are provided, takes then as filenames to process; otherwise,
 * takes input on stdin. In either case, produces a single stream of
 * concatenated output on stdout. The filename "-" is taken to mean standard
 * input (so that standard input can be interleaved with other files);
 */

#ifndef MIN
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif

#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include "hash_table.h"
#include "debug.h"

static hash_table_t *defines;
static FILE *instream, *outstream;

static inline void output(const char *line)
{
    fputs(line, outstream);
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
        if (ellipse)
            strcpy(&buf[sizeof buf - 4], "...");
        _debug(1, "%s on line '%s'", __func__, buf);
    }
#endif


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
