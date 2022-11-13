prefix = /usr/local
datarootdir = $(prefix)/share
mandir = $(datarootdir)/man
man1dir = $(mandir)/man1
manext = .1
man1ext = .1
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin

INSTALL = install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

tarversion != sed -ne"/our \$$VERSION \+=/s/^.*= *['\"]\\?V\\?\\([0-9.]\\+\\).*$$/\\1/p;" ascron
kitname = ascron-$(tarversion)

.PHONY : all

all : ascron$(man1ext)

ascron$(man1ext) : ascron
	pod2man --center "Interactive cron simulator" $< $@

.PHONY : dist

dist : ascron ascron$(man1ext) Makefile
	rm -rf $(kitname)
	mkdir -p $(kitname)
	cp -p $^ $(kitname)
	chown -R 0.0 $(kitname)
	tar -czf $(kitname).tgz $(kitname)
	rm -rf $(kitname)

.PHONY : clean

clean:
	rm -rf $(kitname) $(kitname).tgz

.PHONY : install

install : ascron ascron$(man1ext) installdirs
	$(INSTALL_PROGRAM) ascron $(DESTDIR)$(bindir)/ascron
	-$(INSTALL_DATA) ascron$(man1ext) $(DESTDIR)$(man1dir)/ascron$(man1ext)

.PHONY : uninstall

uninstall :
	-rm $(DESTDIR)$(bindir)/ascron
	-rm $(DESTDIR)$(man1dir)/ascron$(man1ext)

installdirs :
	$(INSTALL) -d $(DESTDIR)$(bindir) $(DESTDIR)$(man1dir)
