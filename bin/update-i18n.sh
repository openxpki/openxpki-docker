#!/bin/bash
test -d /etc/openxpki/i18n/ || exit;

for lang in `ls /etc/openxpki/i18n/`; do
    echo "Update i18n for $lang"
    FILES=`ls /etc/openxpki/i18n/$lang/*.po`
    test -e /etc/openxpki/contrib/i18n/$lang/openxpki.po && FILES+=" /etc/openxpki/contrib/i18n/$lang/openxpki.po"
    mkdir -m755 -p /usr/share/locale/$lang/LC_MESSAGES/
    msgcat --use-first $FILES | msgfmt - -o /usr/share/locale/$lang/LC_MESSAGES/openxpki.mo
done;

