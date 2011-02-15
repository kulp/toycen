MAKE(NODE,node,
        /* only node_type, already there */
    )

MAKE(ID,assignment_operator,
        REFITEM(AO_INVALID)
        REFITEM(AO_MULEQ)
        REFITEM(AO_DIVEQ)
        REFITEM(AO_MODEQ)
        REFITEM(AO_ADDEQ)
        REFITEM(AO_SUBEQ)
        REFITEM(AO_SLEQ)
        REFITEM(AO_SREQ)
        REFITEM(AO_ANDEQ)
        REFITEM(AO_XOREQ)
        REFITEM(AO_OREQ)
        REFITEM(ENUM_VAL(AO_EQ,'='))
    )

MAKE(PRIV,assignment_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(unary_expression)),left))
        DEFITEM(TYPED(REF_ID(assignment_operator),op))
        DEFITEM(TYPED(PTR(REF_NODE(assignment_expression)),right))
    )

MAKE(ID,type_class,
        REFITEM(TC_INVALID)
        REFITEM(TC_VOID)
        REFITEM(TC_INT)
        REFITEM(TC_FLOAT)
        REFITEM(TC_STRUCT)
        REFITEM(TC_UNION)
        REFITEM(TC_max)
    )

MAKE(ID,primary_expression_type,
        REFITEM(PRET_INVALID)
        REFITEM(PRET_IDENTIFIER)
        REFITEM(PRET_INTEGER)
        REFITEM(PRET_CHARACTER)
        REFITEM(PRET_FLOATING)
        REFITEM(PRET_STRING)
        REFITEM(PRET_PARENTHESIZED)
    )

MAKE(ID,expression_type,
        REFITEM(ET_INVALID)
        REFITEM(ET_CAST_EXPRESSION)
        REFITEM(ET_MULTIPLICATIVE_EXRESSION)
        /// @todo fill in the rest
        REFITEM(ET_max)
    )

MAKE(ID,unary_operator,
        REFITEM(UO_INVALID)
        REFITEM(ENUM_VAL(UO_ADDRESS_OF    ,'&'))
        REFITEM(ENUM_VAL(UO_DEREFERENCE   ,'*'))
        REFITEM(ENUM_VAL(UO_PLUS          ,'+'))
        REFITEM(ENUM_VAL(UO_MINUS         ,'-'))
        REFITEM(ENUM_VAL(UO_BITWISE_INVERT,'~'))
        REFITEM(ENUM_VAL(UO_LOGICAL_INVERT,'!'))
    )

MAKE(ID,binary_operator,
        /// @todo but what about multi-character operators
        REFITEM(BO_INVALID)
        REFITEM(ENUM_VAL(BO_ADD        ,'+'))
        REFITEM(ENUM_VAL(BO_SUBTRACT   ,'-'))
        REFITEM(ENUM_VAL(BO_MULTIPLY   ,'*'))
        REFITEM(ENUM_VAL(BO_DIVIDE     ,'/'))
        REFITEM(ENUM_VAL(BO_MODULUS    ,'%'))
        REFITEM(ENUM_VAL(BO_BITWISE_AND,'&'))
        REFITEM(BO_max)
    )

MAKE(ID,increment_operator,
        REFITEM(IO_INCREMENT)
        REFITEM(IO_DECREMENT)
    )

MAKE(NODE,assignment_expression,
        DEFITEM(TYPED(bool,has_op))
        DEFITEM(CHOICE(c,
            DEFITEM(TYPED(PTR(REF_NODE(conditional_expression)),right))
            DEFITEM(TYPED(REF_NODE(assignment_inner_),assn))
        ))
    )

MAKE(NODE,expression,
        DEFITEM(TYPED(PTR(REF_NODE(assignment_expression)),right))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),left))
    )

MAKE(ID,sq_meta,
        REFITEM(SQ_HAS_TYPE_SPEC)
        REFITEM(SQ_HAS_TYPE_QUAL)
    )

