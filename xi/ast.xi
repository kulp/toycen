MAKE(NODE,node,
        DEFITEM(TYPED(REF_ID(node_type),node_type))
    )

MAKE(ID,assignment_operator,
        REFITEM(ENUM_DFL(AO,INVALID))
        REFITEM(ENUM_DFL(AO,MULEQ))
        REFITEM(ENUM_DFL(AO,DIVEQ))
        REFITEM(ENUM_DFL(AO,MODEQ))
        REFITEM(ENUM_DFL(AO,ADDEQ))
        REFITEM(ENUM_DFL(AO,SUBEQ))
        REFITEM(ENUM_DFL(AO,SLEQ))
        REFITEM(ENUM_DFL(AO,SREQ))
        REFITEM(ENUM_DFL(AO,ANDEQ))
        REFITEM(ENUM_DFL(AO,XOREQ))
        REFITEM(ENUM_DFL(AO,OREQ))
        REFITEM(ENUM_VAL(AO,EQ,'='))
    )

MAKE(PRIV,assignment_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(unary_expression)),left))
        DEFITEM(TYPED(REF_ID(assignment_operator),op))
        DEFITEM(TYPED(PTR(REF_NODE(assignment_expression)),right))
    )

MAKE(ID,type_class,
        REFITEM(ENUM_DFL(TC,INVALID))
        REFITEM(ENUM_DFL(TC,VOID))
        REFITEM(ENUM_DFL(TC,INT))
        REFITEM(ENUM_DFL(TC,FLOAT))
        REFITEM(ENUM_DFL(TC,STRUCT))
        REFITEM(ENUM_DFL(TC,UNION))
        REFITEM(ENUM_DFL(TC,max))
    )

MAKE(ID,primary_expression_type,
        REFITEM(ENUM_DFL(PRET,INVALID))
        REFITEM(ENUM_DFL(PRET,IDENTIFIER))
        REFITEM(ENUM_DFL(PRET,INTEGER))
        REFITEM(ENUM_DFL(PRET,CHARACTER))
        REFITEM(ENUM_DFL(PRET,FLOATING))
        REFITEM(ENUM_DFL(PRET,STRING))
        REFITEM(ENUM_DFL(PRET,PARENTHESIZED))
    )

MAKE(ID,expression_type,
        REFITEM(ENUM_DFL(ET,INVALID))
        REFITEM(ENUM_DFL(ET,CAST_EXPRESSION))
        REFITEM(ENUM_DFL(ET,MULTIPLICATIVE_EXRESSION))
        /// @todo fill in the rest
        REFITEM(ENUM_DFL(ET,max))
    )

MAKE(ID,unary_operator,
        REFITEM(ENUM_DFL(UO,INVALID))
        REFITEM(ENUM_VAL(UO,ADDRESS_OF    ,'&'))
        REFITEM(ENUM_VAL(UO,DEREFERENCE   ,'*'))
        REFITEM(ENUM_VAL(UO,PLUS          ,'+'))
        REFITEM(ENUM_VAL(UO,MINUS         ,'-'))
        REFITEM(ENUM_VAL(UO,BITWISE_INVERT,'~'))
        REFITEM(ENUM_VAL(UO,LOGICAL_INVERT,'!'))
        REFITEM(ENUM_DFL(UO,max))
    )

MAKE(ID,binary_operator,
        /// @todo but what about multi-character operators
        REFITEM(ENUM_DFL(BO,INVALID))
        REFITEM(ENUM_VAL(BO,ADD        ,'+'))
        REFITEM(ENUM_VAL(BO,SUBTRACT   ,'-'))
        REFITEM(ENUM_VAL(BO,MULTIPLY   ,'*'))
        REFITEM(ENUM_VAL(BO,DIVIDE     ,'/'))
        REFITEM(ENUM_VAL(BO,MODULUS    ,'%'))
        REFITEM(ENUM_VAL(BO,BITWISE_AND,'&'))
        REFITEM(ENUM_DFL(BO,max))
    )

