(struct translation_unit){
    .base = /* struct node */ {
        .node_type = NODE_TYPE_translation_unit,
        },
    .right = &(struct external_declaration){
        .base = /* struct node */ {
            .node_type = NODE_TYPE_external_declaration,
            },
        .type = ED_DECL,
        .me = /* union */ { .idx = 0 },
        },
    }
