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
    #include "parser.h"
    #include "parser_primitives.h"
    #include "lexer.h"

    #include <assert.h>
    #include <stdio.h>
    #include <stdarg.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdint.h>

    extern int lineno;
%}

%union {
    long i;
    char *str;
    char chr;
    struct unary_expression *ue;
    struct postfix_expression *pe;
    struct cast_expression *ce;
    enum unary_operator uo;
    struct type_name *tn;
    struct type_specifier *ts;
    struct aggregate_specifier *as;
    struct enum_specifier *enum_spec;
    struct identifier *id;
    struct aggregate_declaration_list *al;
    struct aggregate_declaration *ai;
    struct enumerator_list *el;
    struct enumerator *ei;
    struct constant_expression *const_expr;
    struct conditional_expression *cond_expr;
    struct logical_or_expression *l_or_expr;
    struct logical_and_expression *l_and_expr;
    struct expression *expr;
    struct inclusive_or_expression *i_or_expr;
    struct exclusive_or_expression *e_or_expr;
    struct and_expression *and_expr;
    struct equality_expression *eq_expr;
    struct relational_expression *rel_expr;
    struct shift_expression *shift_expr;
    struct additive_expression *add_expr;
    struct primary_expression *pri_expr;
    struct multiplicative_expression *mult_expr;
    struct assignment_expression *assn_expr;
    enum assignment_operator assn_op;
    struct specifier_qualifier_list *sq_list;
    struct abstract_declarator *abs_decl;
    struct aggregate_declarator_list *sdecl_list;
    struct aggregate_declarator *sdecl;
}

%type <ue> unary_expression
%type <pe> postfix_expression
%type <uo> unary_operator
%type <ce> cast_expression
%type <tn> type_name
%type <ts> type_specifier
%type <as> struct_or_union_specifier
%type <enum_spec> enum_specifier
%type <id> identifier
%type <al> struct_declaration_list
%type <i>  struct_or_union
%type <ai> struct_declaration
%type <el> enumerator_list
%type <ei> enumerator
%type <const_expr> constant_expression;
%type <cond_expr> conditional_expression;
%type <l_or_expr> logical_or_expression;
%type <l_and_expr> logical_and_expression;
%type <expr> expression;
%type <i_or_expr> inclusive_or_expression;
%type <e_or_expr> exclusive_or_expression;
%type <and_expr> and_expression;
%type <eq_expr> equality_expression;
%type <rel_expr> relational_expression;
%type <shift_expr> shift_expression;
%type <add_expr> additive_expression;
%type <pri_expr> primary_expression;
%type <mult_expr> multiplicative_expression;
%type <assn_expr> assignment_expression;
%type <assn_op> assignment_operator;
%type <sq_list> specifier_qualifier_list;
%type <abs_decl> abstract_declarator;
%type <sdecl_list> struct_declarator_list;
%type <sdecl> struct_declarator;


%token IDENTIFIER TYPEDEF_NAME INTEGER FLOATING CHARACTER STRING

%token ELLIPSIS ADDEQ SUBEQ MULEQ DIVEQ MODEQ XOREQ ANDEQ OREQ SL SR
%token SLEQ SREQ EQ NOTEQ LTEQ GTEQ ANDAND OROR PLUSPLUS MINUSMINUS ARROW

%token AUTO BREAK CASE CHAR CONST CONTINUE DEFAULT DO DOUBLE ELSE ENUM
%token EXTERN FLOAT FOR GOTO IF INT LONG REGISTER RETURN SHORT SIGNED SIZEOF
%token STATIC SWITCH TYPEDEF UNSIGNED VOID VOLATILE WHILE

%token <chr> '&' '*' '+' '-' '~' '!' '/' '%'
%token <i> STRUCT UNION

%start translation_unit

%%

/* B.2.1 Expressions. */

primary_expression
    : identifier { $$ = NN(primary_expression, .type = PRET_IDENTIFIER, .me.id = $1); }
    | INTEGER    { $$ = NN(primary_expression, .type = PRET_INTEGER   , .me.i  = /* TODO */NULL); }
    | CHARACTER  { $$ = NN(primary_expression, .type = PRET_CHARACTER , .me.c  = /* TODO */NULL); }
    | FLOATING   { $$ = NN(primary_expression, .type = PRET_FLOATING  , .me.f  = /* TODO */NULL); }
    | STRING     { $$ = NN(primary_expression, .type = PRET_STRING    , .me.s  = /* TODO */NULL); }
    | '(' expression ')' { $$ = NN(primary_expression, .type = PRET_PARENTHESIZED, .me.e = $2); }
    ;

identifier
    : IDENTIFIER { $$ = NN(identifier, .name = strdup(yylval.str)); }
    ;

