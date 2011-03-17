#ifndef LEXER_H_E571EB9E02B6F579090D900B1C254D9C
#define LEXER_H_E571EB9E02B6F579090D900B1C254D9C

#define TAB_WIDTH 8

/// @todo define scope appropriately, and somewhere else
typedef int scope_t;

void lexer_setup();
void lexer_teardown();

void add_typename(scope_t *scope, const char *type);

#endif

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
