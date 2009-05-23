#ifndef DEBUG_H_F828480A004155BCAD874C168AB38287
#define DEBUG_H_F828480A004155BCAD874C168AB38287

#if DEBUG
#include <stdio.h>
#define _debug(n,...) \
    do \
		if (n <= DEBUG) { \
			fprintf(stderr, __VA_ARGS__); \
			fprintf(stderr, "\n"); \
		} while (0)
#else
#define _debug(...)
#endif

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
