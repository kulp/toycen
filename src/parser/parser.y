/*  $Id: parser.y,v 1.4 1997/11/23 12:52:22 sandro Exp $    */

/*
 * Copyright (c) 1997 Sandro Sigala <ssigala@globalnet.it>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * ISO C parser.
 *
 * Based on the ISO C 9899:1990 international standard.
 */

%{
#define _XOPEN_SOURCE 600

#include "ast.h"
#include "parser_primitives.h"
#include "lexer.h"

#include <assert.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

int parser_add_typename(struct parser_state *ps, scope_t *scope, const char *type);

#define YYLEX_PARAM (ps->scanner)

%}

%error-verbose
%pure-parser
%locations
%define parse.lac full
%lex-param { void *yyscanner }
/* declare parse_data struct as opaque for bison 2.6 */
%code requires { struct parser_state; }
%parse-param { struct parser_state *ps }
%name-prefix "toycen_"

%union {
    long i;
    char *str;
    char chr;

    /* TODO align */
    enum assignment_operator assn_op;
    enum storage_class_specifier scs;
    enum type_qualifier tq;
    enum unary_operator uo;
    struct abstract_declarator *abs_decl;
    struct additive_expression *add_expr;
    struct aggregate_declaration *ai;
    struct aggregate_declaration_list *al;
    struct aggregate_declarator *adecl;
    struct aggregate_declarator_list *adecl_list;
    struct aggregate_specifier *as;
    struct and_expression *and_expr;
    struct argument_expression_list *ael;
    struct assignment_expression *assn_expr;
    struct cast_expression *ce;
    struct compound_statement *comp_stat;
    struct conditional_expression *cond_expr;
    struct constant_expression *const_expr;
    struct declaration *decln;
    struct declaration_list *decln_list;
    struct declaration_specifiers *decl_spec;
    struct declarator *decl;
    struct direct_abstract_declarator *dir_abs_decl;
    struct direct_declarator *ddecl;
    struct enum_specifier *enum_spec;
    struct enumerator *ei;
    struct enumerator_list *el;
    struct equality_expression *eq_expr;
    struct exclusive_or_expression *e_or_expr;
    struct expression *expr;
    struct expression_statement *expr_stat;
    struct external_declaration *ext_decl;
    struct function_definition *func_def;
    struct identifier *id;
    struct identifier_list *ident_list;
    struct inclusive_or_expression *i_or_expr;
    struct init_declarator *i_decl;
    struct init_declarator_list *i_d_list;
    struct initializer *init;
    struct initializer_list *init_list;
    struct iteration_statement *iter_stat;
    struct jump_statement *jump_stat;
    struct labeled_statement *lab_stat;
    struct logical_and_expression *l_and_expr;
    struct logical_or_expression *l_or_expr;
    struct multiplicative_expression *mult_expr;
    struct parameter_declaration *p_decl;
    struct parameter_list *p_list;
    struct parameter_type_list *p_type_list;
    struct pointer *ptr;
    struct postfix_expression *pe;
    struct primary_expression *pri_expr;
    struct relational_expression *rel_expr;
    struct selection_statement *sel_stat;
    struct shift_expression *shift_expr;
    struct specifier_qualifier_list *sq_list;
    struct statement *stat;
    struct statement_list *stat_list;
    struct translation_unit *trans_unit;
    struct type_name *tn;
    struct type_qualifier_list *tq_list;
    struct type_specifier *ts;
    struct unary_expression *ue;
}

%type <abs_decl> abstract_declarator;
%type <add_expr> additive_expression;
%type <adecl> struct_declarator;
%type <adecl_list> struct_declarator_list;
%type <ael> argument_expression_list
%type <ai> struct_declaration
%type <al> struct_declaration_list
%type <and_expr> and_expression;
%type <as> struct_or_union_specifier
%type <assn_expr> assignment_expression;
%type <assn_op> assignment_operator;
%type <ce> cast_expression
%type <comp_stat> compound_statement
%type <cond_expr> conditional_expression;
%type <const_expr> constant_expression;
%type <ddecl> direct_declarator;
%type <decl> declarator;
%type <decl_spec> declaration_specifiers;
%type <decln> declaration
%type <decln_list> declaration_list
%type <dir_abs_decl> direct_abstract_declarator;
%type <e_or_expr> exclusive_or_expression;
%type <ei> enumerator
%type <el> enumerator_list
%type <enum_spec> enum_specifier
%type <eq_expr> equality_expression;
%type <expr> expression;
%type <expr_stat> expression_statement
%type <ext_decl> external_declaration
%type <func_def> function_definition
%type <i> struct_or_union
%type <i_d_list> init_declarator_list
%type <i_decl> init_declarator
%type <i_or_expr> inclusive_or_expression;
%type <id> identifier
%type <ident_list> identifier_list
%type <init> initializer
%type <init_list> initializer_list
%type <iter_stat> iteration_statement
%type <jump_stat> jump_statement
%type <l_and_expr> logical_and_expression;
%type <l_or_expr> logical_or_expression;
%type <lab_stat> labeled_statement
%type <mult_expr> multiplicative_expression;
%type <p_decl> parameter_declaration;
%type <p_list> parameter_list;
%type <p_type_list> parameter_type_list
%type <pe> postfix_expression
%type <pri_expr> primary_expression;
%type <ptr> pointer;
%type <rel_expr> relational_expression;
%type <scs> storage_class_specifier;
%type <sel_stat> selection_statement
%type <shift_expr> shift_expression;
%type <sq_list> specifier_qualifier_list;
%type <stat> statement
%type <stat_list> statement_list
%type <tn> type_name
%type <tq> type_qualifier;
%type <tq_list> type_qualifier_list;
%type <trans_unit> translation_unit
%type <ts> type_specifier
%type <ue> unary_expression
%type <uo> unary_operator

