#include "parser_primitives.h"

void* _alloc_node(size_t size, void *data)
{
    debug(3, "allocator running with size %ld", size);
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
    memcpy((char*)old + off, data, size - off);
    return old;
}
 
void parser_setup(parser_state_t *ps)
{
    _debug(2, "%s", __func__);
    *ps = (parser_state_t){ 0 };
    /// @todo implement
}

void parser_teardown(parser_state_t *ps)
{
    _debug(2, "%s", __func__);
    *ps = (parser_state_t){ 0 };
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