MAKE(ID,increment_operator,
        REFITEM(ENUM_DFL(IO,INCREMENT))
        REFITEM(ENUM_DFL(IO,DECREMENT))
    )

MAKE(NODE,assignment_expression,
        BASE(node)
        DEFITEM(TYPED(BASIC(bool),has_op))
        DEFITEM(CHOICE(c,
            DEFITEM(TYPED(PTR(REF_NODE(conditional_expression)),right))
            DEFITEM(TYPED(REF_PRIV(assignment_inner_),assn))
        ))
    )

MAKE(NODE,expression,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(assignment_expression)),right))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),left))
    )

MAKE(ID,sq_meta,
        REFITEM(ENUM_DFL(SQ,HAS_TYPE_SPEC))
        REFITEM(ENUM_DFL(SQ,HAS_TYPE_QUAL))
    )

MAKE(NODE,specifier_qualifier_list,
        BASE(node)
        DEFITEM(TYPED(REF_ID(sq_meta),type))
        DEFITEM(TYPED(PTR(REF_NODE(specifier_qualifier_list)),next))
    )

MAKE(ID,type_qualifier,
        REFITEM(ENUM_DFL(TQ,INVALID))
        REFITEM(ENUM_DFL(TQ,CONST))
        REFITEM(ENUM_DFL(TQ,VOLATILE))
    )

MAKE(NODE,type_qualifier_list,
        BASE(node)
        DEFITEM(TYPED(REF_ID(type_qualifier),me))
        DEFITEM(TYPED(PTR(REF_NODE(type_qualifier_list)),left))
    )

MAKE(NODE,pointer,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(type_qualifier_list)),tq))
        DEFITEM(TYPED(PTR(REF_NODE(pointer)),right))
    )

MAKE(ID,direct_abstract_declarator_subtype,
        REFITEM(ENUM_DFL(DA,INVALID))
        REFITEM(ENUM_DFL(DA,PARENTHESIZED))
        REFITEM(ENUM_DFL(DA,ARRAY_INDEX))
        REFITEM(ENUM_DFL(DA,FUNCTION_CALL))
    )

MAKE(PRIV,array_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(direct_abstract_declarator)),left))
        DEFITEM(TYPED(PTR(REF_NODE(constant_expression)),idx))
    )

MAKE(PRIV,func_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(direct_abstract_declarator)),left))
        DEFITEM(TYPED(PTR(REF_NODE(parameter_type_list)),params))
    )

MAKE(NODE,direct_abstract_declarator,
        BASE(node)
        DEFITEM(TYPED(REF_ID(direct_abstract_declarator_subtype),type))
        DEFITEM(CHOICE(me,
            DEFITEM(TYPED(PTR(REF_NODE(abstract_declarator)),abs))
            DEFITEM(TYPED(REF_PRIV(array_inner_),array))
            DEFITEM(TYPED(REF_PRIV(func_inner_),function))
        ))
    )

MAKE(NODE,abstract_declarator,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(pointer)),ptr))
        DEFITEM(TYPED(PTR(REF_NODE(direct_abstract_declarator)),right))
    )

MAKE(NODE,type_name,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(specifier_qualifier_list)),list))
        DEFITEM(TYPED(PTR(REF_NODE(abstract_declarator)),decl))
    )

MAKE(NODE,identifier,
        BASE(node)
        DEFITEM(TYPED(BASIC(size_t  ),len ))
        DEFITEM(TYPED(BASIC(char_ptr),name))
    )