MAKE(NODE,specifier_qualifier_list,
        DEFITEM(TYPED(REF_ID(sq_meta),type))
        DEFITEM(TYPED(PTR(REF_NODE(specifier_qualifier_list)),next))
    )

MAKE(ID,type_qualifier,
        REFITEM(TQ_INVALID)
        REFITEM(TQ_CONST)
        REFITEM(TQ_VOLATILE)
    )

MAKE(NODE,type_qualifier_list,
        DEFITEM(TYPED(REF_ID(type_qualifier),me))
        DEFITEM(TYPED(PTR(REF_NODE(type_qualifier_list)),left))
    )

MAKE(NODE,pointer,
        DEFITEM(TYPED(PTR(REF_NODE(type_qualifier_list)),tq))
        DEFITEM(TYPED(PTR(REF_NODE(pointer)),right))
    )

MAKE(ID,direct_abstract_declarator_subtype,
        REFITEM(DA_INVALID)
        REFITEM(DA_PARENTHESIZED)
        REFITEM(DA_ARRAY_INDEX)
        REFITEM(DA_FUNCTION_CALL)
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
        DEFITEM(TYPED(REF_ID(direct_abstract_declarator_subtype),type))
        DEFITEM(CHOICE(me,
            DEFITEM(TYPED(PTR(REF_NODE(abstract_declarator)),abs))
            DEFITEM(TYPED(REF_PRIV(array_inner_),array))
            DEFITEM(TYPED(REF_PRIV(func_inner_),function))
        ))
    )

MAKE(NODE,abstract_declarator,
        DEFITEM(TYPED(PTR(REF_NODE(pointer)),ptr))
        DEFITEM(TYPED(PTR(REF_NODE(direct_abstract_declarator)),right))
    )

MAKE(NODE,type_name,
        DEFITEM(TYPED(PTR(REF_NODE(specifier_qualifier_list)),list))
        DEFITEM(TYPED(PTR(REF_NODE(abstract_declarator)),decl))
    )

MAKE(NODE,identifier,
        DEFITEM(TYPED(size_t,len))
        DEFITEM(TYPED(PTR(char),name))
    )

MAKE(NODE,integer,
        DEFITEM(TYPED(size_t,size))
        DEFITEM(TYPED(bool,is_signed))
        DEFITEM(CHOICE(me,
            // TODO typedef the multi-word types
            DEFITEM(TYPED(short,s))
            DEFITEM(TYPED(int,i))
            DEFITEM(TYPED(long,l))
            DEFITEM(TYPED(long long,ll))
            DEFITEM(TYPED(signed short,ss))
            DEFITEM(TYPED(signed int,si))
            DEFITEM(TYPED(signed long,sl))
            DEFITEM(TYPED(signed long long,sll))
            DEFITEM(TYPED(unsigned short,us))
            DEFITEM(TYPED(unsigned int,ui))
            DEFITEM(TYPED(unsigned long,ul))
            DEFITEM(TYPED(unsigned long long,ull))
        ))
    )

MAKE(NODE,character,
    /// @todo support wchars ?
    //size_t size;
    DEFITEM(TYPED(bool,has_signage))
    DEFITEM(TYPED(bool,is_signed))
    DEFITEM(CHOICE(me,
            DEFITEM(TYPED(char,c))
            DEFITEM(TYPED(signed char,lc))
            DEFITEM(TYPED(unsigned char,uc))
        ))
    )

MAKE(NODE,floating,
    DEFITEM(TYPED(size_t,size))
    DEFITEM(CHOICE(me,
            DEFITEM(TYPED(float,f))
            DEFITEM(TYPED(double,d))
            DEFITEM(TYPED(long double,ld))
        ))
    )

MAKE(NODE,string,
        DEFITEM(TYPED(size_t,size))
        DEFITEM(TYPED(PTR(REF_NODE(character)),value))
        DEFITEM(TYPED(char,*cached))
    )

MAKE(NODE,expression_having_type_,
        DEFITEM(TYPED(REF_ID(expression_type),type))
    )