%token IDENTIFIER TYPEDEF_NAME INTEGER FLOATING CHARACTER

%token ELLIPSIS ADDEQ SUBEQ MULEQ DIVEQ MODEQ XOREQ ANDEQ OREQ SL SR
%token SLEQ SREQ EQ NOTEQ LTEQ GTEQ ANDAND OROR PLUSPLUS MINUSMINUS ARROW

%token AUTO BREAK CASE CHAR CONST CONTINUE DEFAULT DO DOUBLE ELSE ENUM
%token EXTERN FLOAT FOR GOTO IF INT LONG REGISTER RETURN SHORT SIGNED SIZEOF
%token STATIC SWITCH TYPEDEF UNSIGNED VOID VOLATILE WHILE

%token <chr> '&' '*' '+' '-' '~' '!' '/' '%'
%token <i> STRUCT UNION
%token <str> STRING

%start translation_unit

%%

/* B.2.1 Expressions. */

primary_expression
    : identifier
        { $$ = NN(primary_expression, .type = PRET_IDENTIFIER, .me = CHOICE(0,id,$1)); }
    | INTEGER
        { struct integer *temp = NN(integer, /** @todo size */.size = 4,
                                             /** @todo is_signed */.is_signed = true,
                                             .me = CHOICE(1,i,strtol(toycen_lval.str, NULL, 0)));
          $$ = NN(primary_expression, .type = PRET_INTEGER   , .me = CHOICE(1,i,temp)); }
    | CHARACTER
        { $$ = NN(primary_expression, .type = PRET_CHARACTER , .me = CHOICE(2,c,/* TODO */NULL)); }
    | FLOATING
        { $$ = NN(primary_expression, .type = PRET_FLOATING  , .me = CHOICE(3,f,/* TODO */NULL)); }
    | STRING
        { $$ = NN(primary_expression, .type = PRET_STRING    , .me = CHOICE(4,s,intern_string(ps,$1))); }
    | '(' expression ')'
        { $$ = NN(primary_expression, .type = PRET_PARENTHESIZED, .me = CHOICE(5,e,$2)); }
    ;

identifier
    : IDENTIFIER
        { $$ = NN(identifier, .len = strlen(toycen_lval.str), .name = strdup(toycen_lval.str)); }
    ;

postfix_expression
    : primary_expression
        { $$ = NN(postfix_expression, .type = PET_PRIMARY, .me = CHOICE(0,pri,$1)); }
    | postfix_expression '[' expression ']'
        { $$ = NN(postfix_expression, .type = PET_ARRAY_INDEX, .me = CHOICE(2,array,{ .left = $1, .index = $3 })); }
    | postfix_expression '(' argument_expression_list ')'
        { $$ = NN(postfix_expression, .type = PET_FUNCTION_CALL, .me = CHOICE(3,function,{ .left = $1, .ael = $3 })); }
    | postfix_expression '(' ')'
        { $$ = NN(postfix_expression, .type = PET_FUNCTION_CALL, .me = CHOICE(3,function,{ .left = $1, .ael = NULL })); }
    | postfix_expression '.' identifier
        { $$ = NN(postfix_expression, .type = PET_AGGREGATE_SELECTION, .me = CHOICE(4,aggregate,{ .left = $1, .designator = $3 })); }
    | postfix_expression ARROW identifier
        { $$ = NN(postfix_expression, .type = PET_AGGREGATE_PTR_SELECTION, .me = CHOICE(4,aggregate,{ .left = $1, .designator = $3 })); }
    | postfix_expression PLUSPLUS
        { $$ = NN(postfix_expression, .type = PET_POSTINCREMENT, .me = CHOICE(1,left,$1)); }
    | postfix_expression MINUSMINUS
        { $$ = NN(postfix_expression, .type = PET_POSTDECREMENT, .me = CHOICE(1,left,$1)); }
    ;

