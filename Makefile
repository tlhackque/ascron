# Install targets - can override on command line

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

# Specify key="deadbeef" or key="deadbeef beeffeed" on command line (else default)
GPG = gpg

SHELL := bash

# Usage:
#  See INSTALL

# Extract version from ascron source

tarversion != sed -ne"/our \$$VERSION \+=/s/^.*= *['\"]\\?V\\?\\([0-9.]\\+\\).*$$/\\1/p;" ascron
kitname = ascron-$(tarversion)

# If in a Git working directory and the git command is available,
# get the last tag and wd state in case making a distribution

ifneq "$(strip $(shell [ -d '.git' ] && echo 'true' ))" ""
  gitcmd != command -v git
  ifneq "$(strip $(gitcmd))" ""
    gittag != git tag | tail -n1
    gitdirty != git diff --stat
  endif
endif

# file types from which tar can infer compression

kittypes = gz xz lzop

.PHONY : all

all : ascron$(man1ext)

# Compilations: man page from pod in ascron

ascron$(man1ext) : ascron Makefile
	pod2man --center "Interactive cron simulator"  --release "$$(./ascron --version | sed -e'1!d;s/version //')" $< $@

# Make tarball kits - various compressions

.PHONY : dist unsigned-dist signed-dist

dist : signed-dist

signed-dist : unsigned-dist $(foreach type,$(kittypes),$(kitname).tar.$(type).sig)

unsigned-dist : $(foreach type,$(kittypes),$(kitname).tar.$(type))

# Tarball build directory

$(kitname) :  ascron ascron$(man1ext) Makefile INSTALL
	rm -rf $(kitname)
	mkdir -p $(kitname)
	cp -p $^ $(kitname)
	chown -R 0.0 $(kitname)

# Clean up after builds

.PHONY : clean

clean:
	rm -rf $(kitname) $(foreach type,$(kittypes),$(kitname).tar.$(type)*)

# Install program and doc

.PHONY : install

install : ascron ascron$(man1ext) installdirs
	$(INSTALL_PROGRAM) ascron $(DESTDIR)$(bindir)/ascron
	-$(INSTALL_DATA) ascron$(man1ext) $(DESTDIR)$(man1dir)/ascron$(man1ext)

# un-install

.PHONY : uninstall

uninstall :
	-rm $(DESTDIR)$(bindir)/ascron
	-rm $(DESTDIR)$(man1dir)/ascron$(man1ext)

# create install directory tree (especially when staging)

installdirs :
	$(INSTALL) -d $(DESTDIR)$(bindir) $(DESTDIR)$(man1dir)

# rules for making tarballs - $1 is file type that implies compression

define make_tar =

%.tar.$(1) : %
	tar -caf $$@ $$^
	chown 0.0 $$@
ifneq ($(strip $(gitcmd)),)
  ifeq ($(strip $(gitdirty)),)
    ifeq ($(strip $(gittag)),V$(tarversion))
	@echo " *** Not tagging because $(gittag)/V$(tarversion) already exists"
	@echo ""
    else
	-git tag -f V$(tarversion)
    endif
  else
	@echo " *** Not tagging V$(tarversion) because working directory is dirty"
	@echo ""
  endif
endif

endef

$(foreach type,$(kittypes),$(eval $(call make_tar,$(type))))

# create a detached signature for a file

%.sig : % Makefile
	rm -f $<.sig
	$(GPG) --output $@ --detach-sig $(if $(key),$(foreach k,$(key), --local-user "$(k)"),) $(basename $@)
	chown 0.0 $@
