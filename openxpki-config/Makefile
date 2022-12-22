POFILES=$(wildcard contrib/i18n/*/openxpki.po)

-include Makefile.local

.PHONY: i18n-update

version:
	touch config.d/system/version.yaml
	sed -r "/^commit:/d" -i config.d/system/version.yaml
	git log -n 1 --format=format:"commit: \"%h\"%n" HEAD >> config.d/system/version.yaml

openxpki-config.i18n: config.d template
	@grep -rhoEe 'I18N_OPENXPKI_UI_\w+' config.d template | sort | uniq > $@
	test -d ../openxpki/core/i18n/extra && mv $@ ../openxpki/core/i18n/extra

i18n-update: $(POFILES)

$(POFILES):
	@cp $(subst contrib,../openxpki/core,$@) $@

# vim: tabstop=4 noexpandtab
