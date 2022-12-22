#!/bin/bash

## DO NOT USE THIS SCRIPT FOR PRODUCTION SYSTEMS

set -e

# Debug='true'
# MyPerl='true'
[ "$MyPerl" = ' true' ] && [ -d /opt/myperl/bin ] && export PATH=/opt/myperl/bin:$PATH

#
# basic openxpki settings
#
BASE='/etc/openxpki';
OPENXPKI_CONFIG="${BASE}/config.d/system/server.yaml"
if [ -f "${OPENXPKI_CONFIG}" ]
then
   eval `egrep '^user:|^group:' "${OPENXPKI_CONFIG}" | sed -e 's/:  */=/g'`
else
   echo "ERROR: It seems that openXPKI is not installed at the default location (${BASE})!" >&2
   echo "Please install OpenXPKI or set BASE to the new PATH!" >&2
   exit 1
fi

REALM='democa'
FQDN=`hostname -f`
# For automated testing we want to have this set to root
# unset this to get random passwords (put into the .pass files)
KEY_PASSWORD="root"

if [ -z "$1" ]; then
   TMP_CA_DIR=$(mktemp -d)
   echo "Fully automated sample setup using tmpdir $TMP_CA_DIR"
elif [ -d "$1" ]; then
   TMP_CA_DIR=$1
   echo "Try to read/build sample hierarchy from $TMP_CA_DIR "
else
   echo "Given parameter is not a directory"
   exit 1;
fi

make_password() {

    PASSWORD_FILE=$1;
    touch "${PASSWORD_FILE}"
    chown $user:root "${PASSWORD_FILE}"
    chmod 640 "${PASSWORD_FILE}"
    if [ -z "$KEY_PASSWORD" ]; then
        dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 >"${PASSWORD_FILE}"
    else
        echo -n "$KEY_PASSWORD" > "${PASSWORD_FILE}"
    fi;

}

#
# CA and certificate settings
#

BACKUP_SUFFIX='~'
GENERATION=$(date +%Y%m%d)

# root CA selfsigned (in production use company's root certificate)
ROOT_CA='OpenXPKI_Root_CA'
ROOT_CA_REQUEST="${TMP_CA_DIR}/${ROOT_CA}.csr"
ROOT_CA_KEY="${TMP_CA_DIR}/${ROOT_CA}.key"
ROOT_CA_KEY_PASSWORD="${TMP_CA_DIR}/${ROOT_CA}.pass"
ROOT_CA_CERTIFICATE="${TMP_CA_DIR}/${ROOT_CA}.crt"
ROOT_CA_SUBJECT="/CN=OpenXPKI Root CA ${GENERATION}"
ROOT_CA_SERVER_FQDN='rootca.openxpki.net'

# issuing CA signed by root CA above
ISSUING_CA='OpenXPKI_Issuing_CA'
ISSUING_CA_REQUEST="${TMP_CA_DIR}/${ISSUING_CA}.csr"
ISSUING_CA_KEY="${TMP_CA_DIR}/${ISSUING_CA}.key"
ISSUING_CA_KEY_PASSWORD="${TMP_CA_DIR}/${ISSUING_CA}.pass"
ISSUING_CA_CERTIFICATE="${TMP_CA_DIR}/${ISSUING_CA}.crt"
ISSUING_CA_SUBJECT="/C=DE/O=OpenXPKI/OU=PKI/CN=OpenXPKI Demo Issuing CA ${GENERATION}"

# SCEP registration authority certificate signed by root CA above
SCEP='OpenXPKI_SCEP_RA'
SCEP_REQUEST="${TMP_CA_DIR}/${SCEP}.csr"
SCEP_KEY="${TMP_CA_DIR}/${SCEP}.key"
SCEP_KEY_PASSWORD="${TMP_CA_DIR}/${SCEP}.pass"
SCEP_CERTIFICATE="${TMP_CA_DIR}/${SCEP}.crt"
SCEP_SUBJECT="/CN=${FQDN}:scep-ra"

