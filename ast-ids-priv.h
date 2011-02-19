#ifndef AST_IDS_PRIV_H_
#define AST_IDS_PRIV_H_

struct node_rec {
    enum node_type type;
    const char *name;
    size_t * const * const offp; ///< pointer to array due to limitations in preprocessor
    struct node_item *items;
};

struct priv_rec {
    enum priv_type type;
    const char *name;
    size_t * const * const offp; ///< pointer to array due to limitations in preprocessor
    struct node_item *items;
};

struct id_rec {
    enum id_type type;
    const char *name;
};

struct basic_rec {
    enum basic_type type;
    const char *defname;
    /// this is different only for _Bool so far. do we really want it ?
    const char *rawname;
    size_t size;
};

struct node_parentage {
    enum node_type type,
                   base;
    size_t size;
    struct node_parentage *base_ptr; ///< for walking convenience
};

enum meta_type {
    META_IS_INVALID,    ///< also marks end of list
    META_IS_NODE,
    META_IS_ID,
    META_IS_CHOICE,
    META_IS_PRIV,
    META_IS_BASIC,
};

struct node_offset {
    enum node_type type;
    size_t *items;
};

struct priv_offset {
    enum priv_type type;
    size_t *items;
};

struct node_item {
    enum meta_type meta;
    bool is_pointer;
    const char *name;
    // we would like to have here the size for this node, but we don't have the
    // argument passed to the REF_*() macro that would tell us the first
    // argument to offsetof(), so we keep a parallel array in the node_recs[]
    //size_t *offp; ///< pointer due to limitations in preprocessor
    union {
        const struct node_rec *node;
        const struct priv_rec *priv;
        const struct id_rec *id;
        const struct node_item *choice;
        const struct basic_rec *basic;
    } c;
};

extern const struct node_rec node_recs[];
extern const struct priv_rec priv_recs[];
extern const struct id_rec id_recs[];
extern struct node_parentage node_parentages[];
extern const struct basic_rec basic_recs[];

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