argument_expression_list
    : assignment_expression
        { $$ = UN(argument_expression_list, $1, .left = NULL); }
    | argument_expression_list ',' assignment_expression
        { $$ = UN(argument_expression_list, $3, .left = $1); }
    ;

unary_expression
    : postfix_expression
        { $$ = UN(unary_expression, $1, .type = UET_POSTFIX); }
    | PLUSPLUS unary_expression
        { /** @todo .me */ $$ = NN(unary_expression, .type = UET_PREINCREMENT, .c = CHOICE(0,ue,$2)); }
    | MINUSMINUS unary_expression
        { /** @todo .me */ $$ = NN(unary_expression, .type = UET_PREDECREMENT, .c = CHOICE(0,ue,$2)); }
    | unary_operator cast_expression
        { $$ = NN(unary_expression, .type = UET_UNARY_OP, .c = CHOICE(1,ce,{ .uo = $1, .ce = $2 })); }
    | SIZEOF unary_expression
        { $$ = NN(unary_expression, .type = UET_SIZEOF_EXPR, .c = CHOICE(0,ue,$2)); }
    | SIZEOF '(' type_name ')'
        { $$ = NN(unary_expression, .type = UET_SIZEOF_TYPE, .c = CHOICE(2,tn,$3)); }
    ;

unary_operator
    : '&' { $$ = $<chr>1; }
    | '*' { $$ = $<chr>1; }
    | '+' { $$ = $<chr>1; }
    | '-' { $$ = $<chr>1; }
    | '~' { $$ = $<chr>1; }
    | '!' { $$ = $<chr>1; }
    ;

cast_expression
    : unary_expression
        { $$ = NN(cast_expression, .me = CHOICE(0,unary,$1)); }
    | '(' type_name ')' cast_expression
        { $$ = NN(cast_expression, .me = CHOICE(1,cast,{ .tn = $2, .ce = $4 })); }
    ;

multiplicative_expression
    : cast_expression
        { $$ = UN(multiplicative_expression, $1, .left = NULL, .op = BO_INVALID); }
    | multiplicative_expression '*' cast_expression
        { $$ = UN(multiplicative_expression, $3, .left = $1, .op = BO_MULTIPLY); }
    | multiplicative_expression '/' cast_expression
        { $$ = UN(multiplicative_expression, $3, .left = $1, .op = BO_DIVIDE); }
    | multiplicative_expression '%' cast_expression
        { $$ = UN(multiplicative_expression, $3, .left = $1, .op = BO_MODULUS); }
    ;

additive_expression
    : multiplicative_expression
        { $$ = UN(additive_expression, $1, .left = NULL, .op = BO_INVALID); }
    | additive_expression '+' multiplicative_expression
        { $$ = UN(additive_expression, $3, .left = $1, .op = BO_ADD); }
    | additive_expression '-' multiplicative_expression
        { $$ = UN(additive_expression, $3, .left = $1, .op = BO_SUBTRACT); }
    ;

shift_expression
    : additive_expression
        { $$ = UN(shift_expression, $1, .left = NULL, .op = SO_INVALID); }
    | shift_expression SL additive_expression
        { $$ = UN(shift_expression, $3, .left = $1, .op = SO_LSH); }
    | shift_expression SR additive_expression
        { $$ = UN(shift_expression, $3, .left = $1, .op = SO_RSH); }
    ;

relational_expression
    : shift_expression
        { $$ = UN(relational_expression, $1, .left = NULL, .op = RO_INVALID); }
    | relational_expression '<' shift_expression
        { $$ = UN(relational_expression, $3, .left = $1, .op = RO_LT); }
    | relational_expression '>' shift_expression
        { $$ = UN(relational_expression, $3, .left = $1, .op = RO_GT); }
    | relational_expression LTEQ shift_expression
        { $$ = UN(relational_expression, $3, .left = $1, .op = RO_LTEQ); }
    | relational_expression GTEQ shift_expression
        { $$ = UN(relational_expression, $3, .left = $1, .op = RO_GTEQ); }
    ;

equality_expression
    : relational_expression
        { $$ = UN(equality_expression, $1, .left = NULL); }
    | equality_expression EQ relational_expression
        { $$ = UN(equality_expression, $3, .left = $1, .eq = true); }
    | equality_expression NOTEQ relational_expression
        { $$ = UN(equality_expression, $3, .left = $1, .eq = false); }
    ;

and_expression
    : equality_expression
        { $$ = UN(and_expression, $1, .left = NULL); }
    | and_expression '&' equality_expression
        { $$ = UN(and_expression, $3, .left = $1); }
    ;

exclusive_or_expression
    : and_expression
        { $$ = UN(exclusive_or_expression, $1, .left = NULL); }
    | exclusive_or_expression '^' and_expression
        { $$ = UN(exclusive_or_expression, $3, .left = $1); }
    ;

