/**
 * @file
 * Hashtable implementation.
 *
 * Very naive implementation for starters.
 */

#include <string.h>
#include <stdlib.h>
#include <errno.h>

#include "debug.h"
#include "hash_table.h"

#define DEFAULT_HASH_POWER 9

typedef struct bucket_s bucket_t;

struct bucket_s {
    enum { NODE, HEAD } type;
    char *key;
    const void *val;
    bucket_t *next;     ///< next node in a bucket
};

struct hash_table_s {
    unsigned int size;  ///< the total size of the hash
    unsigned int full;  ///< the number of elements stored
    bucket_t **bkts;
};

/// This is a very naive hashing function
static inline unsigned int hash(const char *str)
{
    unsigned int result = 0;

    int len = strlen(str);
    result += len;
    if (len > 4) len = 4;
    for (int i = 0; i < len; i++)
        result += (unsigned int)str[i] << i;

    return result;
}

static bucket_t* bucket_top(bucket_t **bkts, int index)
{
    if (!bkts[index]) {
        bkts[index] = malloc(sizeof *bkts[index]);
        bkts[index]->type = HEAD;
    }

    return bkts[index];
}

static int bucket_put(bucket_t **bkts, int size, char *duped, const void *val)
{
    unsigned int index = hash(duped) % size;

    bucket_t *here = bucket_top(bkts, index);
    while (here->next) here = here->next;
    here->next = malloc(sizeof *here->next);
    here = here->next;

    here->type  = NODE;
    here->key   = duped;
    here->val   = val;
    here->next  = NULL;

    return 0;
}

static int hash_table_resize(hash_table_t *table, unsigned int newsize)
{
    int rc = 0;

    if (newsize < table->full)
        return -EINVAL;

    bucket_t **old_buckets = table->bkts;
    bucket_t **new_buckets = calloc(newsize, sizeof *new_buckets);

    bucket_t *here = bucket_top(old_buckets, 0);
    bucket_t *temp;
    int i = 0;
    int index = 0;
    while (i < table->full && index <= table->size) {
        if ((temp = here->next)) {
            i++;
            void *val = hash_table_get(table, temp->key);
            _debug(1, "fetching key '%s' with value %p during resize", temp->key, val);
            bucket_put(new_buckets, newsize, temp->key, val);
            here = temp;
        } else {
            here = bucket_top(old_buckets, (++index, index %= table->size));
        }
    }

    table->size = newsize;
    table->bkts = new_buckets;

    free(old_buckets);

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
    table->bkts = calloc(table->size,  sizeof *table->bkts);

    return table;
}

int hash_table_delete(hash_table_t *table, const char *key)
{
    int rc = -1;

    unsigned int index = hash(key) % table->size;

    bucket_t *top  = table->bkts[index];
    bucket_t *here = top;
    bucket_t *last = top;
    if (here) {
        do {
            if (here->type == HEAD) continue;
            if (!strcmp(key, here->key)) {
                last->next = here->next;
                free(here);
                table->full--;
                rc = 0;
                break;
            }
            last = here;
        } while ((here = here->next));
        table->bkts[index] = top;
    }

    return rc;
}

void* hash_table_get(hash_table_t *table, const char *key)
{
    void *result = NULL;

    unsigned int index = hash(key) % table->size;

    bucket_t *here = table->bkts[index];
    if (here) {
        do {
            if (here->type == HEAD) continue;
            if (!strcmp(key, here->key)) {
                // cast away constness, since the external program has
                // the right to do what it wants with its value
                result = (void*)here->val;
                break;
            }
        } while ((here = here->next));
    }

    return result;
}

int hash_table_put(hash_table_t *table, const char *key, const void *val)
{
    int rc = 0;

    if (!key) return -1;

    if (hash_table_get(table, key))
        hash_table_delete(table, key);

    if (table->full + 1 >= table->size) {
        int newsize = table->size;
        while (table->full + 1 >= newsize)
            newsize = (newsize + 1) * 2 - 1;
        hash_table_resize(table, newsize);
    }

    // save key for enumeration purposes
    char *duped = strdup(key);

    bucket_put(table->bkts, table->size, duped, val);

    table->full++;

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
            } while ((b = next));
        }
    }

    free(table->bkts); table->bkts = NULL;

    table->size = 0;
    table->full = 0;

    return rc;
}


/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