# Apache WEB certificate signed by root CA above
WEB='OpenXPKI_WebUI'
WEB_REQUEST="${TMP_CA_DIR}/${WEB}.csr"
WEB_KEY="${TMP_CA_DIR}/${WEB}.key"
WEB_KEY_PASSWORD="${TMP_CA_DIR}/${WEB}.pass"
WEB_CERTIFICATE="${TMP_CA_DIR}/${WEB}.crt"
WEB_SUBJECT="/CN=${FQDN}"
WEB_SERVER_FQDN="${FQDN}"

# data vault certificate selfsigned
DATAVAULT='OpenXPKI_DataVault'
DATAVAULT_REQUEST="${TMP_CA_DIR}/${DATAVAULT}.csr"
DATAVAULT_KEY="${TMP_CA_DIR}/${DATAVAULT}.key"
DATAVAULT_KEY_PASSWORD="${TMP_CA_DIR}/${DATAVAULT}.pass"
DATAVAULT_CERTIFICATE="${TMP_CA_DIR}/${DATAVAULT}.crt"
DATAVAULT_SUBJECT='/CN=DataVault'

#
# openssl.conf
#
BITS=3072
DAYS=730 # 2 years (default value not used for further enhancements)
RDAYS="3655" # 10 years for root
IDAYS="1828" # 5 years for issuing
SDAYS="365" # 1 years for scep
WDAYS="1096" # 3 years web
DDAYS="$RDAYS" # 10 years datavault (same a root)

# creation neccessary directories and files
echo -n "creating configuration for openssl ($OPENSSL_CONF) .. "
test -d "${TMP_CA_DIR}" || mkdir -m 755 -p "${TMP_CA_DIR}" && chown ${user}:root "${TMP_CA_DIR}"
OPENSSL_DIR="${TMP_CA_DIR}/.openssl"
test -d "${OPENSSL_DIR}" || mkdir -m 700 "${OPENSSL_DIR}" && chown root:root "${OPENSSL_DIR}"
cd "${OPENSSL_DIR}";

OPENSSL_CONF="${OPENSSL_DIR}/openssl.cnf"

touch "${OPENSSL_DIR}/index.txt"
touch "${OPENSSL_DIR}/index.txt.attr"
echo 00 > "${OPENSSL_DIR}/crlnumber"

echo "
HOME			= .
RANDFILE		= \$ENV::HOME/.rnd

[ ca ]
default_ca		= CA_default

[ CA_default ]
dir			= ${OPENSSL_DIR}
certs			= ${OPENSSL_DIR}/certs
crl_dir			= ${OPENSSL_DIR}/
database		= ${OPENSSL_DIR}/index.txt
new_certs_dir		= ${OPENSSL_DIR}/
serial			= ${OPENSSL_DIR}/serial
crlnumber		= ${OPENSSL_DIR}/crlnumber

crl			= ${OPENSSL_DIR}/crl.pem
private_key		= ${OPENSSL_DIR}/cakey.pem
RANDFILE		= ${OPENSSL_DIR}/.rand

default_md		= sha256
preserve		= no
policy			= policy_none
default_days		= ${DAYS}

# x509_extensions               = v3_ca_extensions
# x509_extensions               = v3_issuing_extensions
# x509_extensions               = v3_datavault_extensions
# x509_extensions               = v3_scep_extensions
# x509_extensions               = v3_web_extensions

[policy_none]
countryName             = optional
organizationName        = optional
domainComponent		= optional
organizationalUnitName	= optional
commonName		= supplied

[ req ]
default_bits		= ${BITS}
distinguished_name	= req_distinguished_name

# x509_extensions               = v3_ca_reqexts # not for root self signed, only for issuing
## x509_extensions              = v3_datavault_reqexts # not required self signed
# x509_extensions               = v3_scep_reqexts
# x509_extensions               = v3_web_reqexts

[ req_distinguished_name ]
domainComponent		= Domain Component
commonName		= Common Name

[ v3_ca_reqexts ]
subjectKeyIdentifier    = hash
keyUsage                = digitalSignature, keyCertSign, cRLSign

[ v3_datavault_reqexts ]
subjectKeyIdentifier    = hash
keyUsage                = keyEncipherment
extendedKeyUsage        = emailProtection

[ v3_scep_reqexts ]
subjectKeyIdentifier    = hash

