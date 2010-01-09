#include "parser_primitives.h"

#include <assert.h>

static parser_state_t *_ps;

parser_state_t *get_parser_state(void)
{
    return _ps;
}

void set_parser_state(parser_state_t *ps)
{
    _ps = ps;
}

void* _alloc_node(size_t size, void *data)
{
    debug(3, "allocator running with size %ld", size);
    assert(data != NULL);
    void *result = my_calloc(1, size);
    _copy_node(result, data, size, 0);
    return result;
}

/**
 * Copies @c (size - off) bytes from @p data into @p old at position @p off.
 * Used to copy child data into a recently-upgraded parent.
 */
void* _copy_node(void *old, void *data, size_t size, size_t off)
{
    assert(old != NULL);
    assert(data != NULL);
    assert(size >= off);

    /// @todo should / must we use memmove() here ?
    memcpy((char*)old + off, data, size - off);

    return old;
}
 
void parser_setup(parser_state_t *ps)
{
    _debug(2, "%s", __func__);
    assert(ps != NULL);
    memset(ps, 0, sizeof *ps);
    set_parser_state(ps);
    hash_table_create(&ps->globals          , DEFAULT_SYMBOL_TABLE_SIZE);
    hash_table_create(&ps->constants.strings, DEFAULT_CONSTANTS_TABLE_SIZE);

    /// @todo implement
}

void parser_teardown(parser_state_t *ps)
{
    _debug(2, "%s", __func__);
    assert(ps != NULL);
    memset(ps, 0, sizeof *ps);
    set_parser_state(NULL);
    /// @todo implement
}

/// @todo define this elswhere
void debug(int level, const char *fmt, ...)
{
    if (level <= DEBUG_LEVEL && DEBUG_FILE) {
        va_list vl;
        va_start(vl, fmt);
        vfprintf(DEBUG_FILE, fmt, vl);
        putc('\n', DEBUG_FILE);
        va_end(vl);
    }
}

void *my_malloc(size_t size)
{
    void *result = malloc(size);
    debug(5, "%s(%lu) returning %p", __func__, size, result);
    assert(result != NULL);
    return result;
}

void *my_calloc(size_t count, size_t size)
{
    void *result = calloc(count, size);
    debug(5, "%s(%lu,%lu) returning %p", __func__, count, size, result);
    assert(result != NULL);
    return result;
}

void *my_realloc(void *ptr, size_t size)
{
    void *result = realloc(ptr, size);
    debug(5, "%s(%p,%lu) returning %p", __func__, ptr, size, result);
    assert(result != NULL);
    return result;
}

void my_free(void *ptr)
{
    debug(5, "%s(%p)", __func__, ptr);
    free(ptr);
}

/// @tod support overlapping string constants
struct string* intern_string(parser_state_t *ps, const char *str)
{
    assert(ps != NULL);
    assert(str != NULL);
    assert(ps->constants.strings != NULL);

    struct string *result = NULL;
    // look up string in constants table, and add it if it doesn't exist
    /// @todo
    result = hash_table_get(ps->constants.strings, str);
    if (!result) {
        result = my_malloc(sizeof *result);
        size_t len = strlen(str);
        result->cached = my_malloc(len + 1);
        memcpy(result->cached, str, len + 1);
        result->size = len;
        result->value = my_malloc(len * sizeof *result->value);
        for (unsigned i = 0; i < len; i++) {
            result->value[i] = (struct character){
                .has_signage = false,
                .is_signed = false,
                .me.c = str[i],
            };
        }
        hash_table_put(ps->constants.strings, str, result);
    }

    assert(result != NULL);
    return result;
}
