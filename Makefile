prefix ?= $(HOME)
bindir := $(prefix)/bin
cmddir := $(prefix)/share/topgit
docdir := $(prefix)/share/doc/topgit
hooksdir := $(cmddir)/hooks


commands_in := $(wildcard tg-*.sh)
hooks_in = hooks/pre-commit.sh

commands_out := $(patsubst %.sh,%,$(commands_in))
hooks_out := $(patsubst %.sh,%,$(hooks_in))
help_out := $(patsubst %.sh,%.txt,$(commands_in))

all::	tg $(commands_out) $(hooks_out) $(help_out)

tg $(commands_out) $(hooks_out): % : %.sh Makefile
	@echo "[SED] $@"
	@sed -e 's#@cmddir@#$(cmddir)#g;' \
		-e 's#@hooksdir@#$(hooksdir)#g' \
		-e 's#@bindir@#$(bindir)#g' \
		-e 's#@docdir@#$(docdir)#g' \
		$@.sh >$@+ && \
	chmod +x $@+ && \
	mv $@+ $@

$(help_out): README
	@CMD=`echo $@ | sed -e 's/tg-//' -e 's/\.txt//'` && \
	echo '[HELP]' $$CMD && \
	./create-help.sh $$CMD

install:: all
	install -d -m 755 "$(DESTDIR)$(bindir)"
	install tg "$(DESTDIR)$(bindir)"
	install -d -m 755 "$(DESTDIR)$(cmddir)"
	install $(commands_out) "$(DESTDIR)$(cmddir)"
	install -d -m 755 "$(DESTDIR)$(hooksdir)"
	install $(hooks_out) "$(DESTDIR)$(hooksdir)"
	install -d -m 755 "$(DESTDIR)$(docdir)"
	install -m 644 $(help_out) "$(DESTDIR)$(docdir)"

clean::
	rm -f tg $(commands_out) $(hooks_out) $(help_out)
