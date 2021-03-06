CPP = gcc -E -x c -P
ifneq ($(DEBUG),)
DEFINES += DEBUG=$(DEBUG)
SAVE_TEMPS ?= 1
else
CFLAGS += -O3
endif

ifneq ($(NDEBUG),1)
CFLAGS += -g
LDFLAGS += -g
endif

ifeq ($(SAVE_TEMPS),1)
CFLAGS += -save-temps
endif

ifeq ($(NDEBUG),1)
ifneq ($(ENABLE_LUA),1)
# Lua walk needs introspection
INHIBIT_INTROSPECTION = 1
endif
DEFINES += NDEBUG
endif

ENABLE_LUA ?= 1

INDENT ?= indent

INCLUDE += xi include include/housekeeping include/ast include/preprocessor include/util
SRC += src src/ast src/ast/walk src/compiler src/preprocessor src/util

vpath %.l	    lexer
vpath %.l.pre   lexer
vpath %.l.post  lexer
vpath %.l.rules lexer
vpath %.y  		parser
vpath %.c  		$(SRC) lua/
vpath %.h  		$(INCLUDE)
vpath %.xi 		xi

ifeq ($(INHIBIT_INTROSPECTION),1)
DEFINES += INHIBIT_INTROSPECTION
endif

TARGET = toycen

PEDANTIC = $(if $(INHIBIT_PEDANTRY),,-pedantic)
WEXTRA = -Wextra -Wno-unused

ARCHFLAGS = $(patsubst %,-arch %,$(ARCHS))

CPPFLAGS += -std=c99 $(patsubst %,-D'%',$(DEFINES)) $(patsubst %,-I%,$(INCLUDE))
YFLAGS  += -dv
CFLAGS  += -Wall $(WEXTRA) -std=c99 $(PEDANTIC) $(ARCHFLAGS)
LFLAGS  +=
LDFLAGS += $(ARCHFLAGS)

OBJECTS = parser.o parser_primitives.o lexer.o main.o hash_table.o ast-ids.o ast-formatters.o

ifneq ($(INHIBIT_INTROSPECTION),1)
WALKERS = demo graphviz test c lua_graphviz
WALKBINS = $(addprefix ast-walk-,$(WALKERS))
OBJECTS += ast-walk.o
endif

CLEANFILES += $(WALKBINS)
OBJECTS += $(addsuffix .o,$(WALKBINS))
all: $(TARGET) t/test_hash_table t/test_hash_table_interface $(WALKBINS)

ast-walk-lua_graphviz luash: LDLIBS += $(shell pkg-config --libs luajit) -lreadline
$(WALKBINS) : ast-walk-% : toycen.o ast-walk-%.o parser.o parser_primitives.o \
                           lexer.o hash_table.o ast-ids.o ast-walk.o \
                           ast-formatters.o | libljffifields.so
	$(LINK.c) $(LDFLAGS) -o $@ $^ $(LDLIBS)

toycen.o: CFLAGS += -Wno-unused-parameter
toycen: parser.o parser_primitives.o lexer.o hash_table.o ast-ids.o ast-formatters.o
parser.o: CFLAGS += -Wno-missing-field-initializers

CLEANFILES += ast-gen.h ast-gen2.h
ast-gen2.h: ast.xi
	$(CPP) $(CPPFLAGS) $^ | $(INDENT) > $@.$$$$ && mv $@.$$$$ $@ || rm $@.$$$$

ast-gen.h: ast-gen2.h
	$(CPP) $(CPPFLAGS) -include ast-gen-pre.h $^ | $(INDENT) > $@.$$$$ && mv $@.$$$$ $@ || rm $@.$$$$

wrap_ast_%.o: CFLAGS += -Wno-missing-field-initializers
wrap_ast_%.o: wrap.c %-ast.c
	$(COMPILE.c) -DWRAPPED='"$*-ast.c"' -o $@ $<

# use a separate object so that -save-temps doesn't wreck users of normal toycen.o
toycen,wrap.o: toycen.c
	$(COMPILE.c) -o $@ $^