postfix_expression
    : primary_expression { $$ = UN(postfix_expression, $1, .type = PET_PRIMARY); }
    | postfix_expression '[' expression ']'
    | postfix_expression '(' argument_expression_list ')'
    | postfix_expression '(' ')'
    | postfix_expression '.' identifier
    | postfix_expression ARROW identifier
    | postfix_expression PLUSPLUS
    | postfix_expression MINUSMINUS
    ;

argument_expression_list
    : assignment_expression
    | argument_expression_list ',' assignment_expression
    ;

unary_expression
    : postfix_expression {
            $$ = UN(unary_expression, $1, .type = UET_POSTFIX);
        }
    | PLUSPLUS unary_expression {
        /// @todo .me
            $$ = NN(unary_expression, .type = UET_PREINCREMENT, .val.ue = $<ue>2);
        }
    | MINUSMINUS unary_expression {
        /// @todo .me
            $$ = NN(unary_expression, .type = UET_PREDECREMENT, .val.ue = $<ue>2);
        }
    | unary_operator cast_expression {
            $$ = NN(unary_expression, .type = UET_UNARY_OP,
                                      .val.ce = { .uo = $1, .ce = $2 }
                                      );
        }
    | SIZEOF unary_expression {
            $$ = NN(unary_expression, .type = UET_SIZEOF_EXPR, .val.ue = $<ue>2);
        }
    | SIZEOF '(' type_name ')' {
            $$ = NN(unary_expression, .type = UET_SIZEOF_TYPE, .val.tn = $3);
        }
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
    : unary_expression { $$ = UN(cast_expression, $1, .tn = NULL); }
    | '(' type_name ')' cast_expression { $$ = NN(cast_expression, .tn = $2, .ce = $4); }
    ;

multiplicative_expression
    : cast_expression
        { $$ = UN(multiplicative_expression, $1, .left = NULL); }
    | multiplicative_expression '*' cast_expression
        { $$ = UN(multiplicative_expression, $3, .left = $1, .op = $2); }
    | multiplicative_expression '/' cast_expression
        { $$ = UN(multiplicative_expression, $3, .left = $1, .op = $2); }
    | multiplicative_expression '%' cast_expression
        { $$ = UN(multiplicative_expression, $3, .left = $1, .op = $2); }
    ;

additive_expression
    : multiplicative_expression
        { $$ = UN(additive_expression, $1, .left = NULL); }
    | additive_expression '+' multiplicative_expression
        { $$ = UN(additive_expression, $3, .left = $1, .op = $2); }
    | additive_expression '-' multiplicative_expression
        { $$ = UN(additive_expression, $3, .left = $1, .op = $2); }
    ;

shift_expression
    : additive_expression
        { $$ = UN(shift_expression, $1, .left = NULL); }
    | shift_expression SL additive_expression
        { $$ = UN(shift_expression, $3, .left = $1, .op = SO_LSH); }
    | shift_expression SR additive_expression
        { $$ = UN(shift_expression, $3, .left = $1, .op = SO_RSH); }
    ;

relational_expression
    : shift_expression
        { $$ = UN(relational_expression, $1, .left = NULL); }
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
    : equality_expression { $$ = UN(and_expression, $1, .left = NULL); }
    | and_expression '&' equality_expression
        { $$ = UN(and_expression, $3, .left = $1); }
    ;

exclusive_or_expression
    : and_expression { $$ = UN(exclusive_or_expression, $1, .left = NULL); }
    | exclusive_or_expression '^' and_expression
        { $$ = UN(exclusive_or_expression, $3, .left = $1); }
    ;

inclusive_or_expression
    : exclusive_or_expression { $$ = UN(inclusive_or_expression, $1, .left = NULL); }
    | inclusive_or_expression '|' exclusive_or_expression
        { $$ = UN(inclusive_or_expression, $3, .left = $1); }
    ;

logical_and_expression
    : inclusive_or_expression { $$ = UN(logical_and_expression, $1, .left = NULL); }
    | logical_and_expression ANDAND inclusive_or_expression
        { $$ = UN(logical_and_expression, $3, .left = $1); }
    ;

logical_or_expression
    : logical_and_expression { $$ = UN(logical_or_expression, $1, .left = NULL); }
    | logical_or_expression OROR logical_and_expression
        { $$ = UN(logical_or_expression, $3, .left = $1); }
    ;

conditional_expression
    : logical_or_expression { $$ = UN(conditional_expression, $1, .is_ternary = false); }
    | logical_or_expression '?' expression ':' conditional_expression {
            $$ = UN(conditional_expression, $1, .is_ternary = true, .if_expr = $3, .else_expr = $5); }
    ;

