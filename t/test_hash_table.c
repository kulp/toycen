#include <stdio.h>
#include <string.h>

#include "hash_table.h"

#define countof(X) (sizeof (X) / sizeof (X)[0])

static const char *toput[] = {
    "hi",  "foo",
    "bye", "bar",
    "hi",  "moo",
};

static const char *toget[] = {
    "hi",  "moo",
    "bye", "bar",
    "not", NULL,
};

int main()
{
    hash_table_t *ht = hash_table_create(1);

    for (int i = 0; i < countof(toput); i += 2)
        hash_table_put(ht, toput[i], toput[i + 1]);

    for (int i = 0; i < countof(toget); i += 2) {
        char *str = hash_table_get(ht, toget[i]);

        if (str != toget[i + 1] && strcmp(str, toget[i + 1]))
            printf("mismatch: hash[%s] = '%s', should have been '%s'\n", toget[i], str, toget[i + 1]);
    }

    hash_table_destroy(ht);

    return 0;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
