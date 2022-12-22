FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENXPKI_NOCONFIG=1

RUN apt-get update && \
    apt-get install --assume-yes gpg libdbd-mysql-perl libapache2-mod-fcgid apache2 wget locales less gettext

RUN rm /etc/locale.gen && \
    (for lang in "en_US" "de_DE" "ja_JP"; do echo "$lang.UTF-8 UTF-8" >> /etc/locale.gen; done) && \
    dpkg-reconfigure --frontend=noninteractive locales

RUN wget https://packages.openxpki.org/v3/debian/openxpki.list -O /etc/apt/sources.list.d/openxpki.list
RUN wget https://packages.openxpki.org/v3/debian/Release.key -O - | apt-key add -
RUN apt-get update && apt-get install --assume-yes libopenxpki-perl openxpki-i18n openxpki-cgi-session-driver libcrypt-libscep-perl libscep
RUN apt-get clean

# Hack to run rhel/sles configs in this container
RUN /usr/bin/id -u www-data | xargs /usr/sbin/useradd apache -s /usr/sbin/nologin -b /var/www -g www-data -o -u
RUN /usr/bin/id -u www-data | xargs /usr/sbin/useradd wwwrun -s /usr/sbin/nologin -b /var/www -g www-data -o -u

ENV LANG=ja_JP.UTF-8 LANGUAGE=ja_JP:en LC_ALL=ja_JP.UTF-8
VOLUME /var/log/openxpki /etc/openxpki
WORKDIR /var/log/openxpki/
RUN a2dissite 000-default; a2disconf serve-cgi-bin
# look alike for the default apache setup from postinst to let a2ensite openxpki work
RUN ln -s /etc/openxpki/contrib/apache2-openxpki-site.conf /etc/apache2/sites-available/openxpki.conf
RUN ln -s ../sites-available/openxpki.conf /etc/apache2/sites-enabled/ 
RUN a2enmod cgid fcgid headers rewrite ssl
COPY bin/setup-cert.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-cert.sh
COPY bin/start-apache.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start-apache.sh
COPY bin/update-i18n.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/update-i18n.sh
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN echo "ServerName localhost:8443" >> /etc/apache2/apache2.conf

CMD ["/usr/local/bin/entrypoint.sh"]

EXPOSE 80 443
