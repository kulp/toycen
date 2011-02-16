CPP = gcc -E -x c -P
ifneq ($(DEBUG),)
DEFINES += DEBUG=$(DEBUG)
CFLAGS += -save-temps
endif

TARGET = toycen

PEDANTIC = $(if $(INHIBIT_PEDANTRY),,-pedantic)
WEXTRA = -Wextra

ARCHFLAGS = $(patsubst %,-arch %,$(ARCHS))

CPPFLAGS += -std=c99 $(patsubst %,-D%,$(DEFINES))
YFLAGS  += -dv
CFLAGS  += -Wall $(WEXTRA) -g -std=c99 $(PEDANTIC) $(ARCHFLAGS)
LFLAGS  +=
LDFLAGS += $(ARCHFLAGS)

OBJECTS = parser.o parser_primitives.o lexer.o main.o hash_table.o ast-ids.o

all: $(TARGET) t/test_hash_table t/test_hash_table_interface

toycen.o: CFLAGS += -Wno-unused-parameter
toycen: parser.o parser_primitives.o lexer.o hash_table.o ast-ids.o
parser.o: CFLAGS += -Wno-missing-field-initializers -D_XOPEN_SOURCE=600

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

ifeq ($(BUILD_PP),1)
CLEANFILES += tpp
tpp: hash_table.o pp_lexer.o
pp_lexer.o: DEFINES += PREPROCESSOR_LEXING _XOPEN_SOURCE=500
pp_lexer.o: WEXTRA =
pp_lexer.l: lexer.l.pre lexer.l.rules lexer.l.post
OBJECTS += pp_lexer.o
CLEANFILES += pp_lexer.l
.SECONDARY: pp_lexer.c
endif

lexer.o: DEFINES += _XOPEN_SOURCE=500

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

%.l: %.l.pre %.l.rules %.l.post
	cat $(filter %.l.pre,$^) blank.l $(filter %.l.rules,$^) blank.l $(filter %.l.post,$^) > $@

clean:
	-rm -f $(CLEANFILES) *.[od] $(TARGET)