MAKE(NODE,primary_expression,
        DEFITEM(TYPED(REF_NODE(expression_having_type_),base))
        DEFITEM(TYPED(REF_ID(primary_expression_type),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
                DEFITEM(TYPED(PTR(REF_NODE(integer)),i))
                DEFITEM(TYPED(PTR(REF_NODE(character)),c))
                DEFITEM(TYPED(PTR(REF_NODE(floating)),f))
                DEFITEM(TYPED(PTR(REF_NODE(string)),s))
                DEFITEM(TYPED(PTR(REF_NODE(expression)),e))
            ))
    )

MAKE(NODE,argument_expression_list,
        DEFITEM(TYPED(REF_NODE(assignment_expression),base))
        DEFITEM(TYPED(PTR(REF_NODE(argument_expression_list)),left))
    )

MAKE(ID,postfix_expression_type,
        REFITEM(PET_INVALID)
        REFITEM(PET_PRIMARY)
        REFITEM(PET_ARRAY_INDEX)
        REFITEM(PET_FUNCTION_CALL)
        REFITEM(PET_AGGREGATE_SELECTION)
        REFITEM(PET_AGGREGATE_PTR_SELECTION)
        REFITEM(PET_POSTINCREMENT)
        REFITEM(PET_POSTDECREMENT)
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
    //struct primary_expression me;
        DEFITEM(TYPED(REF_ID(postfix_expression_type),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(primary_expression)),pri))
                DEFITEM(TYPED(PTR(REF_NODE(postfix_expression)),left))
                DEFITEM(TYPED(REF_NODE(array_postfix_inner_),array))
                DEFITEM(TYPED(REF_NODE(function_postfix_inner_),function))
                DEFITEM(TYPED(REF_NODE(aggregate_postfix_inner_),aggregate))
            ))
        //struct postfix_expression *left;
    )

MAKE(ID,unary_expression_type,
        REFITEM(UET_INVALID)
        REFITEM(UET_POSTFIX)
        REFITEM(UET_PREINCREMENT)
        REFITEM(UET_PREDECREMENT)
        REFITEM(UET_UNARY_OP)
        REFITEM(UET_SIZEOF_EXPR)
        REFITEM(UET_SIZEOF_TYPE)
    )

MAKE(PRIV,ce_unary_inner_,
        DEFITEM(TYPED(REF_ID(unary_operator),uo))
        DEFITEM(TYPED(PTR(REF_NODE(cast_expression)),ce))
    )

MAKE(NODE,unary_expression,
        DEFITEM(TYPED(REF_NODE(postfix_expression),me))
        DEFITEM(TYPED(REF_ID(unary_expression_type),type))
        DEFITEM(CHOICE(c,
                DEFITEM(TYPED(PTR(REF_NODE(unary_expression)),ue))
                DEFITEM(TYPED(REF_NODE(ce_unary_inner_),ce))
                DEFITEM(TYPED(PTR(REF_NODE(type_name)),tn))
            ))
    )

MAKE(PRIV,cast_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(cast_expression)),ce))
        DEFITEM(TYPED(PTR(REF_NODE(type_name)),tn))
    )

MAKE(NODE,cast_expression,
    DEFITEM(CHOICE(me,
            DEFITEM(TYPED(PTR(REF_NODE(unary_expression)),unary))
            DEFITEM(TYPED(REF_NODE(cast_inner_),cast))
        ))
    )

MAKE(NODE,multiplicative_expression,
        DEFITEM(TYPED(REF_NODE(cast_expression),right))
        DEFITEM(TYPED(PTR(REF_NODE(multiplicative_expression)),left)) ///< may be NULL
        DEFITEM(TYPED(REF_ID(binary_operator),op))                ///< if @c is NULL, nonsensical
    )

MAKE(NODE,additive_expression,
        DEFITEM(TYPED(REF_NODE(multiplicative_expression),right))
        DEFITEM(TYPED(PTR(REF_NODE(additive_expression)),left))       ///< may be NULL
        DEFITEM(TYPED(REF_ID(binary_operator),op))                ///< if @c is NULL, nonsensical
    )