MAKE(NODE,integer,
        BASE(node)
        DEFITEM(TYPED(BASIC(size_t),size     ))
        DEFITEM(TYPED(BASIC(bool  ),is_signed))
        DEFITEM(CHOICE(me,
            DEFITEM(TYPED(BASIC(short             ),s  ))
            DEFITEM(TYPED(BASIC(int               ),i  ))
            DEFITEM(TYPED(BASIC(long              ),l  ))
            DEFITEM(TYPED(BASIC(long_long         ),ll ))
            DEFITEM(TYPED(BASIC(signed_short      ),ss ))
            DEFITEM(TYPED(BASIC(signed_int        ),si ))
            DEFITEM(TYPED(BASIC(signed_long       ),sl ))
            DEFITEM(TYPED(BASIC(signed_long_long  ),sll))
            DEFITEM(TYPED(BASIC(unsigned_short    ),us ))
            DEFITEM(TYPED(BASIC(unsigned_int      ),ui ))
            DEFITEM(TYPED(BASIC(unsigned_long     ),ul ))
            DEFITEM(TYPED(BASIC(unsigned_long_long),ull))
        ))
    )

MAKE(NODE,character,
        BASE(node)
        /// @todo support wchars ?
        //size_t size;
        DEFITEM(TYPED(BASIC(bool),has_signage))
        DEFITEM(TYPED(BASIC(bool),is_signed))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(BASIC(char         ),c ))
                DEFITEM(TYPED(BASIC(signed_char  ),lc))
                DEFITEM(TYPED(BASIC(unsigned_char),uc))
            ))
    )

MAKE(NODE,floating,
        BASE(node)
        DEFITEM(TYPED(BASIC(size_t),size))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(BASIC(float),f))
                DEFITEM(TYPED(BASIC(double),d))
                DEFITEM(TYPED(BASIC(long_double),ld))
            ))
    )

MAKE(NODE,string,
        BASE(node)
        DEFITEM(TYPED(BASIC(size_t),size))
        DEFITEM(TYPED(PTR(REF_NODE(character)),value))
        DEFITEM(TYPED(PTR(BASIC(char)),cached))
    )

// was expression_having_type_ but I reserved trailing _ for PRIV
MAKE(NODE,expression_having_type,
        BASE(node)
        DEFITEM(TYPED(REF_ID(expression_type),type))
    )

MAKE(NODE,primary_expression,
        BASE(expression_having_type)
        DEFITEM(TYPED(REF_ID(primary_expression_type),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
                DEFITEM(TYPED(PTR(REF_NODE(integer   )),i ))
                DEFITEM(TYPED(PTR(REF_NODE(character )),c ))
                DEFITEM(TYPED(PTR(REF_NODE(floating  )),f ))
                DEFITEM(TYPED(PTR(REF_NODE(string    )),s ))
                DEFITEM(TYPED(PTR(REF_NODE(expression)),e ))
            ))
    )

MAKE(NODE,argument_expression_list,
        BASE(assignment_expression)
        DEFITEM(TYPED(PTR(REF_NODE(argument_expression_list)),left))
    )

MAKE(ID,postfix_expression_type,
        REFITEM(ENUM_DFL(PET,INVALID))
        REFITEM(ENUM_DFL(PET,PRIMARY))
        REFITEM(ENUM_DFL(PET,ARRAY_INDEX))
        REFITEM(ENUM_DFL(PET,FUNCTION_CALL))
        REFITEM(ENUM_DFL(PET,AGGREGATE_SELECTION))
        REFITEM(ENUM_DFL(PET,AGGREGATE_PTR_SELECTION))
        REFITEM(ENUM_DFL(PET,POSTINCREMENT))
        REFITEM(ENUM_DFL(PET,POSTDECREMENT))
    )

MAKE(PRIV,array_postfix_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(postfix_expression)),left))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),index))
    )

MAKE(PRIV,function_postfix_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(postfix_expression)),left))
        DEFITEM(TYPED(PTR(REF_NODE(argument_expression_list)),ael))
    )
MAKE(PRIV,aggregate_postfix_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(postfix_expression)),left))
        DEFITEM(TYPED(PTR(REF_NODE(identifier)),designator))
    )
