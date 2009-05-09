#include <stdio.h>
#include <string.h>

#include "hash_table.h"

#define countof(X) (sizeof (X) / sizeof (X)[0])

static const char *toput[] = {
    "hi",  "foo",
    "bye", "bar",
};

static const char *toget[] = {
    "hi",  "foo",
    "bye", "bar",
    "not", NULL,
};

int main()
{
    hash_table_t *ht = hash_table_create(1);

    hash_table_put(ht, "hi",  "foo");
    hash_table_put(ht, "bye", "bar");

    for (int i = 0; i < countof(toget) / 2; i++) {
        char *str = hash_table_get(ht, toget[i * 2]);

        if (str != toget[i * 2 + 1] && strcmp(str, toget[i * 2 + 1]))
            printf("mismatch: hash[%s] = '%s', should have been '%s'\n", toget[i * 2], str, toget[i * 2 + 1]);
    }

    hash_table_destroy(ht);

    return 0;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
