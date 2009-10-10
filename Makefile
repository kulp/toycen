ifneq ($(DEBUG),)
DEFINES += DEBUG=$(DEBUG)
endif

TARGET = toycen

PEDANTIC = $(if $(INHIBIT_PEDANTRY),,-pedantic)

YFLAGS += -dv
CFLAGS += -Wall -g -std=c99 $(PEDANTIC) $(patsubst %,-D%,$(DEFINES))
LFLAGS +=

OBJECTS = parser.o lexer.o main.o hash_table.o pp_lexer.o

CLEANFILES += tpp
all: tpp $(TARGET) t/test_hash_table t/test_hash_table_interface

toycen: parser.o lexer.o hash_table.o

# Don't complain about unused yyunput()
lexer.o: CFLAGS += -Wno-unused-function
parser_internal.h: y.tab.h ; ln $< $@

CLEANFILES += t/test_hash_table t/test_hash_table_interface
t/%: CFLAGS += -I.
t/test_hash_table t/test_hash_table_interface: hash_table.o

tpp: hash_table.o pp_lexer.o
pp_lexer.o: DEFINES += PREPROCESSOR_LEXING _XOPEN_SOURCE=500
pp_lexer.l: lexer.l.pre lexer.l.rules lexer.l.post

lexer.o: DEFINES += _XOPEN_SOURCE=500

.SECONDARY: parser.c lexer.c pp_lexer.c
CLEANFILES += y.output parser_internal.h y.tab.h parser.c pp_lexer.l lexer.l

ifeq ($(words $(filter clean,$(MAKECMDGOALS))),0)
-include $(notdir $(patsubst %.o,%.d,$(OBJECTS)))
endif

%.d: %.c ; $(COMPILE.c) -MG -M -MF $@ $<

%.l: %.l.pre %.l.rules %.l.post
	cat $(filter %.l.pre,$^) blank.l $(filter %.l.rules,$^) blank.l $(filter %.l.post,$^) > $@

clean:
	-rm -f $(CLEANFILES) *.[od] $(TARGET)
