/**
 * @file
 * Hashtable interface.
 */

/*
 * Forward declaration of hash table struct which is not defined in the
 * interface file prevents easy inspection and modification of structure
 * members (aids encapsulation).
 */

struct hash_table_s;
typedef struct hash_table_s hash_table_t;

hash_table_t*   hash_table_create(unsigned int initial_size);
void*           hash_table_get(hash_table_t *table, const char *key);
int             hash_table_put(hash_table_t *table, const char *key, void *val);
int             hash_table_destroy(hash_table_t *table);

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
