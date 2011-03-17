CPP = gcc -E -x c -P
ifneq ($(DEBUG),)
DEFINES += DEBUG=$(DEBUG)
SAVE_TEMPS = 1
else
CFLAGS += -O3
endif

ifneq ($(NDEBUG),1)
CFLAGS += -g
endif

ifneq ($(SAVE_TEMPS),)
CFLAGS += -save-temps
endif

ifeq ($(NDEBUG),1)
DEFINES += NDEBUG
endif

vpath %.l	    lexer
vpath %.l.pre   lexer
vpath %.l.post  lexer
vpath %.l.rules lexer
vpath %.y  		parser
vpath %.c  		src
vpath %.h  		include include/housekeeping
vpath %.xi 		xi

INCLUDE += xi include include/housekeeping

TARGET = toycen

PEDANTIC = $(if $(INHIBIT_PEDANTRY),,-pedantic)
WEXTRA = -Wextra -Wno-unused

ARCHFLAGS = $(patsubst %,-arch %,$(ARCHS))

CPPFLAGS += -std=c99 $(patsubst %,-D%,$(DEFINES)) $(patsubst %,-I%,$(INCLUDE))
YFLAGS  += -dv
CFLAGS  += -Wall $(WEXTRA) -std=c99 $(PEDANTIC) $(ARCHFLAGS)
LFLAGS  +=
LDFLAGS += $(ARCHFLAGS)

OBJECTS = parser.o parser_primitives.o lexer.o main.o hash_table.o ast-ids.o ast-walk.o ast-formatters.o

WALKERS = demo graphviz test c
WALKBINS = $(addprefix ast-walk-,$(WALKERS))
CLEANFILES += $(WALKBINS)
OBJECTS += $(addsuffix .o,$(WALKBINS))
all: $(TARGET) t/test_hash_table t/test_hash_table_interface $(WALKBINS)

$(WALKBINS) : ast-walk-% : parser.o parser_primitives.o lexer.o hash_table.o ast-ids.o ast-walk.o ast-formatters.o

toycen.o: CFLAGS += -Wno-unused-parameter
toycen: parser.o parser_primitives.o lexer.o hash_table.o ast-ids.o ast-walk.o ast-formatters.o
parser.o: CFLAGS += -Wno-missing-field-initializers

CLEANFILES += ast-gen.h ast-gen2.h
ast-gen2.h: ast.xi
	$(CPP) $(CPPFLAGS) $^ | indent /dev/stdin $@

ast-gen.h: ast-gen2.h
	$(CPP) $(CPPFLAGS) -include ast-gen-pre.h $^ | indent /dev/stdin $@

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

ifeq ($(words $(filter clean,$(MAKECMDGOALS))),0)
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
	$(RM) -fr $(CLEANFILES) *.[odsi] *.dSYM $(TARGET)
