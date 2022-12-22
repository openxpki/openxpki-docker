#!/bin/bash

# avoid permission problems with the log volume 
chmod 4777 /var/log/openxpki

# finally: start apache
/usr/sbin/apache2ctl start

# start openxpkictl
/usr/bin/openxpkictl start --no-detach
