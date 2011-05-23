PREFIX=/usr
BINDIR=$(DESTDIR)$(PREFIX)/bin
MANS=sbank sbank-deposit sbank-balance sbank-project sbank-user sbank-time sbank-cluster sbank-submit
BINS=${MANS} sbank-balance.pl sbank-common-cpu_hrs.pl

# If ikiwiki is available, build static html docs suitable for being
# shipped in the software package.
ifeq ($(shell which ikiwiki),)
IKIWIKI=@echo "** ikiwiki not found, skipping building docs" >&2; true
else
IKIWIKI=ikiwiki
endif

all: build

build: docs
	for man in $(MANS); do \
		./mdwn2man $$man 1 doc/$$man.mdwn > $$man.1; \
	done

docs:
	$(IKIWIKI) doc html -v --wikiname slurm-bank --plugin=goodstuff \
		--no-usedirs --disable-plugin=openid --plugin=sidebar \
		--underlaydir=/dev/null --disable-plugin=shortcut \
		--disable-plugin=smiley \
		--plugin=comments --set comments_pagespec="*" \
		--exclude='news/.*'

install: build
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m644 src/shflags $(DESTDIR)$(PREFIX)/bin
	for bin in $(BINS); do \
		install -m 644 src/$$bin $(DESTDIR)$(PREFIX)/bin; \
	done
	install -m 644 src/sbank-common $(DESTDIR)$(PREFIX)/bin;
	chmod +x $(DESTDIR)$(PREFIX)/bin/sbank
	chmod +x $(DESTDIR)$(PREFIX)/bin/sbank-balance.pl
	chmod +x $(DESTDIR)$(PREFIX)/bin/sbank-common-cpu_hrs.pl

	install -d $(DESTDIR)$(PREFIX)/share/man/man1
	for man in $(MANS); do \
		install -m 0644 $$man.1 $(DESTDIR)$(PREFIX)/share/man/man1; \
	done

	install -d $(DESTDIR)$(PREFIX)/share/doc/slurm-bank
	if [ -d html ]; then \
                rsync -a --delete html/ $(DESTDIR)$(PREFIX)/share/doc/slurm-bank/html/; \
        fi

runtests:
	$(MAKE) -C t runtests

test: build
	./wvtestrun $(MAKE) runtests	

clean:
	for man in $(MANS); do \
                rm -f $$man.1; \
        done
	rm -rf html doc/.ikiwiki

dist:
	git archive --format tar --prefix=$$(cat VERSION)/ HEAD | gzip > $$(cat VERSION).tar.gz

dist-withdocs: docs
	git archive --format tar --prefix=$$(cat VERSION)/ HEAD | tar xv -
	if [ -d html ]; then \
		rsync -a --delete html/ $$(cat VERSION)/html/; \
	fi
	tar czvf $$(cat VERSION).tar.gz $$(cat VERSION)/
	echo rm -rf $$(cat VERSION)

.PHONY: docs