inclusive_or_expression
    : exclusive_or_expression
        { $$ = UN(inclusive_or_expression, $1, .left = NULL); }
    | inclusive_or_expression '|' exclusive_or_expression
        { $$ = UN(inclusive_or_expression, $3, .left = $1); }
    ;

logical_and_expression
    : inclusive_or_expression
        { $$ = UN(logical_and_expression, $1, .left = NULL); }
    | logical_and_expression ANDAND inclusive_or_expression
        { $$ = UN(logical_and_expression, $3, .left = $1); }
    ;

logical_or_expression
    : logical_and_expression
        { $$ = UN(logical_or_expression, $1, .left = NULL); }
    | logical_or_expression OROR logical_and_expression
        { $$ = UN(logical_or_expression, $3, .left = $1); }
    ;

conditional_expression
    : logical_or_expression
        { $$ = UN(conditional_expression, $1, .is_ternary = false); }
    | logical_or_expression '?' expression ':' conditional_expression
        { $$ = UN(conditional_expression, $1, .is_ternary = true, .if_expr = $3, .else_expr = $5); }
    ;

assignment_expression
    : conditional_expression
        { $$ = NN(assignment_expression, .has_op = false, .c = CHOICE(0,right,$1)); }
    | unary_expression assignment_operator assignment_expression
        { $$ = NN(assignment_expression, .has_op = true,  .c = CHOICE(1,assn,{ .left = $1, .op = $2, .right = $3 })); }
    ;

assignment_operator
    : '='   { $$ = AO_EQ   ; }
    | MULEQ { $$ = AO_MULEQ; }
    | DIVEQ { $$ = AO_DIVEQ; }
    | MODEQ { $$ = AO_MODEQ; }
    | ADDEQ { $$ = AO_ADDEQ; }
    | SUBEQ { $$ = AO_SUBEQ; }
    | SLEQ  { $$ = AO_SLEQ ; }
    | SREQ  { $$ = AO_SREQ ; }
    | ANDEQ { $$ = AO_ANDEQ; }
    | XOREQ { $$ = AO_XOREQ; }
    | OREQ  { $$ = AO_OREQ ; }
    ;

expression
    : assignment_expression
        { $$ = UN(expression, $1, .left = NULL); }
    | expression ',' assignment_expression
        { $$ = UN(expression, $3, .left = $1); }
    ;

constant_expression
    : conditional_expression
        { $$ = UN(constant_expression, $1, .dummy = 0); }
    ;

declaration
    : declaration_specifiers init_declarator_list ';'
        { $$ = UN(declaration, $1, .decl = $2);
          struct declaration_specifiers *old = (void*)$$; // realloc may have moved it, can't use $1 any more
          /// @todo this is a very naïve way of handling types : replace it
          if (old->type == DS_HAS_STORAGE_CLASS && CHOICE_REF(&old->me,scs) == SCS_TYPEDEF) {
              struct init_declarator_list *head = $2;
              while (head) {
                  parser_add_typename(ps, NULL, CHOICE_REF(&head->base.base.base.c,id)->name);
                  head = head->left;
              }
          }
        }
    | declaration_specifiers ';'
        { $$ = UN(declaration, $1, .decl = NULL); }
    ;

declaration_specifiers
    : storage_class_specifier declaration_specifiers
        { $$ = NN(declaration_specifiers, .type = DS_HAS_STORAGE_CLASS, .me = CHOICE(0,scs,$1), .right = $2); }
    | storage_class_specifier
        { $$ = NN(declaration_specifiers, .type = DS_HAS_STORAGE_CLASS, .me = CHOICE(0,scs,$1), .right = NULL); }
    | type_specifier declaration_specifiers
        { $$ = NN(declaration_specifiers, .type = DS_HAS_TYPE_SPEC, .me = CHOICE(1,ts,$1), .right = $2); }
    | type_specifier
        { $$ = NN(declaration_specifiers, .type = DS_HAS_TYPE_SPEC, .me = CHOICE(1,ts,$1), .right = NULL); }
    | type_qualifier declaration_specifiers
        { $$ = NN(declaration_specifiers, .type = DS_HAS_TYPE_QUAL, .me = CHOICE(2,tq,$1), .right = $2); }
    | type_qualifier
        { $$ = NN(declaration_specifiers, .type = DS_HAS_TYPE_QUAL, .me = CHOICE(2,tq,$1), .right = NULL); }
    ;

init_declarator_list
    : init_declarator
        { $$ = UN(init_declarator_list, $1, .left = NULL); }
    | init_declarator_list ',' init_declarator
        { $$ = UN(init_declarator_list, $3, .left = $1); }
    ;

init_declarator
    : declarator
        { $$ = UN(init_declarator, $1, .init = NULL); }
    | declarator '=' initializer
        { $$ = UN(init_declarator, $1, .init = $3); }
    ;

