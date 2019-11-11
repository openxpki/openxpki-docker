FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENXPKI_NOCONFIG=1

RUN apt-get update && \
    apt-get install --assume-yes gpg libdbd-mysql-perl libapache2-mod-fcgid apache2 wget locales less

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && dpkg-reconfigure --frontend=noninteractive locales
RUN wget https://packages.openxpki.org/v3/debian/openxpki.list -O /etc/apt/sources.list.d/openxpki.list
RUN wget https://packages.openxpki.org/v3/debian/Release.key -O - | apt-key add -
RUN apt-get update && apt-get install --assume-yes libopenxpki-perl openxpki-i18n openxpki-cgi-session-driver libcrypt-libscep-perl libscep 
RUN apt-get clean
RUN ln -s /etc/openxpki/contrib/apache2-openxpki.conf /etc/apache2/conf-enabled/
RUN a2dissite 000-default
RUN ln -s /etc/openxpki/contrib/apache2-openxpki-site.conf /etc/apache2/sites-enabled/
RUN a2enmod cgid fcgid headers rewrite ssl
COPY bin/setup-cert.sh /usr/bin/setup-cert
RUN chmod +x /usr/bin/setup-cert
COPY bin/start-apache.sh /usr/bin/start-apache
RUN chmod +x /usr/bin/start-apache

VOLUME /var/log/openxpki /etc/openxpki

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /var/log/openxpki/

CMD ["/usr/bin/openxpkictl","start","--no-detach"]

EXPOSE 80 443