MAKE(ID,shift_operator,
        REFITEM(SO_LSH)
        REFITEM(SO_RSH)
    )

MAKE(NODE,shift_expression,
        DEFITEM(TYPED(REF_NODE(additive_expression),base))
        DEFITEM(TYPED(REF_ID(shift_operator),op))
        DEFITEM(TYPED(PTR(REF_NODE(shift_expression)),left))
    )

MAKE(ID,relational_operator,
        REFITEM(RO_LT)
        REFITEM(RO_GT)
        REFITEM(RO_LTEQ)
        REFITEM(RO_GTEQ)
    )

MAKE(NODE,relational_expression,
        DEFITEM(TYPED(REF_NODE(shift_expression),right))
        DEFITEM(TYPED(REF_ID(relational_operator),op))
        DEFITEM(TYPED(PTR(REF_NODE(relational_expression)),left))
    )

MAKE(NODE,equality_expression,
        DEFITEM(TYPED(REF_NODE(relational_expression),right))
        DEFITEM(TYPED(bool,eq))
        DEFITEM(TYPED(PTR(REF_NODE(equality_expression)),left))
    )

MAKE(NODE,and_expression,
        DEFITEM(TYPED(REF_NODE(equality_expression),right))
        DEFITEM(TYPED(PTR(REF_NODE(and_expression)),left))
    )

MAKE(NODE,exclusive_or_expression,
        DEFITEM(TYPED(REF_NODE(and_expression),right))
        DEFITEM(TYPED(PTR(REF_NODE(exclusive_or_expression)),left))
    )

MAKE(NODE,inclusive_or_expression,
        DEFITEM(TYPED(REF_NODE(exclusive_or_expression),right))
        DEFITEM(TYPED(PTR(REF_NODE(inclusive_or_expression)),left))
    )

MAKE(NODE,logical_and_expression,
        DEFITEM(TYPED(REF_NODE(inclusive_or_expression),right))
        DEFITEM(TYPED(PTR(REF_NODE(logical_and_expression)),left))
    )

MAKE(NODE,logical_or_expression,
        DEFITEM(TYPED(REF_NODE(logical_and_expression),right))
        DEFITEM(TYPED(PTR(REF_NODE(logical_or_expression)),left))
    )

MAKE(NODE,conditional_expression,
        DEFITEM(TYPED(REF_NODE(logical_or_expression),right))
        DEFITEM(TYPED(bool,is_ternary))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),if_expr))
        DEFITEM(TYPED(PTR(REF_NODE(conditional_expression)),else_expr))
    )

MAKE(NODE,constant_expression,
        DEFITEM(TYPED(REF_NODE(conditional_expression),right))
        DEFITEM(TYPED(char,dummy)) ///< to avoid warnings about empty initializer braces, since there is nothing to initialize
    )

MAKE(NODE,aggregate_definition,
        DEFITEM(TYPED(bool,TODO)) /// @todo
    )

MAKE(NODE,aggregate_definition_list,
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_definition)),me))
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_definition_list)),prev))
    )

MAKE(NODE,aggregate_declaration,
        DEFITEM(TYPED(PTR(REF_NODE(specifier_qualifier_list)),sq))
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_declarator_list)),decl))
    )

MAKE(NODE,aggregate_declaration_list,
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_declaration)),me))
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_declaration_list)),prev))
    )

MAKE(ID,aggregate_type,
        REFITEM(AT_UNION)
        REFITEM(AT_STRUCT)
    )

MAKE(NODE,aggregate_specifier,
        DEFITEM(TYPED(REF_NODE(node),base))
        DEFITEM(TYPED(REF_ID(aggregate_type),type))
        DEFITEM(TYPED(bool,has_id))
        DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
        DEFITEM(TYPED(bool,has_list))
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_declaration_list)),list))
    )

MAKE(NODE,enumerator,
        DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
        DEFITEM(TYPED(PTR(REF_NODE(constant_expression)),val))
    )