storage_class_specifier
    : TYPEDEF  { $$ = SCS_TYPEDEF ; }
    | EXTERN   { $$ = SCS_EXTERN  ; }
    | STATIC   { $$ = SCS_STATIC  ; }
    | AUTO     { $$ = SCS_AUTO    ; }
    | REGISTER { $$ = SCS_REGISTER; }
    ;

type_specifier
    : VOID     { $$ = NN(type_specifier, .type = TS_VOID    ) ; }
    | CHAR     { $$ = NN(type_specifier, .type = TS_CHAR    ) ; }
    | SHORT    { $$ = NN(type_specifier, .type = TS_SHORT   ) ; }
    | INT      { $$ = NN(type_specifier, .type = TS_INT     ) ; }
    | LONG     { $$ = NN(type_specifier, .type = TS_LONG    ) ; }
    | FLOAT    { $$ = NN(type_specifier, .type = TS_FLOAT   ) ; }
    | DOUBLE   { $$ = NN(type_specifier, .type = TS_DOUBLE  ) ; }
    | SIGNED   { $$ = NN(type_specifier, .type = TS_SIGNED  ) ; }
    | UNSIGNED { $$ = NN(type_specifier, .type = TS_UNSIGNED) ; }
    | struct_or_union_specifier
        { $$ = NN(type_specifier, .type = TS_STRUCT_OR_UNION_SPEC, .c = CHOICE(0,as,$1)); }
    | enum_specifier
        { $$ = NN(type_specifier, .type = TS_ENUM_SPEC, .c = CHOICE(1,es,$1)); }
    | TYPEDEF_NAME
        { $$ = NN(type_specifier, .type = TS_TYPEDEF_NAME, .c = CHOICE(2,tn,NULL /* TODO str2type_name(toycen_lval.str))*/)); }
    ;

struct_or_union_specifier
    : struct_or_union identifier '{' struct_declaration_list '}'
        { $$ = NN(aggregate_specifier, .type = $1, .has_id = true, .id = $2, .has_list = true, .list = $4); }
    | struct_or_union '{' struct_declaration_list '}'
        { $$ = NN(aggregate_specifier, .type = $1, .has_id = false, .has_list = true, .list = $3); }
    | struct_or_union identifier
        { $$ = NN(aggregate_specifier, .type = $1, .has_id = true, .id = $2, .has_list = false); }
    ;

struct_or_union
    : STRUCT { $$ = AT_STRUCT; }
    | UNION  { $$ = AT_UNION ; }
    ;

struct_declaration_list
    : struct_declaration
        { $$ = NN(aggregate_declaration_list, .me = $1); }
    | struct_declaration_list struct_declaration
        { $$ = NN(aggregate_declaration_list, .me = $2, .prev = $1); }
    ;

struct_declaration
    : specifier_qualifier_list struct_declarator_list ';'
        { $$ = NN(aggregate_declaration, .sq = $1, .decl = $2); }
    ;

specifier_qualifier_list
    : type_specifier specifier_qualifier_list
        { $$ = NN(specifier_qualifier_list, .type = SQ_HAS_TYPE_SPEC, .next = $2); }
    | type_specifier
        { $$ = NN(specifier_qualifier_list, .type = SQ_HAS_TYPE_SPEC, .next = NULL); }
    | type_qualifier specifier_qualifier_list
        { $$ = NN(specifier_qualifier_list, .type = SQ_HAS_TYPE_QUAL, .next = $2); }
    | type_qualifier
        { $$ = NN(specifier_qualifier_list, .type = SQ_HAS_TYPE_QUAL, .next = NULL); }
    ;

struct_declarator_list
    : struct_declarator
        { $$ = UN(aggregate_declarator_list, $1, .prev = NULL); }
    | struct_declarator_list ',' struct_declarator
        { $$ = UN(aggregate_declarator_list, $3, .prev = $1); }
    ;

struct_declarator
    : declarator
        { $$ = NN(aggregate_declarator, .has_decl = true, .decl = $1, .has_bitfield = false); }
    |  ':' constant_expression
        { $$ = NN(aggregate_declarator, .has_decl = false, .has_bitfield = false, .bf = $2); }
    | declarator ':' constant_expression
        { $$ = NN(aggregate_declarator, .has_decl = true, .decl = $1, .has_bitfield = true, .bf = $3); }
    ;

enum_specifier
    : ENUM identifier '{' enumerator_list '}'
        { $$ = NN(enum_specifier, .has_id = true,
                                  .id = $2,
                                  .has_list = true,
                                  .list = $4,
                                  ); }
    | ENUM '{' enumerator_list '}'
        { $$ = NN(enum_specifier, .has_id = false,
                                  .has_list = true,
                                  .list = $3,
                                  ); }
    | ENUM identifier
        { $$ = NN(enum_specifier, .has_id = true,
                                  .id = $2,
                                  .has_list = false,
                                  ); }
    ;

enumerator_list
    : enumerator
        { $$ = NN(enumerator_list, .me = $1); }
    | enumerator_list ',' enumerator
        { $$ = NN(enumerator_list, .me = $3, .prev = $1); }
    ;

