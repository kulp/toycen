/**
 * @file
 * Hashtable interface.
 */

#ifndef HASH_TABLE_H_E42199ACD89556523F1728BB1503FC38
#define HASH_TABLE_H_E42199ACD89556523F1728BB1503FC38

/*
 * Forward declaration of hash table struct which is not defined in the
 * interface file prevents easy inspection and modification of structure
 * members (aids encapsulation).
 */

struct hash_table_s;
typedef struct hash_table_s* hash_table_t;

int     hash_table_create(hash_table_t *table, unsigned int initial_size);
void*   hash_table_get(hash_table_t table, const char *key);
int     hash_table_put(hash_table_t table, const char *key, const void *val);
void*   hash_table_delete(hash_table_t table, const char *key);
int     hash_table_destroy(hash_table_t table);

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
