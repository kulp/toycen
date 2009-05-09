TARGET = toycen

PEDANTIC = $(if $(INHIBIT_PEDANTRY),,-pedantic)

YFLAGS += -dv
CFLAGS += -Wall -g -std=c99 $(PEDANTIC)
LFLAGS +=

SRC     = parser.y lexer.l main.c
OBJECTS = parser.o lexer.o main.o

all: $(TARGET) t/test_hash_table

$(TARGET): $(OBJECTS)
	$(LINK.c) $(OUTPUT_OPTION) $^

lexer.o: parser.h
parser.h: y.tab.h ; ln $< $@

t/%: CFLAGS += -I.
t/test_hash_table: hash_table.o

.SECONDARY: parser.c lexer.c
CLEANFILES += y.output parser.h y.tab.h parser.c lexer.c

ifeq ($(words $(filter clean,$(MAKECMDGOALS))),0)
-include $(notdir $(patsubst %.o,%.d,$(OBJECTS)))
endif

%.d: %.c ; $(COMPILE.c) -MG -M -MF $@ $<

clean:
	-rm -f $(CLEANFILES) *.[od] $(TARGET)