MAKE(NODE,enumerator_list,
        DEFITEM(TYPED(PTR(REF_NODE(enumerator)),me))
        DEFITEM(TYPED(PTR(REF_NODE(enumerator_list)),prev))
    )

MAKE(NODE,enum_specifier,
        DEFITEM(TYPED(REF_NODE(node),base))
        DEFITEM(TYPED(bool,has_id))
        DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
        DEFITEM(TYPED(bool,has_list))
        DEFITEM(TYPED(PTR(REF_NODE(enumerator_list)),list))
    )

MAKE(ID,type_specifier_type,
        REFITEM(TS_INVALID)
        REFITEM(TS_VOID)
        REFITEM(TS_CHAR)
        REFITEM(TS_SHORT)
        REFITEM(TS_INT)
        REFITEM(TS_LONG)
        REFITEM(TS_FLOAT)
        REFITEM(TS_DOUBLE)
        REFITEM(TS_SIGNED)
        REFITEM(TS_UNSIGNED)
        REFITEM(TS_STRUCT_OR_UNION_SPEC)
        REFITEM(TS_ENUM_SPEC)
        REFITEM(TS_TYPEDEF_NAME)
    )

MAKE(NODE,type_specifier,
        DEFITEM(TYPED(REF_NODE(node),base))
        DEFITEM(TYPED(REF_ID(type_specifier_type),type))
        DEFITEM(CHOICE(c,
                DEFITEM(TYPED(PTR(REF_NODE(aggregate_specifier)),as))
                DEFITEM(TYPED(PTR(REF_NODE(enum_specifier)),es))
                DEFITEM(TYPED(PTR(REF_NODE(type_name)),tn))
            ))
    )

MAKE(ID,storage_class_specifier,
        REFITEM(SCS_INVALID)
        REFITEM(SCS_TYPEDEF)
        REFITEM(SCS_EXTERN)
        REFITEM(SCS_STATIC)
        REFITEM(SCS_AUTO)
        REFITEM(SCS_REGISTER)
    )

MAKE(ID,declaration_specifiers_subtype,
        REFITEM(DS_HAS_STORAGE_CLASS)
        REFITEM(DS_HAS_TYPE_SPEC)
        REFITEM(DS_HAS_TYPE_QUAL)
    )

MAKE(NODE,declaration_specifiers,
    DEFITEM(TYPED(REF_ID(declaration_specifiers_subtype),type))
    DEFITEM(CHOICE(me,
            DEFITEM(TYPED(REF_ID(storage_class_specifier),scs))
            DEFITEM(TYPED(PTR(REF_NODE(type_specifier)),ts))
            DEFITEM(TYPED(REF_ID(type_qualifier),tq))
        ))
        DEFITEM(TYPED(PTR(REF_NODE(declaration_specifiers)),right))
    )

MAKE(ID,parameter_declaration_subtype,
        REFITEM(PD_HAS_NONE)
        REFITEM(PD_HAS_DECL)
        REFITEM(PD_HAS_ABSTRACT_DECL)
    )

MAKE(NODE,parameter_declaration,
    DEFITEM(TYPED(REF_NODE(declaration_specifiers),base))
    DEFITEM(TYPED(REF_ID(parameter_declaration_subtype),type))
    DEFITEM(CHOICE(decl,
            DEFITEM(TYPED(PTR(REF_NODE(declarator)),decl))
            DEFITEM(TYPED(PTR(REF_NODE(abstract_declarator)),abstract))
        ))
    )

MAKE(NODE,parameter_list,
        DEFITEM(TYPED(REF_NODE(parameter_declaration),base))
        DEFITEM(TYPED(PTR(REF_NODE(parameter_list)),left))
    )

MAKE(NODE,parameter_type_list,
    DEFITEM(TYPED(REF_NODE(parameter_list),base))
    DEFITEM(TYPED(bool,has_ellipsis))
    )

MAKE(NODE,identifier_list,
        DEFITEM(TYPED(REF_NODE(identifier),base))
        DEFITEM(TYPED(PTR(REF_NODE(identifier_list)),left))
    )