MAKE(NODE,postfix_expression,
        BASE(node)
    //struct primary_expression me;
        DEFITEM(TYPED(REF_ID(postfix_expression_type),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(primary_expression)),pri))
                DEFITEM(TYPED(PTR(REF_NODE(postfix_expression)),left))
                DEFITEM(TYPED(REF_PRIV(array_postfix_inner_),array))
                DEFITEM(TYPED(REF_PRIV(function_postfix_inner_),function))
                DEFITEM(TYPED(REF_PRIV(aggregate_postfix_inner_),aggregate))
            ))
        //struct postfix_expression *left;
    )

MAKE(ID,unary_expression_type,
        REFITEM(ENUM_DFL(UET,INVALID))
        REFITEM(ENUM_DFL(UET,POSTFIX))
        REFITEM(ENUM_DFL(UET,PREINCREMENT))
        REFITEM(ENUM_DFL(UET,PREDECREMENT))
        REFITEM(ENUM_DFL(UET,UNARY_OP))
        REFITEM(ENUM_DFL(UET,SIZEOF_EXPR))
        REFITEM(ENUM_DFL(UET,SIZEOF_TYPE))
    )

MAKE(PRIV,ce_unary_inner_,
        DEFITEM(TYPED(REF_ID(unary_operator),uo))
        DEFITEM(TYPED(PTR(REF_NODE(cast_expression)),ce))
    )

MAKE(NODE,unary_expression,
        BASE(postfix_expression)
        DEFITEM(TYPED(REF_ID(unary_expression_type),type))
        DEFITEM(CHOICE(c,
                DEFITEM(TYPED(PTR(REF_NODE(unary_expression)),ue))
                DEFITEM(TYPED(REF_PRIV(ce_unary_inner_),ce))
                DEFITEM(TYPED(PTR(REF_NODE(type_name)),tn))
            ))
    )

MAKE(PRIV,cast_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(cast_expression)),ce))
        DEFITEM(TYPED(PTR(REF_NODE(type_name)),tn))
    )

MAKE(NODE,cast_expression,
        BASE(node)
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(unary_expression)),unary))
                DEFITEM(TYPED(REF_PRIV(cast_inner_),cast))
            ))
    )

MAKE(NODE,multiplicative_expression,
        BASE(cast_expression)
        DEFITEM(TYPED(PTR(REF_NODE(multiplicative_expression)),left)) ///< may be NULL
        DEFITEM(TYPED(REF_ID(binary_operator),op))                ///< if @c is NULL, nonsensical
    )

MAKE(NODE,additive_expression,
        BASE(multiplicative_expression)
        DEFITEM(TYPED(PTR(REF_NODE(additive_expression)),left))       ///< may be NULL
        DEFITEM(TYPED(REF_ID(binary_operator),op))                ///< if @c is NULL, nonsensical
    )

MAKE(ID,shift_operator,
        REFITEM(ENUM_DFL(SO,INVALID))
        REFITEM(ENUM_DFL(SO,LSH))
        REFITEM(ENUM_DFL(SO,RSH))
    )

MAKE(NODE,shift_expression,
        BASE(additive_expression)
        DEFITEM(TYPED(REF_ID(shift_operator),op))
        DEFITEM(TYPED(PTR(REF_NODE(shift_expression)),left))
    )

MAKE(ID,relational_operator,
        REFITEM(ENUM_DFL(RO,INVALID))
        REFITEM(ENUM_DFL(RO,LT))
        REFITEM(ENUM_DFL(RO,GT))
        REFITEM(ENUM_DFL(RO,LTEQ))
        REFITEM(ENUM_DFL(RO,GTEQ))
    )

MAKE(NODE,relational_expression,
        BASE(shift_expression)
        DEFITEM(TYPED(REF_ID(relational_operator),op))
        DEFITEM(TYPED(PTR(REF_NODE(relational_expression)),left))
    )