enumerator
    : identifier
        { $$ = NN(enumerator, .id = $1, .val = NULL); }
    | identifier '=' constant_expression
        { $$ = NN(enumerator, .id = $1, .val = $3); }
    ;

type_qualifier
    : CONST    { $$ = TQ_CONST   ; }
    | VOLATILE { $$ = TQ_VOLATILE; }
    ;

declarator
    : pointer direct_declarator
        { $$ = UN(declarator, $2, .has_pointer = true); }
    | direct_declarator
        { $$ = UN(declarator, $1, .has_pointer = false); }
    ;

direct_declarator
    : identifier
        { $$ = NN(direct_declarator, .type = DD_IDENTIFIER, .c = CHOICE(0,id,$1)); }
    | '(' declarator ')'
        { $$ = NN(direct_declarator, .type = DD_PARENTHESIZED, .c = CHOICE(1,decl,$2)); }
    | direct_declarator '[' constant_expression ']'
        { $$ = NN(direct_declarator, .type = DD_ARRAY, .c = CHOICE(2,array,{ .left = $1, .index = $3 })); }
    | direct_declarator '[' ']'
        { $$ = NN(direct_declarator, .type = DD_ARRAY, .c = CHOICE(2,array,{ .left = $1, .index = NULL })); }
    | direct_declarator '(' parameter_type_list ')'
        { $$ = NN(direct_declarator, .type = DD_FUNCTION, .c = CHOICE(3,function,{ .left = $1, .type = FD_HAS_PLIST, .list = CHOICE(0,param,$3) })); }
    | direct_declarator '(' identifier_list ')'
        { $$ = NN(direct_declarator, .type = DD_FUNCTION, .c = CHOICE(3,function,{ .left = $1, .type = FD_HAS_ILIST, .list = CHOICE(1,ident,$3) })); }
    | direct_declarator '(' ')'
        { $$ = NN(direct_declarator, .type = DD_FUNCTION, .c = CHOICE(3,function,{ .left = $1, .type = FD_HAS_NONE })); }
    ;

pointer
    : '*' type_qualifier_list
        { $$ = NN(pointer, .tq = $2, .right = NULL); }
    | '*'
        { $$ = NN(pointer, .tq = NULL, .right = NULL); }
    | '*' type_qualifier_list pointer
        { $$ = NN(pointer, .tq = $2, .right = $3); }
    | '*' pointer
        { $$ = NN(pointer, .right = $2); }
    ;

type_qualifier_list
    : type_qualifier
        { $$ = NN(type_qualifier_list, .me = $1, .left = NULL); }
    | type_qualifier_list type_qualifier
        { $$ = NN(type_qualifier_list, .me = $2, .left = $1); }
    ;

parameter_type_list
    : parameter_list
        { $$ = UN(parameter_type_list, $1, .has_ellipsis = false); }
    | parameter_list ',' ELLIPSIS
        { $$ = UN(parameter_type_list, $1, .has_ellipsis = true); }
    ;

parameter_list
    : parameter_declaration
        { $$ = UN(parameter_list, $1, .left = NULL); }
    | parameter_list ',' parameter_declaration
        { $$ = UN(parameter_list, $3, .left = $1); }
    ;

parameter_declaration
    : declaration_specifiers declarator
        { $$ = UN(parameter_declaration, $1, .type = PD_HAS_DECL, .decl = CHOICE(0,decl,$2)); }
    | declaration_specifiers abstract_declarator
        { $$ = UN(parameter_declaration, $1, .type = PD_HAS_DECL, .decl = CHOICE(1,abstract,$2)); }
    | declaration_specifiers
        { $$ = UN(parameter_declaration, $1, .type = PD_HAS_NONE); }
    ;

identifier_list
    : identifier
        { $$ = UN(identifier_list, $1, .left = NULL); }
    | identifier_list ',' identifier
        { $$ = UN(identifier_list, $3, .left = $1); }
    ;

type_name
    : specifier_qualifier_list
        { $$ = NN(type_name, .list = $1, .decl = NULL); }
    | specifier_qualifier_list abstract_declarator
        { $$ = NN(type_name, .list = $1, .decl = $2); }
    ;

abstract_declarator
    : pointer
        { $$ = NN(abstract_declarator, .ptr = $1, .right = NULL); }
    | direct_abstract_declarator
        { $$ = NN(abstract_declarator, .ptr = NULL, .right = $1); }
    | pointer direct_abstract_declarator
        { $$ = NN(abstract_declarator, .ptr = $1, .right = $2); }
    ;