[ v3_web_reqexts ]
subjectKeyIdentifier    = hash
keyUsage                = critical, digitalSignature, keyEncipherment
extendedKeyUsage        = serverAuth, clientAuth


[ v3_ca_extensions ]
subjectKeyIdentifier    = hash
keyUsage                = digitalSignature, keyCertSign, cRLSign
basicConstraints        = critical,CA:TRUE
authorityKeyIdentifier  = keyid:always,issuer

[ v3_issuing_extensions ]
subjectKeyIdentifier    = hash
keyUsage                = digitalSignature, keyCertSign, cRLSign
basicConstraints        = critical,CA:TRUE
authorityKeyIdentifier  = keyid:always,issuer:always
#crlDistributionPoints	= ${ROOT_CA_REVOCATION_URI}
#authorityInfoAccess	= caIssuers;${ROOT_CA_CERTIFICATE_URI}

[ v3_datavault_extensions ]
subjectKeyIdentifier    = hash
keyUsage                = keyEncipherment
extendedKeyUsage        = emailProtection
basicConstraints        = CA:FALSE
authorityKeyIdentifier  = keyid:always,issuer

[ v3_scep_extensions ]
subjectKeyIdentifier    = hash
keyUsage                = digitalSignature, keyEncipherment
basicConstraints        = CA:FALSE
authorityKeyIdentifier  = keyid,issuer

[ v3_web_extensions ]
subjectKeyIdentifier    = hash
keyUsage                = critical, digitalSignature, keyEncipherment
extendedKeyUsage        = serverAuth, clientAuth
basicConstraints        = critical,CA:FALSE
subjectAltName		= DNS:${WEB_SERVER_FQDN}
#crlDistributionPoints	= ${ISSUING_REVOCATION_URI}
#authorityInfoAccess	= caIssuers;${ISSUING_CERTIFICATE_URI}
" > "${OPENSSL_CONF}"

echo "done."

[ "$Debug" = 'true' ] || exec 2>/dev/null

echo "Creating certificates .. "

# self signed root
if [ ! -e "${ROOT_CA_CERTIFICATE}" ]
then
   echo "Did not find a root ca certificate file."
   echo -n "Creating an own self signed root ca .. "
   test -f "${ROOT_CA_KEY}" && \
    mv "${ROOT_CA_KEY}" "${ROOT_CA_KEY}${BACKUP_SUFFIX}"
   test -f "${ROOT_CA_KEY_PASSWORD}" && \
    mv "${ROOT_CA_KEY_PASSWORD}" "${ROOT_CA_KEY_PASSWORD}${BACKUP_SUFFIX}"
   make_password "${ROOT_CA_KEY_PASSWORD}"
   openssl req -verbose -config "${OPENSSL_CONF}" -extensions v3_ca_extensions -batch -x509 -newkey rsa:$BITS -days ${RDAYS} -passout file:"${ROOT_CA_KEY_PASSWORD}" -keyout "${ROOT_CA_KEY}" -subj "${ROOT_CA_SUBJECT}" -out "${ROOT_CA_CERTIFICATE}"
   echo "done."
fi

# signing certificate (issuing)
if [ ! -e "${ISSUING_CA_KEY}" ]
then
   echo "Did not find existing issuing CA key file."
   echo -n "Creating an issuing CA request .. "
   test -f "${ISSUING_CA_REQUEST}" && \
    mv "${ISSUING_CA_REQUEST}" "${ISSUING_CA_REQUEST}${BACKUP_SUFFIX}"
   make_password "${ISSUING_CA_KEY_PASSWORD}"
   openssl req -verbose -config "${OPENSSL_CONF}" -reqexts v3_ca_reqexts -batch -newkey rsa:$BITS -passout file:"${ISSUING_CA_KEY_PASSWORD}" -keyout "${ISSUING_CA_KEY}" -subj "${ISSUING_CA_SUBJECT}" -out "${ISSUING_CA_REQUEST}"
   echo "done."
   if [ -e "${ROOT_CA_KEY}" ]
   then
      echo -n "Signing issuing certificate with own root CA .. "
      test -f "${ISSUING_CA_CERTIFICATE}" && \
       mv "${ISSUING_CA_CERTIFICATE}" "${ISSUING_CA_CERTIFICATE}${BACKUP_SUFFIX}"
      openssl ca -create_serial -config "${OPENSSL_CONF}" -extensions v3_issuing_extensions -batch -days ${IDAYS} -in "${ISSUING_CA_REQUEST}" -cert "${ROOT_CA_CERTIFICATE}" -passin file:"${ROOT_CA_KEY_PASSWORD}" -keyfile "${ROOT_CA_KEY}" -out "${ISSUING_CA_CERTIFICATE}"
      echo "done."
   else
      echo "No '${ROOT_CA_KEY}' key file!"
      echo "please sign generated request with the company's root CA key"
      exit 0
   fi