MAKE(NODE,equality_expression,
        BASE(relational_expression)
        DEFITEM(TYPED(BASIC(bool),eq))
        DEFITEM(TYPED(PTR(REF_NODE(equality_expression)),left))
    )

MAKE(NODE,and_expression,
        BASE(equality_expression)
        DEFITEM(TYPED(PTR(REF_NODE(and_expression)),left))
    )

MAKE(NODE,exclusive_or_expression,
        BASE(and_expression)
        DEFITEM(TYPED(PTR(REF_NODE(exclusive_or_expression)),left))
    )

MAKE(NODE,inclusive_or_expression,
        BASE(exclusive_or_expression)
        DEFITEM(TYPED(PTR(REF_NODE(inclusive_or_expression)),left))
    )

MAKE(NODE,logical_and_expression,
        BASE(inclusive_or_expression)
        DEFITEM(TYPED(PTR(REF_NODE(logical_and_expression)),left))
    )

MAKE(NODE,logical_or_expression,
        BASE(logical_and_expression)
        DEFITEM(TYPED(PTR(REF_NODE(logical_or_expression)),left))
    )

MAKE(NODE,conditional_expression,
        BASE(logical_or_expression)
        DEFITEM(TYPED(BASIC(bool),is_ternary))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),if_expr))
        DEFITEM(TYPED(PTR(REF_NODE(conditional_expression)),else_expr))
    )

MAKE(NODE,constant_expression,
        BASE(conditional_expression)
        DEFITEM(TYPED(BASIC(char),dummy)) ///< to avoid warnings about empty initializer braces, since there is nothing to initialize
    )

MAKE(NODE,aggregate_definition,
        BASE(node)
        DEFITEM(TYPED(BASIC(bool),TODO)) /// @todo
    )

MAKE(NODE,aggregate_definition_list,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_definition)),me))
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_definition_list)),prev))
    )

MAKE(NODE,aggregate_declaration,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(specifier_qualifier_list)),sq))
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_declarator_list)),decl))
    )

MAKE(NODE,aggregate_declaration_list,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_declaration)),me))
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_declaration_list)),prev))
    )

MAKE(ID,aggregate_type,
        REFITEM(ENUM_DFL(AT,UNION))
        REFITEM(ENUM_DFL(AT,STRUCT))
    )

MAKE(NODE,aggregate_specifier,
        BASE(node)
        DEFITEM(TYPED(REF_ID(aggregate_type),type))
        DEFITEM(TYPED(BASIC(bool),has_id))
        DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
        DEFITEM(TYPED(BASIC(bool),has_list))
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_declaration_list)),list))
    )

MAKE(NODE,enumerator,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
        DEFITEM(TYPED(PTR(REF_NODE(constant_expression)),val))
    )

MAKE(NODE,enumerator_list,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(enumerator)),me))
        DEFITEM(TYPED(PTR(REF_NODE(enumerator_list)),prev))
    )

MAKE(NODE,enum_specifier,
        BASE(node)
        DEFITEM(TYPED(BASIC(bool),has_id))
        DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
        DEFITEM(TYPED(BASIC(bool),has_list))
        DEFITEM(TYPED(PTR(REF_NODE(enumerator_list)),list))
    )

MAKE(ID,type_specifier_type,
        REFITEM(ENUM_DFL(TS,INVALID))
        REFITEM(ENUM_DFL(TS,VOID))
        REFITEM(ENUM_DFL(TS,CHAR))
        REFITEM(ENUM_DFL(TS,SHORT))
        REFITEM(ENUM_DFL(TS,INT))
        REFITEM(ENUM_DFL(TS,LONG))
        REFITEM(ENUM_DFL(TS,FLOAT))
        REFITEM(ENUM_DFL(TS,DOUBLE))
        REFITEM(ENUM_DFL(TS,SIGNED))
        REFITEM(ENUM_DFL(TS,UNSIGNED))
        REFITEM(ENUM_DFL(TS,STRUCT_OR_UNION_SPEC))
        REFITEM(ENUM_DFL(TS,ENUM_SPEC))
        REFITEM(ENUM_DFL(TS,TYPEDEF_NAME))
    )

