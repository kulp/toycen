#ifndef AST_IDS_PRIV_H_
#define AST_IDS_PRIV_H_

struct node_parentage {
    enum node_type type,
                   base;
    size_t size;
    struct node_parentage *base_ptr; ///< for walking convenience
};

struct node_offset {
    enum node_type type;
    size_t *items;
};

struct priv_offset {
    enum priv_type type;
    size_t *items;
};

extern const struct node_rec node_recs[];
extern const struct priv_rec priv_recs[];
extern const struct id_rec id_recs[];
extern struct node_parentage node_parentages[];
extern const struct basic_rec basic_recs[];

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */

