FROM debian:bookworm

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENXPKI_NOCONFIG=1

RUN apt-get update && \
    apt-get upgrade --assume-yes && \
    apt-get install --assume-yes gpg libdbd-mariadb-perl libdbd-mysql-perl apache2 nginx wget locales less gettext

RUN rm /etc/locale.gen && \
    (for lang in "en_US" "de_DE"; do echo "$lang.UTF-8 UTF-8" >> /etc/locale.gen; done) && \
    dpkg-reconfigure --frontend=noninteractive locales

RUN wget http://packages.openxpki.org/v3/bookworm/openxpki.sources -O - 2>/dev/null | tee /etc/apt/sources.list.d/openxpki.sources
RUN wget http://packages.openxpki.org/v3/bookworm/Release.key -O - 2>/dev/null | gpg -o /usr/share/keyrings/openxpki.pgp --dearmor
RUN apt-get update && apt-get install --assume-yes libopenxpki-perl openxpki-i18n openxpki-cgi-session-driver
RUN apt-get clean

# Hack to run rhel/sles configs in this container
RUN /usr/bin/id -u www-data | xargs /usr/sbin/useradd apache -s /usr/sbin/nologin -b /var/www -g www-data -o -u
RUN /usr/bin/id -u www-data | xargs /usr/sbin/useradd wwwrun -s /usr/sbin/nologin -b /var/www -g www-data -o -u

# Install clca (config comes from repo)
RUN wget https://raw.githubusercontent.com/openxpki/clca/master/bin/clca -O /usr/local/bin/clca && chmod 755 /usr/local/bin/clca

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
VOLUME /etc/openxpki

# Apache
RUN a2dissite 000-default; a2disconf javascript-common localized-error-pages security serve-cgi-bin other-vhosts-access-log
RUN a2enmod headers macro proxy proxy_http rewrite ssl
RUN echo "ErrorLog /proc/self/fd/2" > /etc/apache2/conf-enabled/log2stderr.conf

# nginx
RUN rm /etc/nginx/sites-enabled/default
RUN echo "error_log /dev/stderr info;" > /etc/nginx/modules-enabled/error-log-stdout.conf
RUN echo "http { access_log /dev/stdout; }" > /etc/nginx/conf.d/access-log-stdout

# Scripts
COPY bin/setup-cert.sh /usr/bin/setup-cert
RUN chmod +x /usr/bin/setup-cert
COPY bin/start-webserver.sh /usr/bin/start-webserver
RUN chmod +x /usr/bin/start-webserver
COPY bin/update-i18n.sh /usr/bin/update-i18n
RUN chmod +x /usr/bin/update-i18n

# The order here is important
RUN mkdir -m755 /run/openxpkid /run/openxpki-clientd && \
    chown openxpki /run/openxpkid && \
    chown openxpkiclient /run/openxpki-clientd
VOLUME /run/openxpkid /run/openxpki-clientd

RUN mkdir -p -m750 /var/log/openxpki-server /var/log/openxpki-client && \
    chown openxpki:pkiadm /var/log/openxpki-server && \
    chown openxpkiclient:pkiadm /var/log/openxpki-client
VOLUME /var/log/openxpki-server /var/log/openxpki-client
WORKDIR /var/log/

RUN mkdir -p -m755 /var/www/download && \
    chown openxpki:openxpki /var/www/download
VOLUME /var/www/download

RUN mkdir -p -m755 /var/www/static/_global/ && cp /usr/share/doc/libopenxpki-perl/examples/home.html /var/www/static/_global/home.html

CMD ["/usr/bin/openxpkictl","start","server","--no-detach"]

EXPOSE 80 443
