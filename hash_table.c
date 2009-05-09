/**
 * @file
 * Hashtable implementation.
 *
 * Very naive implementation for starters.
 */

#include <string.h>
#include <stdlib.h>
#include <errno.h>

#include "hash_table.h"

#define DEFAULT_HASH_POWER 8

typedef struct bucket_s bucket_t;

struct bucket_s {
    char *key;
    void *val;
    bucket_t *next;
};

struct hash_table_s {
    unsigned int size;
    unsigned int full;
    char **keys;
    bucket_t **bkts;
};

/// This is a very naive hashing function
static inline unsigned int hash(const char *str)
{
    unsigned int result = 0;

    int len = strlen(str);

    result += len;

    for (int i = 0; i < len; i++)
        result += (unsigned int)str[i] << i;

    return result;
}

static int bucket_put(bucket_t **bkts, int size, char *duped, void *val)
{
    int rc = 0;

    unsigned int index = hash(duped) % size;

    bucket_t *top = bkts[index];
    bucket_t *here = top;
    if (!top) {
        top = malloc(sizeof *top);
        top->next = NULL;
        here = top;
    } else {
        while (here->next) here = here->next;
        here->next = malloc(sizeof *here);
        here = here->next;
    }

    here->key = duped;
    here->val = val;

    bkts[index] = top;

    return rc;
}

static int hash_table_resize(hash_table_t *table, unsigned int newsize)
{
    int rc = 0;

    if (newsize < table->full)
        return -EINVAL;

    bucket_t **old_buckets = table->bkts;
    bucket_t **new_buckets = calloc(newsize, sizeof *new_buckets);

    for (int i = 0; i < table->full; i++)
        bucket_put(new_buckets, newsize, table->keys[i], hash_table_get(table, table->keys[i]));

    table->size = newsize;
    table->keys = realloc(table->keys, newsize * sizeof *table->keys);

    return rc;
}

/// @todo pass in a key comparator
hash_table_t* hash_table_create(unsigned int initial_size)
{
    hash_table_t *table;

    table = malloc(sizeof *table);

    if (!initial_size) initial_size = (1 << DEFAULT_HASH_POWER) - 1;

    table->full = 0;
    table->size = initial_size;
    table->keys = malloc(table->size * sizeof *table->keys);
    table->bkts = calloc(table->size,  sizeof *table->bkts);

    return table;
}

void* hash_table_get(hash_table_t *table, const char *key)
{
    void *result = NULL;

    unsigned int index = hash(key) % table->size;

    bucket_t *here = table->bkts[index];
    if (here) {
        do {
            if (!strcmp(key, here->key)) {
                result = here->val;
                break;
            }
        } while ((here = here->next));
    }

    return result;
}

int hash_table_put(hash_table_t *table, const char *key, void *val)
{
    int rc = 0;

    if (table->full + 1 >= table->size)
        hash_table_resize(table, (table->size + 1) * 2 - 1);

    // save key for enumeration purposes
    char *duped = table->keys[table->full++] = strdup(key);

    bucket_put(table->bkts, table->size, duped, val);

    return rc;
}

int hash_table_destroy(hash_table_t *table)
{
    int rc = 0;

    bucket_t *b, *next;
    for (int i = 0; i < table->size; i++) {
        if ((b = table->bkts[i])) {
            do {
                next = b->next;
                free(b);
            } while (next);
        }
    }

    for (int i = 0; i < table->full; i++)
        free(table->keys[i]);

    free(table->keys); table->keys = NULL;
    free(table->bkts); table->bkts = NULL;

    table->size = 0;
    table->full = 0;

    return rc;
}


/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
