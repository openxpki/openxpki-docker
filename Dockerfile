FROM debian:buster

ARG DEBIAN_FRONTEND=noninteractive
ARG OPENXPKI_NOCONFIG=1

RUN apt-get update && \
    apt-get upgrade --assume-yes && \
    apt-get install --assume-yes gpg libdbd-mysql-perl libapache2-mod-fcgid apache2 wget locales less gettext

RUN rm /etc/locale.gen && \
    (for lang in "en_US" "de_DE"; do echo "$lang.UTF-8 UTF-8" >> /etc/locale.gen; done) && \
    dpkg-reconfigure --frontend=noninteractive locales

RUN wget https://packages.openxpki.org/v3/debian/openxpki.list -O /etc/apt/sources.list.d/openxpki.list
RUN wget https://packages.openxpki.org/v3/debian/Release.key -O - | apt-key add -
RUN apt-get update && apt-get install --assume-yes libopenxpki-perl openxpki-i18n openxpki-cgi-session-driver 
RUN apt-get clean

# Hack to run rhel/sles configs in this container
RUN /usr/bin/id -u www-data | xargs /usr/sbin/useradd apache -s /usr/sbin/nologin -b /var/www -g www-data -o -u
RUN /usr/bin/id -u www-data | xargs /usr/sbin/useradd wwwrun -s /usr/sbin/nologin -b /var/www -g www-data -o -u

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
VOLUME /var/log/openxpki /etc/openxpki
WORKDIR /var/log/openxpki/
RUN a2dissite 000-default; a2disconf serve-cgi-bin
# look alike for the default apache setup from postinst to let a2ensite openxpki work
RUN ln -s /etc/openxpki/contrib/apache2-openxpki-site.conf /etc/apache2/sites-available/openxpki.conf
RUN ln -s ../sites-available/openxpki.conf /etc/apache2/sites-enabled/ 
RUN a2enmod cgid fcgid headers rewrite ssl
COPY bin/setup-cert.sh /usr/bin/setup-cert
RUN chmod +x /usr/bin/setup-cert
COPY bin/start-apache.sh /usr/bin/start-apache
RUN chmod +x /usr/bin/start-apache
COPY bin/update-i18n.sh /usr/bin/update-i18n
RUN chmod +x /usr/bin/update-i18n

CMD ["/usr/bin/openxpkictl","start","--no-detach"]

EXPOSE 80 443
