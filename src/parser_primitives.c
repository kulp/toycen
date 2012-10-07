#include "parser_primitives.h"
#include "ast-ids-priv.h"

#include <assert.h>

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
    memmove((char*)old + off, (char*)data + off, size - off);

    return old;
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

void node_free(void *node, int recurse);
void priv_free(void *priv, int recurse);
static void node_or_priv_free(void *what, int _type, int priv, int freeself, int recurse);

static void item_free(void *childaddr, const struct node_item *item)
{
    // TODO move this choice type somewhere common
    struct { int idx; union { alignment_type alignment_dummy_; } choice; } *choice = childaddr;

    int type = NODE_TYPE_INVALID;
    void *what = *(void**)childaddr;
    switch (item->meta) {
        case META_IS_PRIV:
            what = childaddr; // privs have less indirection (whence cometh this ?)
            type = item->c.priv->type; /* FALLTHROUGH */
        case META_IS_NODE:
            node_or_priv_free(what, type, item->meta == META_IS_PRIV, item->is_pointer, 1);
            break;
        case META_IS_CHOICE:
            item_free((void*)&choice->choice, &item->c.choice[choice->idx - 1]);
            break;
        default:
            // Other options are META_IS_ID, which cannot be recursed
            // upon, and META_IS_CHOICE, which might have a freeable
            // string, but that is interned and freed another way.
            // TODO reduce the interned string's refcount
            break;
    }
}

static void node_or_priv_free(void *what, int _type, int priv, int freeself, int recurse)
{
    if (!what)
        return;

    if (recurse) {
        // If _type is nonzero (i.e., if it is valid), use that type ;
        // otherwise discover
        int type = _type ? _type : ((struct node *)what)->node_type;
        const struct node_parentage *anc = priv ? NULL : &node_parentages[type];
        const struct node_rec *recs = priv ? priv_recs : node_recs,
                              *rec  = &recs[type];

        debug(3, "freeing %s '%s' at %p", priv ? "priv" : "node", rec->name, what);

        if (!priv && anc->base != NODE_TYPE_node)
            node_or_priv_free(what, anc->base, priv, 0, recurse);

        size_t offset = 0;
        const struct node_item *item = &rec->items[offset];
        while (item->meta != META_IS_INVALID) {
            void *childaddr = (((char*) what) + (*rec->offp)[offset]);
            item_free(childaddr, item);
            item = &rec->items[++offset];
        }
    }

    if (freeself)
        my_free(what);
}

// TODO remove this entry point if not needed
void priv_free(void *priv, int recurse)
{
    node_or_priv_free(priv, PRIV_TYPE_INVALID, 1, 1, recurse);
}

void node_free(void *node, int recurse)
{
    node_or_priv_free(node, NODE_TYPE_INVALID, 0, 1, recurse);
}

/// @tod support overlapping string constants
struct string* intern_string(struct parser_state *ps, const char *str)
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
            struct character *p = &result->value[i];
            p->has_signage = false;
            p->is_signed= false;
            CHOICE_REF(&p->me,c) = str[i];
        }
        hash_table_put(ps->constants.strings, str, result);
    }

    assert(result != NULL);
    return result;
}