MAKE(NODE,type_specifier,
        BASE(node)
        DEFITEM(TYPED(REF_ID(type_specifier_type),type))
        DEFITEM(CHOICE(c,
                DEFITEM(TYPED(PTR(REF_NODE(aggregate_specifier)),as))
                DEFITEM(TYPED(PTR(REF_NODE(enum_specifier)),es))
                DEFITEM(TYPED(PTR(REF_NODE(type_name)),tn))
            ))
    )

MAKE(ID,storage_class_specifier,
        REFITEM(ENUM_DFL(SCS,INVALID))
        REFITEM(ENUM_DFL(SCS,TYPEDEF))
        REFITEM(ENUM_DFL(SCS,EXTERN))
        REFITEM(ENUM_DFL(SCS,STATIC))
        REFITEM(ENUM_DFL(SCS,AUTO))
        REFITEM(ENUM_DFL(SCS,REGISTER))
    )

MAKE(ID,declaration_specifiers_subtype,
        REFITEM(ENUM_DFL(DS,HAS_STORAGE_CLASS))
        REFITEM(ENUM_DFL(DS,HAS_TYPE_SPEC))
        REFITEM(ENUM_DFL(DS,HAS_TYPE_QUAL))
    )

MAKE(NODE,declaration_specifiers,
        BASE(node)
        DEFITEM(TYPED(REF_ID(declaration_specifiers_subtype),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(REF_ID(storage_class_specifier),scs))
                DEFITEM(TYPED(PTR(REF_NODE(type_specifier)),ts))
                DEFITEM(TYPED(REF_ID(type_qualifier),tq))
            ))
        DEFITEM(TYPED(PTR(REF_NODE(declaration_specifiers)),right))
    )

MAKE(ID,parameter_declaration_subtype,
        REFITEM(ENUM_DFL(PD,HAS_NONE))
        REFITEM(ENUM_DFL(PD,HAS_DECL))
        REFITEM(ENUM_DFL(PD,HAS_ABSTRACT_DECL))
    )

MAKE(NODE,parameter_declaration,
    BASE(declaration_specifiers)
    DEFITEM(TYPED(REF_ID(parameter_declaration_subtype),type))
    DEFITEM(CHOICE(decl,
            DEFITEM(TYPED(PTR(REF_NODE(declarator)),decl))
            DEFITEM(TYPED(PTR(REF_NODE(abstract_declarator)),abstract))
        ))
    )

MAKE(NODE,parameter_list,
        BASE(parameter_declaration)
        DEFITEM(TYPED(PTR(REF_NODE(parameter_list)),left))
    )

MAKE(NODE,parameter_type_list,
    BASE(parameter_list)
    DEFITEM(TYPED(BASIC(bool),has_ellipsis))
    )

MAKE(NODE,identifier_list,
        BASE(identifier)
        DEFITEM(TYPED(PTR(REF_NODE(identifier_list)),left))
    )

MAKE(ID,direct_declarator_type,
        REFITEM(ENUM_DFL(DD,INVALID))
        REFITEM(ENUM_DFL(DD,IDENTIFIER))
        REFITEM(ENUM_DFL(DD,PARENTHESIZED))
        REFITEM(ENUM_DFL(DD,ARRAY))
        REFITEM(ENUM_DFL(DD,FUNCTION))
    )

MAKE(PRIV,array_direct_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(direct_declarator)),left))
        DEFITEM(TYPED(PTR(REF_NODE(constant_expression)),index))
    )

