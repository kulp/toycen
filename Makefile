ifneq ($(DEBUG),)
DEFINES += DEBUG=$(DEBUG)
endif

TARGET = toycen

PEDANTIC = $(if $(INHIBIT_PEDANTRY),,-pedantic)

YFLAGS += -dv
CFLAGS += -Wall -g -std=c99 $(PEDANTIC) $(patsubst %,-D%,$(DEFINES))
LFLAGS +=

OBJECTS = parser.o lexer.o main.o hash_table.o

all: $(TARGET) t/test_hash_table t/test_hash_table_interface

$(TARGET): $(OBJECTS)
	$(LINK.c) $(OUTPUT_OPTION) $^

lexer.o: parser.h
# Don't complain about unused yyunput()
lexer.o: CFLAGS += -Wno-unused-function
parser.h: y.tab.h ; ln $< $@

t/%: CFLAGS += -I.
t/test_hash_table: hash_table.o
t/test_hash_table_interface: hash_table.o

.SECONDARY: parser.c lexer.c
CLEANFILES += y.output parser.h y.tab.h parser.c lexer.c

ifeq ($(words $(filter clean,$(MAKECMDGOALS))),0)
-include $(notdir $(patsubst %.o,%.d,$(OBJECTS)))
endif

%.d: %.c ; $(COMPILE.c) -MG -M -MF $@ $<

clean:
	-rm -f $(CLEANFILES) *.[od] $(TARGET)