assignment_expression
    : conditional_expression
        { $$ = UN(assignment_expression, $1, .has_op = false); }
    | unary_expression assignment_operator assignment_expression
        { $$ = NN(assignment_expression, .val.assn = { .left = $1, .op = $2, .right = $3 }); }
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
        { $$ = UN(expression, $1, .left = $1); }
    ;

constant_expression
    : conditional_expression { $$ = UN(constant_expression, $1, .dummy = 0); }
    ;

declaration
    : declaration_specifiers init_declarator_list ';'
    | declaration_specifiers ';'
    ;

declaration_specifiers
    : storage_class_specifier declaration_specifiers
    | storage_class_specifier
    | type_specifier declaration_specifiers
    | type_specifier
    | type_qualifier declaration_specifiers
    | type_qualifier
    ;

init_declarator_list
    : init_declarator
    | init_declarator_list ',' init_declarator
    ;

init_declarator
    : declarator
    | declarator '=' initializer
    ;

storage_class_specifier
    : TYPEDEF
    | EXTERN
    | STATIC
    | AUTO
    | REGISTER
    ;

type_specifier
    : VOID     { $$ = NN(type_specifier, .type = TS_VOID    ); }
    | CHAR     { $$ = NN(type_specifier, .type = TS_CHAR    ); }
    | SHORT    { $$ = NN(type_specifier, .type = TS_SHORT   ); }
    | INT      { $$ = NN(type_specifier, .type = TS_INT     ); }
    | LONG     { $$ = NN(type_specifier, .type = TS_LONG    ); }
    | FLOAT    { $$ = NN(type_specifier, .type = TS_FLOAT   ); }
    | DOUBLE   { $$ = NN(type_specifier, .type = TS_DOUBLE  ); }
    | SIGNED   { $$ = NN(type_specifier, .type = TS_SIGNED  ); }
    | UNSIGNED { $$ = NN(type_specifier, .type = TS_UNSIGNED); }
    | struct_or_union_specifier {
            $$ = NN(type_specifier, .type = TS_STRUCT_OR_UNION_SPEC, .val.as = $1);
        }
    | enum_specifier {
            $$ = NN(type_specifier, .type = TS_ENUM_SPEC, .val.es = $1);
        }
    | TYPEDEF_NAME { $$ = NN(type_specifier, .type = TS_TYPEDEF_NAME, .val.tn = NULL /* TODO str2type_name(yylval.str)*/); }
    ;

struct_or_union_specifier
    : struct_or_union identifier '{' struct_declaration_list '}' {
            /// @todo rename struct_or_union_* to agreggate_specifier
            $$ = NN(aggregate_specifier, .type = ($1 == STRUCT ? AT_STRUCT : AT_UNION),
                                         .has_id = true,
                                         .id = $2,
                                         .has_list = true,
                                         .list = $4,
                                         );
        }
    | struct_or_union '{' struct_declaration_list '}' {
            $$ = NN(aggregate_specifier, .type = ($1 == STRUCT ? AT_STRUCT : AT_UNION),
                                         .has_id = false,
                                         .has_list = true,
                                         .list = $3,
                                         );
        }
    | struct_or_union identifier {
            $$ = NN(aggregate_specifier, .type = ($1 == STRUCT ? AT_STRUCT : AT_UNION),
                                         .has_id = true,
                                         .id = $2,
                                         .has_list = false,
                                         );
        }
    ;

struct_or_union
    : STRUCT
    | UNION
    ;

struct_declaration_list
    : struct_declaration { $$ = NN(aggregate_declaration_list, .me = $1); }
    | struct_declaration_list struct_declaration { $$ = NN(aggregate_declaration_list, .me = $2, .prev = $1); }
    ;

struct_declaration
    : specifier_qualifier_list struct_declarator_list ';'
        { $$ = NN(aggregate_declaration, .sq = $1, .decl = $2); }
    ;

specifier_qualifier_list
    : type_specifier specifier_qualifier_list
    | type_specifier
    | type_qualifier specifier_qualifier_list
    | type_qualifier
    ;

struct_declarator_list
    : struct_declarator
        { $$ = UN(aggregate_declarator_list, $1, .prev = NULL); }
    | struct_declarator_list ',' struct_declarator
        { $$ = UN(aggregate_declarator_list, $3, .prev = $1); }
    ;

struct_declarator
    : declarator
    |  ':' constant_expression
    | declarator ':' constant_expression
    ;

enum_specifier
    : ENUM identifier '{' enumerator_list '}' {
            $$ = NN(enum_specifier, .has_id = true,
                                    .id = $2,
                                    .has_list = true,
                                    .list = $4,
                                    );
        }
    | ENUM '{' enumerator_list '}' {
            $$ = NN(enum_specifier, .has_id = false,
                                    .has_list = true,
                                    .list = $3,
                                    );
        }
    | ENUM identifier {
            $$ = NN(enum_specifier, .has_id = true,
                                    .id = $2,
                                    .has_list = false,
                                    );
        }
    ;

