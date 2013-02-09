CFLAGS		+= $(shell sdl-config --cflags) -I. -DINLINE=
LDFLAGS		+= -L.
LIBS		+= $(shell sdl-config --libs)

LIB_NAME	= libSDL_flic
LIB_SHARED	= $(LIB_NAME).so
LIB_STATIC	= $(LIB_NAME).a
BIN			= playflic
TARGETS		= $(LIB_SHARED) $(LIB_STATIC) $(BIN)

BINDIR		= /usr/bin
LIBDIR		= /usr/lib
INCDIR		= /usr/include

all: $(TARGETS)

SDL_flic.lo: SDL_flic.c
	$(CC) $(CFLAGS) -fPIC -o $@ -c $<
$(LIB_SHARED): SDL_flic.lo
	$(CC) $(CFLAGS) $(LDFLAGS) SDL_flic.lo -shared -Wl,-soname,$@ -o $@.1.0.0 $(LIBS)
	ln -s $@.1.0.0 $@.1
	ln -s $@.1 $@

$(LIB_STATIC): SDL_flic.o
	$(AR) rcs $@ $<

$(BIN): $(LIB_SHARED) playflic.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ playflic.o -lSDL_flic $(LIBS)

install: $(TARGETS)
	install -d -m 755 $(DESTDIR)/$(LIBDIR)
	install -m 644 $(LIB_STATIC) $(DESTDIR)/$(LIBDIR)
	install -m 755 $(LIB_SHARED).1.0.0 $(DESTDIR)/$(LIBDIR)
	ln -s $(LIB_SHARED).1.0.0 $(DESTDIR)/$(LIBDIR)/$(LIB_SHARED).1
	ln -s $(LIB_SHARED).1 $(DESTDIR)/$(LIBDIR)/$(LIB_SHARED)

	install -d -m 755 $(DESTDIR)/$(BINDIR)
	install -m 755 $(BIN) $(DESTDIR)/$(BINDIR)

	install -d -m 755 $(DESTDIR)/$(INCDIR)
	install -m 644 SDL_flic.h $(DESTDIR)/$(INCDIR)

clean:
	rm -f libSDL_flic.a libSDL_flic.so*
	rm -f *.o *.lo
	rm -f playflic