MAKE(ID,direct_declarator_type,
        REFITEM(DD_INVALID)
        REFITEM(DD_IDENTIFIER)
        REFITEM(DD_PARENTHESIZED)
        REFITEM(DD_ARRAY)
        REFITEM(DD_FUNCTION)
    )

MAKE(PRIV,array_direct_inner_,
        DEFITEM(TYPED(PTR(REF_NODE(direct_declarator)),left))
        DEFITEM(TYPED(PTR(REF_NODE(constant_expression)),index))
    )

MAKE(ID,function_declarator_subtype,
        REFITEM(FD_HAS_NONE)
        REFITEM(FD_HAS_PLIST)
        REFITEM(FD_HAS_ILIST)
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
    DEFITEM(TYPED(REF_ID(direct_declarator_type),type))
    DEFITEM(CHOICE(c,
            DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
            DEFITEM(TYPED(PTR(REF_NODE(declarator)),decl))
            DEFITEM(TYPED(REF_NODE(array_direct_inner_),array))
            DEFITEM(TYPED(REF_NODE(function_direct_inner_),function))
    /// @todo unify "me" and "val" synonyms / overlap
        ))
    )

MAKE(NODE,declarator,
        DEFITEM(TYPED(REF_NODE(direct_declarator),base))
        DEFITEM(TYPED(bool,has_pointer))
    )

MAKE(ID,initializer_subtype,
        REFITEM(I_ASSIGN)
        REFITEM(I_INIT_LIST)
    )

MAKE(NODE,initializer,
    DEFITEM(TYPED(REF_ID(initializer_subtype),type))
    DEFITEM(CHOICE(me,
            DEFITEM(TYPED(PTR(REF_NODE(assignment_expression)),ae))
            DEFITEM(TYPED(PTR(REF_NODE(initializer_list)),il))
        ))
    )

MAKE(NODE,initializer_list,
        DEFITEM(TYPED(REF_NODE(initializer),me))
        DEFITEM(TYPED(PTR(REF_NODE(initializer_list)),left))
    )

MAKE(NODE,init_declarator,
        DEFITEM(TYPED(REF_NODE(declarator),base))
        DEFITEM(TYPED(PTR(REF_NODE(initializer)),init))
    )

MAKE(NODE,init_declarator_list,
        DEFITEM(TYPED(REF_NODE(init_declarator),base))
        DEFITEM(TYPED(PTR(REF_NODE(init_declarator_list)),left))
    )

MAKE(NODE,declaration,
        DEFITEM(TYPED(REF_NODE(declaration_specifiers),base))
        DEFITEM(TYPED(PTR(REF_NODE(init_declarator_list)),decl))
    )

MAKE(NODE,aggregate_declarator,
        DEFITEM(TYPED(bool,has_decl))
        DEFITEM(TYPED(PTR(REF_NODE(declarator)),decl))
        DEFITEM(TYPED(bool,has_bitfield))
        DEFITEM(TYPED(PTR(REF_NODE(constant_expression)),bf))
    )

MAKE(NODE,aggregate_declarator_list,
        DEFITEM(TYPED(REF_NODE(aggregate_declarator),base))
        DEFITEM(TYPED(PTR(REF_NODE(aggregate_declarator_list)),prev))
    )

// control

MAKE(NODE,expression_statement,
        DEFITEM(TYPED(PTR(REF_NODE(expression)),expr))
    )

MAKE(ID,selection_statement_subtype,
        REFITEM(ES_IF)
        REFITEM(ES_SWITCH)
    )

MAKE(NODE,selection_statement,
        DEFITEM(TYPED(REF_ID(selection_statement_subtype),type))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),cond))
        DEFITEM(TYPED(PTR(REF_NODE(statement)),if_stat))
        DEFITEM(TYPED(PTR(REF_NODE(statement)),else_stat))
    )

MAKE(ID,labeled_statement_subtype,
        REFITEM(LS_LABELED)
        REFITEM(LS_CASE)
    )