else
   if [ ! -e "${ISSUING_CA_CERTIFICATE}" ]
   then
      echo "No '${ISSUING_CA_CERTIFICATE}' certificate file!"
      if [ ! -e "${ROOT_CA_KEY}" ]
      then
         echo "No '${ROOT_CA_KEY}' key file!"
         echo "please sign generated request with the company's root CA key"
         exit 0
      else
         echo -n "Signing issuing certificate with own root CA .. "
         openssl ca -create_serial -config "${OPENSSL_CONF}" -extensions v3_issuing_extensions -batch -days ${IDAYS} -in "${ISSUING_CA_REQUEST}" -cert "${ROOT_CA_CERTIFICATE}" -passin file:"${ROOT_CA_KEY_PASSWORD}" -keyfile "${ROOT_CA_KEY}" -out "${ISSUING_CA_CERTIFICATE}"
         echo "done."
      fi
   fi
fi

# Data Vault is only used internally, use self signed
if [ ! -e "${DATAVAULT_KEY}" ]
then
   echo "Did not find existing DataVault certificate file."
   echo -n "Creating a self signed DataVault certificate .. "
   test -f "${DATAVAULT_CERTIFICATE}" && \
    mv "${DATAVAULT_CERTIFICATE}" "${DATAVAULT_CERTIFICATE}${BACKUP_SUFFIX}"
   make_password "${DATAVAULT_KEY_PASSWORD}"
   openssl req -verbose -config "${OPENSSL_CONF}" -extensions v3_datavault_extensions -batch -x509 -newkey rsa:$BITS -days ${DDAYS} -passout file:"${DATAVAULT_KEY_PASSWORD}" -keyout "${DATAVAULT_KEY}" -subj "${DATAVAULT_SUBJECT}" -out "${DATAVAULT_CERTIFICATE}"
   echo "done."
fi

# scep certificate
if [ ! -e "${SCEP_KEY}" ]
then
   echo "Did not find existing SCEP certificate file."
   echo -n "Creating a SCEP request .. "
   test -f "${SCEP_REQUEST}" && \
    mv "${SCEP_REQUEST}" "${SCEP_REQUEST}${BACKUP_SUFFIX}"
   make_password "${SCEP_KEY_PASSWORD}"
   openssl req -verbose -config "${OPENSSL_CONF}" -reqexts v3_scep_reqexts -batch -newkey rsa:$BITS -passout file:"${SCEP_KEY_PASSWORD}" -keyout "${SCEP_KEY}" -subj "${SCEP_SUBJECT}" -out "${SCEP_REQUEST}"
   echo "done."
   echo -n "Signing SCEP certificate with Issuing CA .. "
   test -f "${SCEP_CERTIFICATE}" && \
    mv "${SCEP_CERTIFICATE}" "${SCEP_CERTIFICATE}${BACKUP_SUFFIX}"
   openssl ca -create_serial -config "${OPENSSL_CONF}" -extensions v3_scep_extensions -batch -days ${SDAYS} -in "${SCEP_REQUEST}" -cert "${ISSUING_CA_CERTIFICATE}" -passin file:"${ISSUING_CA_KEY_PASSWORD}" -keyfile "${ISSUING_CA_KEY}" -out "${SCEP_CERTIFICATE}"
   echo "done."
fi

