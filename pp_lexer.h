//------------------------------------------------------------------------------
// Type and macro definitions
//------------------------------------------------------------------------------

/// horizontal space characters
#define HSPACE " \t"
/// vertical space characters
#define VSPACE "\n\v"
/// all space characters
#define ASPACE HSPACE VSPACE

typedef enum keyword {
    K_DEFINE=1, K_UNDEF, K_IF, K_IFDEF, K_IFNDEF, K_ELSE, K_ELIF, K_ENDIF, K_INCLUDE
} keyword_t;

/// @todo this needs to be treated as a one in some cases
static const char DEFAULT_DEFINITION[] = "";

void  add_define(const char *key, const char *val);
void* get_define(const char *key);
void  del_define(const char *key);

int switch_to_input_file(const char *s);

/* vi:set ts=4 sw=4 et syntax=c.doxygen: */
