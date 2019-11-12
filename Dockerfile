FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENXPKI_NOCONFIG=1

RUN apt-get update && \
    apt-get install --assume-yes gpg libdbd-mysql-perl libapache2-mod-fcgid apache2 wget locales less gettext

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && dpkg-reconfigure --frontend=noninteractive locales
RUN wget https://packages.openxpki.org/v3/debian/openxpki.list -O /etc/apt/sources.list.d/openxpki.list
RUN wget https://packages.openxpki.org/v3/debian/Release.key -O - | apt-key add -
RUN apt-get update && apt-get install --assume-yes libopenxpki-perl openxpki-i18n openxpki-cgi-session-driver libcrypt-libscep-perl libscep
RUN apt-get clean

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
VOLUME /var/log/openxpki /etc/openxpki
WORKDIR /var/log/openxpki/
RUN ln -s /etc/openxpki/contrib/apache2-openxpki.conf /etc/apache2/conf-enabled/
RUN a2dissite 000-default; a2disconf serve-cgi-bin
RUN ln -s /etc/openxpki/contrib/apache2-openxpki-site.conf /etc/apache2/sites-enabled/
RUN a2enmod cgid fcgid headers rewrite ssl
COPY bin/setup-cert.sh /usr/bin/setup-cert
RUN chmod +x /usr/bin/setup-cert
COPY bin/start-apache.sh /usr/bin/start-apache
RUN chmod +x /usr/bin/start-apache
COPY bin/update-i18n.sh /usr/bin/update-i18n
RUN chmod +x /usr/bin/update-i18n

CMD ["/usr/bin/openxpkictl","start","--no-detach"]

EXPOSE 80 443
