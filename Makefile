# Copyright (C) 2022, 2023 Timothe Litt litt at acm ddot org

# $Id: c8dcdbc31869b1385dfd11f0386043f7f6705c3b $

# Install targets - can override on command line

# Note that DESTDIR is supported for staging environments

prefix          := /usr/local
datarootdir     := $(prefix)/share
mandir          := $(datarootdir)/man
man1dir         := $(mandir)/man1
manext          := .1
man1ext         := .1
exec_prefix     := $(prefix)
bindir          := $(exec_prefix)/bin

INSTALL         := install
INSTALL_PROGRAM := $(INSTALL)
INSTALL_DATA    := $(INSTALL) -m 644

# Specify key="deadbeef" or key="deadbeef beeffeed" on command line (else default)
GPG          := gpg

PERL         := perl
PERLTIDY     := perltidy
POD2MAN      := pod2man
POD2MARKDOWN := pod2markdown

SHELL        := bash

# Usage:
#  See INSTALL

# Extract version from ascron source

kitversion := $(shell $(PERL) ascron -vv)
kitname    := ascron-$(kitversion)
kitowner   := 0:0

# If in a Git working directory and the git command is available,
# get the last tag in case making a distribution.

ifneq "$(strip $(shell [ -d '.git' ] && echo 'true' ))" ""
  gitcmd   := $(shell command -v git)
  ifneq "$(strip $(gitcmd))" ""
    gittag := $(shell git tag --sort=version:refname | tail -n1)
  endif
endif

# file types from which tar can infer compression, if tool is installed

# kittypes := gz xz lzop lz lzma Z zst bz bz2

# kittypes to build

kittypes := gz xz

# Files to package

kitfiles := INSTALL README.md LICENSE ascron ascron$(man1ext) Makefile

.PHONY : all

all : ascron$(man1ext) README.md

# Compilations: man page from pod in ascron

ascron$(man1ext) : ascron Makefile
	$(POD2MAN) --center "Interactive cron simulator"  --date "$$(date -r ascron '+%d-%b-%Y')"\
		--release "ascron V$(kitversion)" $< $@

# Die if no pod2markdown.
# Append the appropriate sections of POD from ascron to READNE,md.in
# Extract the sections as POD, convert to markdown, append

README.md : ascron README.md.in Makefile
	@$(POD2MARKDOWN)  </dev/null >/dev/null
	$(PERL)  -Mwarnings -Mstrict <$<                   \
	-e'print "=pod\n\n"; while( <> ) {'                \
	-e'my $$t = /^=head1 NAME/../^=head1 Subtleties/;' \
	-e'print if( $$t && $$t !~ /E0$$/ ); }'            \
	-e'print( "\n=cut\n" );'| $(POD2MARKDOWN) | cat $@.in - >$@

# Make tarball kits - various compressions

.PHONY : dist unsigned-dist signed-dist

dist : signed-dist

ifeq ($(strip $(gitcmd)),)
signed-dist : $(foreach type,$(kittypes),$(kitname).tar.$(type).sig)
else
signed-dist : $(foreach type,$(kittypes),$(kitname).tar.$(type).sig) .tagged
endif

unsigned-dist : $(foreach type,$(kittypes),$(kitname).tar.$(type))

# Tarball build directory

$(kitname)/% : %
	@mkdir -p $(dir $@)
	@-chown $(kitowner) $(dir $@)
	cp -p $< $@
	@-chown $(kitowner) $@

# Clean up after builds

.PHONY : clean

clean:
	rm -rf $(kitname) $(foreach type,$(kittypes),$(kitname).tar.$(type){,.sig})

# Install program and doc

.PHONY : install

install : ascron ascron$(man1ext) installdirs
	$(INSTALL_PROGRAM) ascron $(DESTDIR)$(bindir)/ascron
	-$(INSTALL_DATA) ascron$(man1ext) $(DESTDIR)$(man1dir)/ascron$(man1ext)
	-@$(PERL) -MTime::ParseDate -e'exit 0;' >/dev/null 2>&1 || \
	    echo " *** Perl module Time::ParseDate is not installed.  It is not required, but is recommended."

# un-install

.PHONY : uninstall

uninstall :
	-rm -f "$(DESTDIR)$(bindir)/ascron"
	-rm -f "$(DESTDIR)$(man1dir)/ascron$(man1ext)"

# create install directory tree (especially when staging)

installdirs :
	$(INSTALL) -d $(DESTDIR)$(bindir) $(DESTDIR)$(man1dir)

# rules for making tarballs - $1 is file type that implies compression

define make_tar =

%.tar.$(1) : $$(foreach f,$$(kitfiles), %/$$(f))
	tar -caf $$@ $$^
	@-chown $(kitowner) $$@

endef

$(foreach type,$(kittypes),$(eval $(call make_tar,$(type))))

# Ensure that the release is tagged, providing the working directory is clean
# Depends on everything in git (not just kitfiles), everything compiled, and
# all the release kits.

ifneq ($(strip $(gitcmd)),)
.PHONY : tag

tag : .tagged

.tagged : $(shell git ls-tree --full-tree --name-only -r HEAD) unsigned-dist
	@if git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' >/dev/null 2>/dev/null || \
	    [ -n "$$(git diff --name-only)$$(git diff --name-only --staged)" ]; then \
	    echo " *** Not tagging V$(kitversion) because working directory is dirty"; echo ""; false ;\
	 elif [ "$(strip $(gittag))" == "V$(kitversion)" ]; then                 \
	    echo " *** Not tagging because V$(kitversion) already exists";       \
	    echo ""; false;                                                      \
	 else                                                                    \
	    git tag V$(kitversion) && echo "Tagged as V$(kitversion)" | tee .tagged || true; \
	 fi

endif

# create a detached signature for a file

%.sig : % Makefile
	@-rm -f $<.sig
	$(GPG) --output $@ --detach-sig $(foreach k,$(key), --local-user "$(k)") $(basename $@)
	@-chown $(kitowner) $@

# perltidy

.PHONY : tidy

tidy : ascron
	$(PERLTIDY) -b $<
