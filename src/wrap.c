#include "ast.h"

#ifndef WRAPPED
#error "Define WRAPPED"
#endif

static struct translation_unit *artificial = &
#include WRAPPED
;

int get_wrapped_ast(struct parser_state *ps, struct translation_unit **what, void *ud)
{
	*what = artificial;
	return 0;
}

int teardown_wrapped_ast(struct parser_state *ps, struct translation_unit **what, void *ud)
{
	return 0;
}