direct_abstract_declarator
    : '(' abstract_declarator ')'
        { $$ = NN(direct_abstract_declarator, .type = DA_PARENTHESIZED, .me = CHOICE(0,abs,$2)); }
    | '[' ']'
        { $$ = NN(direct_abstract_declarator, .type = DA_ARRAY_INDEX, .me = CHOICE(1,array,{ .left = NULL, .idx = NULL })); }
    | '[' constant_expression ']'
        { $$ = NN(direct_abstract_declarator, .type = DA_ARRAY_INDEX, .me = CHOICE(1,array,{ .left = NULL, .idx = $2 })); }
    | direct_abstract_declarator '[' ']'
        { $$ = NN(direct_abstract_declarator, .type = DA_ARRAY_INDEX, .me = CHOICE(1,array,{ .left = $1, .idx = NULL })); }
    | direct_abstract_declarator '[' constant_expression ']'
        { $$ = NN(direct_abstract_declarator, .type = DA_ARRAY_INDEX, .me = CHOICE(1,array,{ .left = $1, .idx = $3 })); }
    | '(' ')'
        { $$ = NN(direct_abstract_declarator, .type = DA_FUNCTION_CALL, .me = CHOICE(2,function,{ .left = NULL, .params = NULL })); }
    | '(' parameter_type_list ')'
        { $$ = NN(direct_abstract_declarator, .type = DA_FUNCTION_CALL, .me = CHOICE(2,function,{ .left = NULL, .params = $2 })); }
    | direct_abstract_declarator '(' ')'
        { $$ = NN(direct_abstract_declarator, .type = DA_FUNCTION_CALL, .me = CHOICE(2,function,{ .left = $1, .params = NULL })); }
    | direct_abstract_declarator '(' parameter_type_list ')'
        { $$ = NN(direct_abstract_declarator, .type = DA_FUNCTION_CALL, .me = CHOICE(2,function,{ .left = $1, .params = $3 })); }
    ;

initializer
    : assignment_expression
        { $$ = NN(initializer, .me = CHOICE(0,ae,$1)); }
    | '{' initializer_list '}'
        { $$ = NN(initializer, .me = CHOICE(1,il,$2)); }
    | '{' initializer_list ',' '}'
        { $$ = NN(initializer, .me = CHOICE(1,il,$2)); }
    ;

initializer_list
    : initializer
        { $$ = UN(initializer_list, $1, .left = NULL); }
    | initializer_list ',' initializer
        { $$ = UN(initializer_list, $3, .left = $1); }
    ;

/* B.2.3 Statements. */

statement
    : labeled_statement
        { $$ = NN(statement, .type = ST_LABELED, .me = CHOICE(0,ls,$1)); }
    | compound_statement
        { $$ = NN(statement, .type = ST_COMPOUND, .me = CHOICE(1,cs,$1)); }
    | expression_statement
        { $$ = NN(statement, .type = ST_EXPRESSION, .me = CHOICE(2,es,$1)); }
    | selection_statement
        { $$ = NN(statement, .type = ST_SELECTION, .me = CHOICE(3,ss,$1)); }
    | iteration_statement
        { $$ = NN(statement, .type = ST_ITERATION, .me = CHOICE(4,is,$1)); }
    | jump_statement
        { $$ = NN(statement, .type = ST_JUMP, .me = CHOICE(5,js,$1)); }
    ;

labeled_statement
    : identifier ':' statement
        { $$ = NN(labeled_statement, .type = LS_LABELED, .me = CHOICE(0,id,$1), .right = $3); }
    | CASE constant_expression ':' statement
        { $$ = NN(labeled_statement, .type = LS_CASE, .me = CHOICE(1,case_id,$2), .right = $4); }
    | DEFAULT ':' statement
        { $$ = NN(labeled_statement, .type = LS_CASE, .me = CHOICE(1,case_id,NULL), .right = $3); }
    ;

compound_statement
    : '{' '}'
        { $$ = NN(compound_statement, .st = NULL, .dl = NULL); }
    | '{' statement_list '}'
        { $$ = NN(compound_statement, .st = $2, .dl = NULL); }
    | '{' declaration_list '}'
        { $$ = NN(compound_statement, .st = NULL, .dl = $2); }
    | '{' declaration_list statement_list '}'
        { $$ = NN(compound_statement, .st = $3, .dl = $2); }
    ;

declaration_list
    : declaration
        { $$ = UN(declaration_list, $1, .left = NULL); }
    | declaration_list declaration
        { $$ = UN(declaration_list, $2, .left = $1); }
    ;

statement_list
    : statement
        { $$ = NN(statement_list, .st = $1, .prev = NULL); }
    | statement_list statement
        { $$ = NN(statement_list, .st = $2, .prev = $1); }
    ;

expression_statement
    : ';'
        { $$ = NN(expression_statement, .expr = NULL); }
    | expression ';'
        { $$ = NN(expression_statement, .expr = $1); }
    ;

