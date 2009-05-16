#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "lexer.h"
#include "hash_table.h"

#define countof(X) (sizeof (X) / sizeof (X)[0])

int main()
{
    hash_table_t *ht = NULL;

    char buf[128];

    while (fgets(buf, sizeof buf, stdin)) {
        int len = strlen(buf);
        if (len <= 0 || buf[0] == '\n') continue;
        char cmd = buf[0];

        switch (cmd) {
        case 'q':
            exit(0);
            break;
        case 'c': {
            char *start = strchr(buf, ' ');
            if (!start) start = &buf[1];
            int size = strtol(start, NULL, 0);
            ht = hash_table_create(size);
            break;
        }
        case 'g': {
            char key[32] = { 0 };
            char *start = strchr(buf, ' ') + 1;
            strncpy(key, start, strlen(start) - 1);
            char *val = hash_table_get(ht, key);
            printf("got key '%s' val => '%s'\n", key, val);
            break;
        }
        case 'p': {
            char *tmp = strchr(buf, ' ') + 1;
            char *val = strchr(tmp, ' ') + 1;
            char key[32] = { 0 };
            strncpy(key, tmp, val - tmp - 1);
            val[strlen(val) - 1] = 0;
            hash_table_put(ht, key, strdup(val));
            printf("put key '%s' => val '%s'\n", key, val);
            break;
        }
        case 'd':
            if (ht) hash_table_destroy(ht), ht = NULL;
            break;
        default:
            break;
        }

    }

    return 0;
}

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
