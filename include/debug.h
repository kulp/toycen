#ifndef DEBUG_H_F828480A004155BCAD874C168AB38287
#define DEBUG_H_F828480A004155BCAD874C168AB38287

#if defined(DEBUG) && DEBUG > 0
#include <stdio.h>
extern FILE *DEBUG_FILE;
#define _debug(n,...) \
    ( \
		(n <= DEBUG && DEBUG_FILE) ? \
            (fprintf(DEBUG_FILE, __VA_ARGS__), \
            putc('\n', DEBUG_FILE), \
            (void)0) \
        : (void)0 \
      )
#else
#define _debug(...) (void)0
#endif

#define _error(...) \
    do { \
		fprintf(stderr, __VA_ARGS__); \
		fprintf(stderr, "\n"); \
	} while (0)

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