MAKE(ID,function_declarator_subtype,
        REFITEM(ENUM_DFL(FD,HAS_NONE))
        REFITEM(ENUM_DFL(FD,HAS_PLIST))
        REFITEM(ENUM_DFL(FD,HAS_ILIST))
    )

MAKE(PRIV,function_direct_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(direct_declarator)),left))
        DEFITEM(TYPED(REF_ID(function_declarator_subtype),type))
        DEFITEM(CHOICE(list,
                DEFITEM(TYPED(PTR(REF_NODE(parameter_type_list)),param))
                DEFITEM(TYPED(PTR(REF_NODE(identifier_list)),ident))
            ))
    )

MAKE(NODE,direct_declarator,
        BASE(node)
        DEFITEM(TYPED(REF_ID(direct_declarator_type),type))
        DEFITEM(CHOICE(c,
                DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
                DEFITEM(TYPED(PTR(REF_NODE(declarator)),decl))
                DEFITEM(TYPED(REF_PRIV(array_direct_inner_),array))
                DEFITEM(TYPED(REF_PRIV(function_direct_inner_),function))
            ))
    )

MAKE(NODE,declarator,
        BASE(direct_declarator)
        DEFITEM(TYPED(BASIC(bool),has_pointer))
    )

MAKE(ID,initializer_subtype,
        REFITEM(ENUM_DFL(I,ASSIGN))
        REFITEM(ENUM_DFL(I,INIT_LIST))
    )

MAKE(NODE,initializer,
        BASE(node)
        DEFITEM(TYPED(REF_ID(initializer_subtype),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(assignment_expression)),ae))
                DEFITEM(TYPED(PTR(REF_NODE(initializer_list)),il))
            ))
    )

MAKE(NODE,initializer_list,
        BASE(initializer)
        DEFITEM(TYPED(PTR(REF_NODE(initializer_list)),left))
    )

MAKE(NODE,init_declarator,
        BASE(declarator)
        DEFITEM(TYPED(PTR(REF_NODE(initializer)),init))
    )

MAKE(NODE,init_declarator_list,
        BASE(init_declarator)
        DEFITEM(TYPED(PTR(REF_NODE(init_declarator_list)),left))
    )

MAKE(NODE,declaration,
        BASE(declaration_specifiers)
        DEFITEM(TYPED(PTR(REF_NODE(init_declarator_list)),decl))
    )

MAKE(NODE,aggregate_declarator,
        BASE(node)
        DEFITEM(TYPED(BASIC(bool),has_decl))
        DEFITEM(TYPED(PTR(REF_NODE(declarator)),decl))
        DEFITEM(TYPED(BASIC(bool),has_bitfield))
        DEFITEM(TYPED(PTR(REF_NODE(constant_expression)),bf))
    )

MAKE(NODE,aggregate_declarator_list,
        BASE(aggregate_declarator)
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_declarator_list)),prev))
    )

// control

MAKE(NODE,expression_statement,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(expression)),expr))
    )

MAKE(ID,selection_statement_subtype,
        REFITEM(ENUM_DFL(ES,IF))
        REFITEM(ENUM_DFL(ES,SWITCH))
    )

MAKE(NODE,selection_statement,
        BASE(node)
        DEFITEM(TYPED(REF_ID(selection_statement_subtype),type))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),cond))
        DEFITEM(TYPED(PTR(REF_NODE(statement)),if_stat))
        DEFITEM(TYPED(PTR(REF_NODE(statement)),else_stat))
    )

MAKE(ID,labeled_statement_subtype,
        REFITEM(ENUM_DFL(LS,LABELED))
        REFITEM(ENUM_DFL(LS,CASE))
    )

MAKE(NODE,labeled_statement,
        BASE(node)
        DEFITEM(TYPED(REF_ID(labeled_statement_subtype),type))
        DEFITEM(TYPED(PTR(REF_NODE(statement)),right))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
                DEFITEM(TYPED(PTR(REF_NODE(constant_expression)),case_id))
            ))
    )