MAKE(NODE,labeled_statement,
        DEFITEM(TYPED(REF_ID(labeled_statement_subtype),type))
        DEFITEM(TYPED(PTR(REF_NODE(statement)),right))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(identifier)),id))
                DEFITEM(TYPED(PTR(REF_NODE(constant_expression)),case_id))
            ))
    )

MAKE(NODE,declaration_list,
        DEFITEM(TYPED(REF_NODE(declaration),base))
        DEFITEM(TYPED(PTR(REF_NODE(declaration_list)),left))
    )

MAKE(NODE,compound_statement,
    /// @todo support mixed declarations and statements as C99 demands
        DEFITEM(TYPED(PTR(REF_NODE(declaration_list)),dl))
        DEFITEM(TYPED(PTR(REF_NODE(statement_list)),st))
    )

MAKE(ID,iteration_statement_subtype,
        REFITEM(IST_WHILE)
        REFITEM(IST_DO_WHILE)
        REFITEM(IST_FOR)
    )

MAKE(NODE,iteration_statement,
        DEFITEM(TYPED(REF_ID(iteration_statement_subtype),type))
        DEFITEM(TYPED(PTR(REF_NODE(statement)),action))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),before_expr))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),while_expr))
        DEFITEM(TYPED(PTR(REF_NODE(expression)),after_expr))
    )

MAKE(ID,jump_statement_subtype,
        REFITEM(JS_GOTO)
        REFITEM(JS_CONTINUE)
        REFITEM(JS_BREAK)
        REFITEM(JS_RETURN)
    )

MAKE(NODE,jump_statement,
        DEFITEM(TYPED(REF_ID(jump_statement_subtype),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(identifier)),goto_id))
                DEFITEM(TYPED(PTR(REF_NODE(expression)),return_expr))
            ))
    )

MAKE(ID,statement_type,
        REFITEM(ST_LABELED)
        REFITEM(ST_COMPOUND)
        REFITEM(ST_EXPRESSION)
        REFITEM(ST_SELECTION)
        REFITEM(ST_ITERATION)
        REFITEM(ST_JUMP)
    )

MAKE(NODE,statement,
        DEFITEM(TYPED(REF_ID(statement_type),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(labeled_statement)),ls))
                DEFITEM(TYPED(PTR(REF_NODE(compound_statement)),cs))
                DEFITEM(TYPED(PTR(REF_NODE(expression_statement)),es))
                DEFITEM(TYPED(PTR(REF_NODE(selection_statement)),ss))
                DEFITEM(TYPED(PTR(REF_NODE(iteration_statement)),is))
                DEFITEM(TYPED(PTR(REF_NODE(jump_statement)),js))
            ))
        )

MAKE(NODE,statement_list,
        DEFITEM(TYPED(REF_NODE(statement*),st))
        DEFITEM(TYPED(PTR(REF_NODE(statement_list)),prev))
    )

// top-levels
MAKE(ID,external_declaration_subtype,
        REFITEM(ED_FUNC_DEF)
        REFITEM(ED_DECL)
    )

MAKE(NODE,external_declaration,
        DEFITEM(TYPED(REF_ID(external_declaration_subtype),type))
        DEFITEM(CHOICE(me,
                DEFITEM(TYPED(PTR(REF_NODE(function_definition)),func))
                DEFITEM(TYPED(PTR(REF_NODE(declaration)),decl))
            ))
    )

MAKE(NODE,translation_unit,
        DEFITEM(TYPED(PTR(REF_NODE(external_declaration)),right))
        DEFITEM(TYPED(PTR(REF_NODE(translation_unit)),left))
    )

MAKE(NODE,function_definition,
        DEFITEM(TYPED(PTR(REF_NODE(declaration_specifiers)),decl_spec))
        DEFITEM(TYPED(PTR(REF_NODE(declarator)),decl))
        DEFITEM(TYPED(PTR(REF_NODE(declaration_list)),decl_list))
        DEFITEM(TYPED(PTR(REF_NODE(compound_statement)),stat))
    )

