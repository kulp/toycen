.SECONDARY:
YFLAGS += -dv
CFLAGS += -g -std=c99
LFLAGS +=

SRC	= gram.y scan.l main.c
OBJ	= gram.o scan.o main.o

TARGET = ansi_c

$(TARGET): $(OBJ)
	cc $(CFLAGS) $(OBJ) -o $@

scan.o: y.tab.h

clean:
	-rm -f y.tab.h y.output *.o $(TARGET)