MAKE(NODE,declaration_list,
        BASE(declaration)
        DEFITEM(TYPED(PTR(REF_NODE(declaration_list)),left))
    )

MAKE(NODE,compound_statement,
        BASE(node)
        /// @todo support mixed declarations and statements as C99 demands
        DEFITEM(TYPED(PTR(REF_NODE(declaration_list)),dl))
        DEFITEM(TYPED(PTR(REF_NODE(statement_list)),st))
    )

MAKE(ID,iteration_statement_subtype,
        REFITEM(ENUM_DFL(IST,WHILE))
        REFITEM(ENUM_DFL(IST,DO_WHILE))
        REFITEM(ENUM_DFL(IST,FOR))
    )

MAKE(NODE,iteration_statement,
        BASE(node)
        DEFITEM(TYPED(REF_ID(iteration_statement_subtype),type))
        DEFITEM(TYPED(PTR(REF_NODE(statement)),action))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),before_expr))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),while_expr))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),after_expr))
    )

MAKE(ID,jump_statement_subtype,
        REFITEM(ENUM_DFL(JS,GOTO))
        REFITEM(ENUM_DFL(JS,CONTINUE))
        REFITEM(ENUM_DFL(JS,BREAK))
        REFITEM(ENUM_DFL(JS,RETURN))
    )

MAKE(NODE,jump_statement,
        BASE(node)
        DEFITEM(TYPED(REF_ID(jump_statement_subtype),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(identifier)),goto_id))
                DEFITEM(TYPED(PTR(REF_NODE(expression)),return_expr))
            ))
    )

MAKE(ID,statement_type,
        REFITEM(ENUM_DFL(ST,LABELED))
        REFITEM(ENUM_DFL(ST,COMPOUND))
        REFITEM(ENUM_DFL(ST,EXPRESSION))
        REFITEM(ENUM_DFL(ST,SELECTION))
        REFITEM(ENUM_DFL(ST,ITERATION))
        REFITEM(ENUM_DFL(ST,JUMP))
    )

MAKE(NODE,statement,
        BASE(node)
        DEFITEM(TYPED(REF_ID(statement_type),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(labeled_statement   )),ls))
                DEFITEM(TYPED(PTR(REF_NODE(compound_statement  )),cs))
                DEFITEM(TYPED(PTR(REF_NODE(expression_statement)),es))
                DEFITEM(TYPED(PTR(REF_NODE(selection_statement )),ss))
                DEFITEM(TYPED(PTR(REF_NODE(iteration_statement )),is))
                DEFITEM(TYPED(PTR(REF_NODE(jump_statement      )),js))
            ))
        )

MAKE(NODE,statement_list,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(statement)),st))
        DEFITEM(TYPED(PTR(REF_NODE(statement_list)),prev))
    )

// top-levels
MAKE(ID,external_declaration_subtype,
        REFITEM(ENUM_DFL(ED,FUNC_DEF))
        REFITEM(ENUM_DFL(ED,DECL))
    )

MAKE(NODE,external_declaration,
        BASE(node)
        DEFITEM(TYPED(REF_ID(external_declaration_subtype),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(function_definition)),func))
                DEFITEM(TYPED(PTR(REF_NODE(declaration)),decl))
            ))
    )

MAKE(NODE,translation_unit,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(external_declaration)),right))
        DEFITEM(TYPED(PTR(REF_NODE(translation_unit)),left))
    )

MAKE(NODE,function_definition,
        BASE(node)
        DEFITEM(TYPED(PTR(REF_NODE(declaration_specifiers)),decl_spec))
        DEFITEM(TYPED(PTR(REF_NODE(declarator            )),decl     ))
        DEFITEM(TYPED(PTR(REF_NODE(declaration_list      )),decl_list))
        DEFITEM(TYPED(PTR(REF_NODE(compound_statement    )),stat     ))
    )

