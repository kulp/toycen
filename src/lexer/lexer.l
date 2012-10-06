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

%top{
#define _XOPEN_SOURCE 600

#include "ast.h"
#include "parser_gen.h"
#include "parser.h"
}

%{
#include <ctype.h>
#include <stdio.h>

#include "debug.h"
#include "hash_table.h"

int parser_add_typename(struct parser_state *ps, scope_t *scope, const char *type);
static int check_identifier(yyscan_t yyscanner, char *);

%}

%option reentrant bison-bridge bison-locations stack
%option noyywrap never-interactive yylineno batch
%option extra-type="struct parser_state *"
%option prefix="toycen_"

%x comment

intsuffix                               ([uU][lL]?)|([lL][uU]?)
fracconst                               ([0-9]*\.[0-9]+)|([0-9]+\.)
exppart                                 [eE][-+]?[0-9]+
floatsuffix                             [fFlL]
chartext                                ([^'])|(\\.)
stringtext                              ([^"])|(\\.)
id                                      [a-zA-Z_][a-zA-Z_0-9]*

%%

"\n"                                    { }
[\t\f\v\r ]+                            { }

"//".*$                                 { /* c99-style comments */ }
"/*"                                    { yy_push_state(comment, yyscanner); }
<comment>"*/"                           { yy_pop_state(yyscanner); }

<*>"\\"[ \t]*"\n"                       { /* acceptable backslash continuation */ }
<*>"\\"                                 { return '\\'; /* unacceptable */ }

"{"                                     { return '{'; }
"<%"                                    { return '{'; }
"}"                                     { return '}'; }
"%>"                                    { return '}'; }
"["                                     { return '['; }
"<:"                                    { return '['; }
"]"                                     { return ']'; }
":>"                                    { return ']'; }
"("                                     { return '('; }
")"                                     { return ')'; }
";"                                     { return ';'; }
":"                                     { return ':'; }
"..."                                   { return ELLIPSIS; }
"?"                                     { return '?'; }
"."                                     { return '.'; }
"+"                                     { return '+'; }
"-"                                     { return '-'; }
"*"                                     { return '*'; }
"/"                                     { return '/'; }
"%"                                     { return '%'; }
"^"                                     { return '^'; }
"&"                                     { return '&'; }
"|"                                     { return '|'; }
"~"                                     { return '~'; }
"!"                                     { return '!'; }
"="                                     { return '='; }
"<"                                     { return '<'; }
">"                                     { return '>'; }

"+="                                    { return ADDEQ;      }
"-="                                    { return SUBEQ;      }
"*="                                    { return MULEQ;      }
"/="                                    { return DIVEQ;      }
"%="                                    { return MODEQ;      }
"^="                                    { return XOREQ;      }
"&="                                    { return ANDEQ;      }
"|="                                    { return OREQ;       }
"<<"                                    { return SL;         }
">>"                                    { return SR;         }
"<<="                                   { return SLEQ;       }
">>="                                   { return SREQ;       }
"=="                                    { return EQ;         }
"!="                                    { return NOTEQ;      }
"<="                                    { return LTEQ;       }
">="                                    { return GTEQ;       }
"&&"                                    { return ANDAND;     }
"||"                                    { return OROR;       }
"++"                                    { return PLUSPLUS;   }
"--"                                    { return MINUSMINUS; }
","                                     { return ',';        }
"->"                                    { return ARROW;      }

"auto"                                  { return AUTO;     }
"break"                                 { return BREAK;    }
"case"                                  { return CASE;     }
"char"                                  { return CHAR;     }
"const"                                 { return CONST;    }
"continue"                              { return CONTINUE; }
"default"                               { return DEFAULT;  }
"do"                                    { return DO;       }
"double"                                { return DOUBLE;   }
"else"                                  { return ELSE;     }
"enum"                                  { return ENUM;     }
"extern"                                { return EXTERN;   }
"float"                                 { return FLOAT;    }
"for"                                   { return FOR;      }
"goto"                                  { return GOTO;     }
"if"                                    { return IF;       }
"int"                                   { return INT;      }
"long"                                  { return LONG;     }
"register"                              { return REGISTER; }
"return"                                { return RETURN;   }
"short"                                 { return SHORT;    }
"signed"                                { return SIGNED;   }
"sizeof"                                { return SIZEOF;   }
"static"                                { return STATIC;   }
"struct"                                { return STRUCT;   }
"switch"                                { return SWITCH;   }
"typedef"                               { return TYPEDEF;  }
"union"                                 { return UNION;    }
"unsigned"                              { return UNSIGNED; }
"void"                                  { return VOID;     }
"volatile"                              { return VOLATILE; }
"while"                                 { return WHILE;    }

{id}                                    { return check_identifier(yyscanner, yytext); }

"0"[xX][0-9a-fA-F]+{intsuffix}?         { yylval->str = yytext; return INTEGER; }
"0"[0-7]+{intsuffix}?                   { yylval->str = yytext; return INTEGER; }
[0-9]+{intsuffix}?                      { yylval->str = yytext; return INTEGER; }

{fracconst}{exppart}?{floatsuffix}?     { return FLOATING;  }
[0-9]+{exppart}{floatsuffix}?           { return FLOATING;  }

"'"{chartext}*"'"                       { yylval->chr = yytext[0]; return CHARACTER; }
"L'"{chartext}*"'"                      { yylval->chr = yytext[0]; return CHARACTER; }

"\""{stringtext}*"\""                   { yylval->str = yytext; return STRING; }
"L\""{stringtext}*"\""                  { yylval->str = yytext; return STRING; }

.                                       { toycen_error(yylloc, yyextra, "unexpected character"); }

%%

static int check_identifier(yyscan_t yyscanner, char *s)
{
    YYSTYPE *lval = yyget_lval(yyscanner);
    struct parser_state *ps = yyget_extra(yyscanner);
    // XXX copy string instead of copying pointer
    lval->str = s;
    extern int parser_check_identifier(struct parser_state *ps, const char *s);
    return parser_check_identifier(ps, s);
}

int add_typename(yyscan_t yyscanner, scope_t *scope, const char *type)
{
    struct parser_state *ps = yyget_extra(yyscanner);
    return parser_add_typename(ps, scope, type);
}

/* vi:set ts=4 sw=4 et syntax=lex: */

