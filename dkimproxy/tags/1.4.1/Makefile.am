SUBDIRS = lib scripts

EXTRA_DIST = \
	TODO \
	install-perl-script.pl \
	smtpprox.ChangeLog \
	smtpprox.README \
	smtpprox.TODO \
	sample-dkim-init-script.sh sample-dkim-init-script.sh.in \
	dkimproxy.spec dkimproxy.spec.in

noinst_SCRIPTS = sample-dkim-init-script.sh
CLEANFILES = sample-dkim-init-script.sh

sample-dkim-init-script.sh: sample-dkim-init-script.sh.in Makefile
	rm -f $@ $@.tmp
	sed -e 's|@localstatedir[@]|$(localstatedir)|g' \
	    -e 's|@sysconfdir[@]|$(sysconfdir)|g' \
	    -e 's|@bindir[@]|$(bindir)|g' \
	    '$(srcdir)/$@.in' >$@.tmp
	mv $@.tmp $@

rfcs = rfc4870.txt rfc4871.txt rfc2821.txt rfc5322.txt rfc4407.txt
drafts = draft-ietf-dkim-ssp-09.txt
download-rfcs: $(rfcs) $(drafts)

$(rfcs) :
	curl -o $@ http://www.ietf.org/rfc/$@
$(drafts) :
	curl -o $@ http://www.ietf.org/internet-drafts/$@
