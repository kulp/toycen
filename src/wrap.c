#include "ast.h"

#ifndef WRAPPED
#error "Define WRAPPED"
#endif

static struct translation_unit *artificial = &
#include WRAPPED
;

int get_wrapped_ast(void *ud, struct translation_unit **what)
{
	*what = artificial;
	return 0;
}

int teardown_wrapped_ast(void *ud, struct translation_unit **what)
{
	return 0;
}

