#include <stdio.h>
#include <string.h>

#include "hash_table.h"

#define countof(X) (sizeof (X) / sizeof (X)[0])

FILE *DEBUG_FILE = NULL;

static const char *toput[] = {
    "hi",  "foo",
    "bye", "bar",
    "hi",  "moo",
    "not", NULL,
    NULL,  NULL,
};

static const char *toget[] = {
    "hi",  "foo",
    "bye", "bar",
    "hi",  "moo",
    "not", NULL,
    "oth", NULL,
};


static const char *atlast[] = {
    "bye", "bar",
    "hi",  "moo",
    "not", NULL,
    "oth", NULL,
};

int main()
{
	DEBUG_FILE = stderr;

    hash_table_t ht;
    hash_table_create(&ht, 1);

    for (unsigned i = 0; i < countof(toput); i += 2) {
        hash_table_put(ht, toput[i], toput[i + 1]);
        char *str1 = hash_table_get(ht, toget[i]);
        char *str2 = hash_table_get(ht, toget[i]);

        if (str1 != str2)
            printf("mismatch: first retrieval '%s' != second retrieval '%s'\n", str1, str2);

        if (str1 != toget[i + 1] && strcmp(str1, toget[i + 1]))
            printf("mismatch: hash[%s] = '%s', should have been '%s'\n", toget[i], str1, toget[i + 1]);
    }

    for (unsigned i = 0; i < countof(atlast); i += 2) {
        char *str = hash_table_get(ht, atlast[i]);
        if (str != atlast[i + 1] && (str == NULL || strcmp(str, atlast[i + 1])))
            printf("mismatch: hash[%s] = '%s', should have been '%s'\n", atlast[i], str, atlast[i + 1]);
    }

    printf("done\n");

    hash_table_destroy(ht);

    return 0;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