enumerator_list
    : enumerator { $$ = NN(enumerator_list, .me = $1); }
    | enumerator_list ',' enumerator { $$ = NN(enumerator_list, .me = $3, .prev = $1); }
    ;

enumerator
    : identifier { $$ = NN(enumerator, .id = $1, .val = NULL); }
    | identifier '=' constant_expression { $$ = NN(enumerator, .id = $1, .val = $3); }
    ;

type_qualifier
    : CONST
    | VOLATILE
    ;

declarator
    : pointer direct_declarator
    | direct_declarator
    ;

direct_declarator
    : identifier
    | '(' declarator ')'
    | direct_declarator '[' constant_expression ']'
    | direct_declarator '[' ']'
    | direct_declarator '(' parameter_type_list ')'
    | direct_declarator '(' identifier_list ')'
    | direct_declarator '(' ')'
    ;

pointer
    : '*' type_qualifier_list
    | '*'
    | '*' type_qualifier_list pointer
    | '*' pointer
    ;

type_qualifier_list
    : type_qualifier
    | type_qualifier_list type_qualifier
    ;

parameter_type_list
    : parameter_list
    | parameter_list ',' ELLIPSIS
    ;

parameter_list
    : parameter_declaration
    | parameter_list ',' parameter_declaration
    ;

parameter_declaration
    : declaration_specifiers declarator
    | declaration_specifiers abstract_declarator
    | declaration_specifiers
    ;

identifier_list
    : identifier
    | identifier_list ',' identifier
    ;

type_name
    : specifier_qualifier_list
        { $$ = NN(type_name, .list = $1, .decl = NULL); }
    | specifier_qualifier_list abstract_declarator
        { $$ = NN(type_name, .list = $1, .decl = $2); }
    ;

abstract_declarator
    : pointer
    | direct_abstract_declarator
    | pointer direct_abstract_declarator
    ;

direct_abstract_declarator
    : '(' abstract_declarator ')'
    | '[' ']'
    | '[' constant_expression ']'
    | direct_abstract_declarator '[' ']'
    | direct_abstract_declarator '[' constant_expression ']'
    | '(' ')'
    | '(' parameter_type_list ')'
    | direct_abstract_declarator '(' ')'
    | direct_abstract_declarator '(' parameter_type_list ')'
    ;

initializer
    : assignment_expression
    | '{' initializer_list '}'
    | '{' initializer_list ',' '}'
    ;

initializer_list
    : initializer
    | initializer_list ',' initializer
    ;

/* B.2.3 Statements. */

statement
    : labeled_statement
    | compound_statement
    | expression_statement
    | selection_statement
    | iteration_statement
    | jump_statement
    ;

labeled_statement
    : identifier ':' statement
    | CASE constant_expression ':' statement
    | DEFAULT ':' statement
    ;

compound_statement
    : '{' '}'
    | '{' statement_list '}'
    | '{' declaration_list '}'
    | '{' declaration_list statement_list '}'
    ;

declaration_list
    : declaration
    | declaration_list declaration
    ;

statement_list
    : statement
    | statement_list statement
    ;

expression_statement
    : ';'
    | expression ';'
    ;

selection_statement
    : IF '(' expression ')' statement
    | IF '(' expression ')' statement ELSE statement
    | SWITCH '(' expression ')' statement
    ;

iteration_statement
    : WHILE '(' expression ')' statement
    | DO statement WHILE '(' expression ')' ';'
    | FOR '(' ';' ';' ')' statement
    | FOR '(' expression ';' ';' ')' statement
    | FOR '(' ';' expression ';' ')' statement
    | FOR '(' expression ';' expression ';' ')' statement
    | FOR '(' ';' ';' expression ')' statement
    | FOR '(' expression ';' ';' expression ')' statement
    | FOR '(' ';' expression ';' expression ')' statement
    | FOR '(' expression ';' expression ';' expression ')' statement
    ;

jump_statement
    : GOTO identifier ';'
    | CONTINUE ';'
    | BREAK ';'
    | RETURN ';'
    | RETURN expression ';'
    ;

/* B.2.4 External definitions. */

translation_unit
    : external_declaration
    | translation_unit external_declaration
    ;

external_declaration
    : function_definition
    | declaration
    ;

function_definition
    : declaration_specifiers declarator declaration_list compound_statement
    | declaration_specifiers declarator compound_statement
    | declarator declaration_list compound_statement
    | declarator compound_statement
    ;

%%

extern int column;

void yyerror(const char *s) {
    fflush(stdout);
    printf("Error on line %d\n", lineno);
    printf("%*s\n%*s\n", column, "^", column, s);
}

/* vi:set ts=4 sw=4 et syntax=yacc: */