selection_statement
    : IF '(' expression ')' statement
        { $$ = NN(selection_statement, .type = ES_IF, .cond = $3, .if_stat = $5); }
    | IF '(' expression ')' statement ELSE statement
        { $$ = NN(selection_statement, .type = ES_IF, .cond = $3, .if_stat = $5, .else_stat = $7); }
    | SWITCH '(' expression ')' statement
        { $$ = NN(selection_statement, .type = ES_SWITCH, .cond = $3, .if_stat = $5); }
    ;

iteration_statement
    : WHILE '(' expression ')' statement
        { $$ = NN(iteration_statement, .type = IST_WHILE, .while_expr = $3, .action = $5); }
    | DO statement WHILE '(' expression ')' ';'
        { $$ = NN(iteration_statement, .type = IST_DO_WHILE, .while_expr = $5, .action = $2); }
    | FOR '(' ';' ';' ')' statement
        { $$ = NN(iteration_statement, .type = IST_FOR, .action = $6); }
    | FOR '(' expression ';' ';' ')' statement
        { $$ = NN(iteration_statement, .type = IST_FOR, .before_expr = $3, .action = $7); }
    | FOR '(' ';' expression ';' ')' statement
        { $$ = NN(iteration_statement, .type = IST_FOR, .while_expr = $4, .action = $7); }
    | FOR '(' expression ';' expression ';' ')' statement
        { $$ = NN(iteration_statement, .type = IST_FOR, .before_expr = $3, .while_expr = $5, .action = $8); }
    | FOR '(' ';' ';' expression ')' statement
        { $$ = NN(iteration_statement, .type = IST_FOR, .after_expr = $5, .action = $7); }
    | FOR '(' expression ';' ';' expression ')' statement
        { $$ = NN(iteration_statement, .type = IST_FOR, .before_expr = $3, .after_expr = $6, .action = $8); }
    | FOR '(' ';' expression ';' expression ')' statement
        { $$ = NN(iteration_statement, .type = IST_FOR, .while_expr = $4, .after_expr = $6, .action = $8); }
    | FOR '(' expression ';' expression ';' expression ')' statement
        { $$ = NN(iteration_statement, .type = IST_FOR, .before_expr = $3, .while_expr = $5, .after_expr = $7, .action = $9); }
    ;

jump_statement
    : GOTO identifier ';'
        { $$ = NN(jump_statement, .type = JS_GOTO, .me = CHOICE(0,goto_id,$2)); }
    | CONTINUE ';'
        { $$ = NN(jump_statement, .type = JS_CONTINUE); }
    | BREAK ';'
        { $$ = NN(jump_statement, .type = JS_BREAK); }
    | RETURN ';'
        { $$ = NN(jump_statement, .type = JS_RETURN, .me = CHOICE(1,return_expr,NULL)); }
    | RETURN expression ';'
        { $$ = NN(jump_statement, .type = JS_RETURN, .me = CHOICE(1,return_expr,$2)); }
    ;

/* B.2.4 External definitions. */

translation_unit
    : external_declaration
        { ps->top = $$ = NN(translation_unit, .right = $1, .left = NULL); }
    | translation_unit external_declaration
        { ps->top = $$ = NN(translation_unit, .right = $2, .left = $1); }
    ;

external_declaration
    : function_definition
        { $$ = NN(external_declaration, .type = ED_FUNC_DEF, .me = CHOICE(0,func,$1)); }
    | declaration
        { $$ = NN(external_declaration, .type = ED_DECL, .me = CHOICE(1,decl,$1)); }
    ;

function_definition
    : declaration_specifiers declarator declaration_list compound_statement
        { $$ = NN(function_definition, .decl_spec = $1, .decl = $2, .decl_list = $3, .stat = $4); }
    | declaration_specifiers declarator compound_statement
        { $$ = NN(function_definition, .decl_spec = $1, .decl = $2, .stat = $3); }
    | declarator declaration_list compound_statement
        { $$ = NN(function_definition, .decl = $1, .decl_list = $2, .stat = $3); }
    | declarator compound_statement
        { $$ = NN(function_definition, .decl = $1, .stat = $2); }
    ;

%%

int toycen_error(YYLTYPE *locp, struct parser_state *ps, const char *s)
{
    fflush(stderr);
    fprintf(stderr, "%s\n", ps->lexstate.saveline);
    fprintf(stderr, "%*s\n%*s at line %d column %d at `%s'\n",
            locp->first_column, "^", locp->first_column, s,
            locp->first_line, locp->first_column,
            toycen_get_text(ps->scanner));

    return 0;
}

int parser_check_identifier(struct parser_state *ps, const char *s)
{
    if (hash_table_get(ps->types_hash, s))
        return TYPEDEF_NAME;

    return IDENTIFIER;
}

/// @todo scope properly
int parser_add_typename(struct parser_state *ps, scope_t *scope, const char *type)
{
    hash_table_put(ps->types_hash, type, (void*)1);
    (void)scope; // to avoid uused warning for now
    return 0;
}

/* vi:set ts=4 sw=4 et: */

