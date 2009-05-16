/*      $Id: lexer.l,v 1.3 1997/11/22 18:41:23 sandro Exp $     */

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
 * ISO C lexical analyzer.
 *
 * Based on the ISO C 9899:1990 international standard.
 */

%{
    #include <ctype.h>
    #include <stdio.h>

    #include "debug.h"
    #include "parser.h"
    #include "hash_table.h"
    #include "lexer.h"

    int lineno;

    static hash_table_t* types_hash;

    /// Tracks columns for error reporting
    static void c();

    static int yywrap();
    static void skip_comment();
    static int check_identifier(const char *);
%}

intsuffix                               ([uU][lL]?)|([lL][uU]?)
fracconst                               ([0-9]*\.[0-9]+)|([0-9]+\.)
exppart                                 [eE][-+]?[0-9]+
floatsuffix                             [fFlL]
chartext                                ([^'])|(\\.)
stringtext                              ([^"])|(\\.)

%%

"\n"                                    { c(); lineno++; }
[\t\f\v\r ]+                            { c(); /* Ignore whitespace. */ }

"/*"                                    { skip_comment(); }

"{"                                     { c(); return '{'; }
"<%"                                    { c(); return '{'; }
"}"                                     { c(); return '}'; }
"%>"                                    { c(); return '}'; }
"["                                     { c(); return '['; }
"<:"                                    { c(); return '['; }
"]"                                     { c(); return ']'; }
":>"                                    { c(); return ']'; }
"("                                     { c(); return '('; }
")"                                     { c(); return ')'; }
";"                                     { c(); return ';'; }
":"                                     { c(); return ':'; }
"..."                                   { c(); return ELLIPSIS; }
"?"                                     { c(); return '?'; }
"."                                     { c(); return '.'; }
"+"                                     { c(); return '+'; }
"-"                                     { c(); return '-'; }
"*"                                     { c(); return '*'; }
"/"                                     { c(); return '/'; }
"%"                                     { c(); return '%'; }
"^"                                     { c(); return '^'; }
"&"                                     { c(); return '&'; }
"|"                                     { c(); return '|'; }
"~"                                     { c(); return '~'; }
"!"                                     { c(); return '!'; }
"="                                     { c(); return '='; }
"<"                                     { c(); return '<'; }
">"                                     { c(); return '>'; }

"+="                                    { c(); return ADDEQ;      } 
"-="                                    { c(); return SUBEQ;      } 
"*="                                    { c(); return MULEQ;      } 
"/="                                    { c(); return DIVEQ;      } 
"%="                                    { c(); return MODEQ;      } 
"^="                                    { c(); return XOREQ;      } 
"&="                                    { c(); return ANDEQ;      } 
"|="                                    { c(); return OREQ;       } 
"<<"                                    { c(); return SL;         } 
">>"                                    { c(); return SR;         } 
"<<="                                   { c(); return SLEQ;       } 
">>="                                   { c(); return SREQ;       } 
"=="                                    { c(); return EQ;         } 
"!="                                    { c(); return NOTEQ;      } 
"<="                                    { c(); return LTEQ;       } 
">="                                    { c(); return GTEQ;       } 
"&&"                                    { c(); return ANDAND;     } 
"||"                                    { c(); return OROR;       } 
"++"                                    { c(); return PLUSPLUS;   } 
"--"                                    { c(); return MINUSMINUS; } 
","                                     { c(); return ',';        } 
"->"                                    { c(); return ARROW;      } 

"auto"                                  { c(); return AUTO;     } 
"break"                                 { c(); return BREAK;    } 
"case"                                  { c(); return CASE;     } 
"char"                                  { c(); return CHAR;     } 
"const"                                 { c(); return CONST;    } 
"continue"                              { c(); return CONTINUE; } 
"default"                               { c(); return DEFAULT;  } 
"do"                                    { c(); return DO;       } 
"double"                                { c(); return DOUBLE;   } 
"else"                                  { c(); return ELSE;     } 
"enum"                                  { c(); return ENUM;     } 
"extern"                                { c(); return EXTERN;   } 
"float"                                 { c(); return FLOAT;    } 
"for"                                   { c(); return FOR;      } 
"goto"                                  { c(); return GOTO;     } 
"if"                                    { c(); return IF;       } 
"int"                                   { c(); return INT;      } 
"long"                                  { c(); return LONG;     } 
"register"                              { c(); return REGISTER; } 
"return"                                { c(); return RETURN;   } 
"short"                                 { c(); return SHORT;    } 
"signed"                                { c(); return SIGNED;   } 
"sizeof"                                { c(); return SIZEOF;   } 
"static"                                { c(); return STATIC;   } 
"struct"                                { c(); return STRUCT;   } 
"switch"                                { c(); return SWITCH;   } 
"typedef"                               { c(); return TYPEDEF;  } 
"union"                                 { c(); return UNION;    } 
"unsigned"                              { c(); return UNSIGNED; } 
"void"                                  { c(); return VOID;     } 
"volatile"                              { c(); return VOLATILE; } 
"while"                                 { c(); return WHILE;    } 

[a-zA-Z_][a-zA-Z_0-9]*                  { c(); return check_identifier(yytext); }

"0"[xX][0-9a-fA-F]+{intsuffix}?         { c(); return INTEGER;   } 
"0"[0-7]+{intsuffix}?                   { c(); return INTEGER;   } 
[0-9]+{intsuffix}?                      { c(); return INTEGER;   } 

{fracconst}{exppart}?{floatsuffix}?     { c(); return FLOATING;  } 
[0-9]+{exppart}{floatsuffix}?           { c(); return FLOATING;  } 

"'"{chartext}*"'"                       { c(); return CHARACTER; } 
"L'"{chartext}*"'"                      { c(); return CHARACTER; } 

"\""{stringtext}*"\""                   { c(); return STRING;    } 
"L\""{stringtext}*"\""                  { c(); return STRING;    } 

.                                       { c(); fprintf(stderr, "%d: unexpected character `%c'\n", lineno, yytext[0]); }

%%

int column;

static int yywrap()
{
    return 1;
}

static void c()
{
    for (int i = 0; yytext[i]; i++)
        if (yytext[i] == '\n')
            column = 0;
        else if (yytext[i] == '\t')
            column += TAB_WIDTH - (column % TAB_WIDTH);
        else
            column++;
}

/*
 * We use this routine instead a lex pattern because we don't need
 * to save the matched comment in the `yytext' buffer.
 */
static void skip_comment()
{
    int c1, c2;

    c1 = input();
    c2 = input();

    while (c2 != EOF && !(c1 == '*' && c2 == '/')) {
        if (c1 == '\n')
            ++lineno;
        c1 = c2;
        c2 = input();
    }
}

static int check_identifier(const char *s)
{
    if (hash_table_get(types_hash, s))
        return TYPEDEF_NAME;

    return IDENTIFIER;
}

void lexer_setup()
{
    _debug(2, "%s", __func__);

    if (!types_hash)
        types_hash = hash_table_create(0);
}

void lexer_teardown()
{
    _debug(2, "%s", __func__);
    hash_table_destroy(types_hash);
    types_hash = NULL;
}


/* vi:set ts=4 sw=4 et: */