# XXX this -DARTIFICIAL_AST can't really do anything with .o's !
wrap_ast_%: wrap_ast_%.o toycen,wrap.o parser.o parser_primitives.o lexer.o hash_table.o ast-ids.o ast-formatters.o
	$(LINK.c) -DARTIFICIAL_AST -o $@ $^ $(LDLIBS)

# Don't complain about unused yyunput()
lexer.o: CFLAGS += -Wno-unused-function
parser_internal.h: y.tab.h ; ln $< $@

CLEANFILES += t/test_hash_table t/test_hash_table_interface
t/%: CFLAGS += -I.
t/test_hash_table t/test_hash_table_interface: hash_table.o

CLEANFILES += basic-types.xi
# TODO fragile rule : depends on specific ordering of deps
basic-types.xi: ast-basics-pre.h ast.xi
	$(CPP) $(CPPFLAGS) -include $^ | tr ' ' '\012' | sort | uniq - $@

# GCC bug 47772 : http://gcc.gnu.org/bugzilla/show_bug.cgi?id=47772
ast-ids.o: CFLAGS += -Wno-missing-field-initializers

# Lua stuff
ifeq ($(ENABLE_LUA),1)
DEFINES += TOYCEN_ENABLE_LUA
# TODO make dependent on included files
CLEANFILES += ast-one.h
ast-one.h: ast.h ast-ids-priv.h ast-formatters.h
	cat $^ | $(CPP) $(CPPFLAGS) -o $@ -

all: libast.so
all: libljffifields.so
all: ast-one.h

%,fPIC.o: CFLAGS += -fPIC
%,fPIC.o: %.c
	$(COMPILE.c) -o $@ $^
CLEANFILES += libast.so
libast.so: ast-ids,fPIC.o ast-formatters,fPIC.o

CLEANFILES += libljffifields.so
libljffifields.so: fields,fPIC.o
libljffifields.so: LDLIBS   += $(shell pkg-config --libs luajit)
libljffifields.so: CPPFLAGS += $(shell pkg-config --cflags-only-I luajit)
libljffifields.so: INCLUDE  += 3rdparty/luajit-2.0/src
libljffifields.so: CFLAGS   += $(shell pkg-config --cflags-only-other luajit)
# some luajit headers need [?] gcc
libljffifields.so: CFLAGS += -std=gnu99
libljffifields.so: CPPFLAGS += -std=gnu99

%.so:
	$(LINK.c) -shared -o $@ $^ $(LDLIBS)

ifeq ($(shell uname -s),Darwin)
ast-walk-lua% wrap_ast_% toycen luash: LDFLAGS += -Wl,-pagezero_size,10000 -Wl,-image_base,100000000
endif

endif

ifeq ($(BUILD_PP),1)
CLEANFILES += tpp
tpp: hash_table.o pp_lexer.o
pp_lexer.o: DEFINES += PREPROCESSOR_LEXING
pp_lexer.o: WEXTRA =
pp_lexer.l: lexer.l.pre lexer.l.rules lexer.l.post
OBJECTS += pp_lexer.o
CLEANFILES += pp_lexer.l
.SECONDARY: pp_lexer.c
endif

.SECONDARY: parser.c lexer.c
CLEANFILES += y.output parser_internal.h y.tab.h parser.c lexer.l

ifeq ($(words $(filter clean clobber,$(MAKECMDGOALS))),0)
-include $(notdir $(patsubst %.o,%.d,$(OBJECTS)))
endif

%.d: %.c
	@set -e; rm -f $@; \
	$(CC) -MG -M $(CPPFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

CLEANFILES += lexer.c
%.l: %.l.pre blank.l %.l.rules %.l.post
	cat $(filter %.l.pre,$^) $(filter %blank.l,$^) $(filter %.l.rules,$^) $(filter %blank.l,$^) $(filter %.l.post,$^) > $@

clean:
	$(RM) -r $(CLEANFILES) *.[odsi] *.dSYM $(TARGET)

clobber: clean
	$(RM) -r $(CLOBBERFILES)
