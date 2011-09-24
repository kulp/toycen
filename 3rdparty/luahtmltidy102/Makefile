OBJ     = htmltidy.o tdoc.o tnode.o support.o tconst.o
CFLAGS += -I/usr/include/tidy -Wall -g -O0
CFLAGS += $(shell pkg-config --cflags luajit)
LDLIBS += $(shell pkg-config --libs luajit)

all: htmltidy.so

clean:
	rm *.o
	rm *.so

htmltidy.so: $(OBJ)
	$(CC) $(CFLAGS) $(LDFLAGS) -rdynamic -shared -ltidy -W1,-soname,htmltidy.so.1 -o htmltidy.so $(OBJ) $(LDLIBS)