# web certificate
if [ ! -e "${WEB_KEY}" ]
then
   echo "Did not find existing WEB certificate file."
   echo -n "Creating a Web request .. "
   test -f "${WEB_REQUEST}" && \
    mv "${WEB_REQUEST}" "${WEB_REQUEST}${BACKUP_SUFFIX}"
   make_password "${WEB_KEY_PASSWORD}"
   openssl req -verbose -config "${OPENSSL_CONF}" -reqexts v3_web_reqexts -batch -newkey rsa:$BITS -passout file:"${WEB_KEY_PASSWORD}" -keyout "${WEB_KEY}" -subj "${WEB_SUBJECT}" -out "${WEB_REQUEST}"
   echo "done."
   echo -n "Signing Web certificate with Issuing CA .. "
   test -f "${WEB_CERTIFICATE}" && \
    mv "${WEB_CERTIFICATE}" "${WEB_CERTIFICATE}${BACKUP_SUFFIX}"
   openssl ca -create_serial -config "${OPENSSL_CONF}" -extensions v3_web_extensions -batch -days ${WDAYS} -in "${WEB_REQUEST}" -cert "${ISSUING_CA_CERTIFICATE}" -passin file:"${ISSUING_CA_KEY_PASSWORD}" -keyfile "${ISSUING_CA_KEY}" -out "${WEB_CERTIFICATE}"
   echo "done."
fi

cd $OLDPWD;
# rm $TMP/*;
# rmdir $TMP;

# chown/chmod
chmod 400 ${TMP_CA_DIR}/*.pass
chmod 440 ${TMP_CA_DIR}/*.key
chmod 444 ${TMP_CA_DIR}/*.crt
chown root:root ${TMP_CA_DIR}/*.csr ${TMP_CA_DIR}/*.key ${TMP_CA_DIR}/*.pass
chown root:${group} ${TMP_CA_DIR}/*.crt ${TMP_CA_DIR}/*.key

echo -n "Starting server before running import ... "
openxpkictl start

mkdir -p /etc/openxpki/local/keys

# the import command with the --key parameter takes care to copy the key
# files to the datapool or filesystem locations
openxpkiadm certificate import --file "${ROOT_CA_CERTIFICATE}"

openxpkiadm alias --file "${DATAVAULT_CERTIFICATE}" --realm "${REALM}" --token datasafe --key ${DATAVAULT_KEY}
sleep 1;
openxpkiadm alias --file "${ISSUING_CA_CERTIFICATE}" --realm "${REALM}" --token certsign --key ${ISSUING_CA_KEY}
openxpkiadm alias --file "${SCEP_CERTIFICATE}" --realm "${REALM}" --token scep  --key ${SCEP_KEY}

echo "done."
echo ""

# Setup the Webserver
a2enmod ssl rewrite headers
a2ensite openxpki
a2dissite 000-default default-ssl

if [ ! -e "/etc/openxpki/tls/chain" ]; then
    mkdir -m755 -p /etc/openxpki/tls/chain
    cp ${ROOT_CA_CERTIFICATE} /etc/openxpki/tls/chain/
    cp ${ISSUING_CA_CERTIFICATE} /etc/openxpki/tls/chain/
    c_rehash /etc/openxpki/tls/chain/
fi

if [ ! -e "/etc/openxpki/tls/endentity/openxpki.crt" ]; then
    mkdir -m755 -p /etc/openxpki/tls/endentity
    mkdir -m700 -p /etc/openxpki/tls/private
    cp ${WEB_CERTIFICATE} /etc/openxpki/tls/endentity/openxpki.crt
    cat ${ISSUING_CA_CERTIFICATE} >> /etc/openxpki/tls/endentity/openxpki.crt
    openssl rsa -in ${WEB_KEY} -passin file:${WEB_KEY_PASSWORD} -out /etc/openxpki/tls/private/openxpki.pem
    chmod 400 /etc/openxpki/tls/private/openxpki.pem
    service apache2 restart
fi

cp ${ISSUING_CA_CERTIFICATE} /etc/ssl/certs
cp ${ROOT_CA_CERTIFICATE} /etc/ssl/certs
c_rehash /etc/ssl/certs

echo "OpenXPKI configuration should be and server should be running..."
echo ""
echo "Thanks for using OpenXPKI - Have a nice day ;)"
echo ""
