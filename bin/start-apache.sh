#!/bin/bash
CONFIG_CERT_PATH="/etc/openxpki/contrib/https"

SSL_BASE_CRT_DIR=/etc/apache2/ssl.crt
SSL_BASE_KEY_DIR=/etc/apache2/ssl.key

SSL_CERT_FILE="$SSL_BASE_CRT_DIR/openxpki.crt"
SSL_KEY_FILE="$SSL_BASE_KEY_DIR/openxpki.key"

# subj for self-signed certificate
CERT_SUBJ="/CN=OpenXPKI Test"
# host names:
DNS1="DNS.1 = localhost"
DNS2="DNS.2 = openxpki"
DNS3=""

# cleanup pid file for apache
rm -f /run/apache2/apache2.pid

# handle cert file: check if corresponding key file exists and copy certificate+key to the right places
function handle_cert_file() {
    cert_file=$1
    key_file="$(dirname $cert_file)/$(basename $cert_file .crt).pem"
    # make sure all directories exist
    mkdir -p "$SSL_BASE_CRT_DIR"
    mkdir -p "$SSL_BASE_KEY_DIR"
    if [ -f "$key_file" ]; then
      # copy certificate and keys to apache directories
      echo "using certificate '$cert_file' with key '$key_file' for apache"
      cp "$cert_file" "$SSL_CERT_FILE"
      cp "$key_file" "$SSL_KEY_FILE"
    else
      # if corresponding key file is missing -> exit
      echo "[ERROR] could not find matching key file '$key_file' for certificate '$cert_file'"
      exit 1
    fi
}
# call handle_cert_file for every found certificate in CONFIG_CERT_PATH
function handle_cert_files(){
    for f in $(find "$CONFIG_CERT_PATH" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex ".*\.crt"); do
      handle_cert_file $f
    done
}
# generate self signed certificate and store it into CONFIG_CERT_PATH
function generate_self_signed (){
  TMP_FILE="/tmp/self-signed.cnf"
  echo "authorityKeyIdentifier=keyid,issuer
  basicConstraints=CA:FALSE
  distinguished_name = subject
  keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
  [ req_san ]
  subjectAltName = @alt_names
  [ subject ]
  CN=OpenXPKI Test
  [ alt_names ]
  $DNS1
  $DNS2
  $DNS3
  " > "$TMP_FILE"
  openssl req -config "$TMP_FILE" -extensions req_san -new -x509 -sha256 -newkey rsa:2048 -nodes -keyout "/tmp/self-signed.pem" -subj "$CERT_SUBJ" -days 365 -out  "/tmp/self-signed.crt"
  handle_cert_file /tmp/self-signed.crt
}

# count available certificate files
if [ -d "$CONFIG_CERT_PATH" ]; then
    crt_count="$(find "$CONFIG_CERT_PATH" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex ".*\.crt" | wc -l)"
else
    crt_count=0
fi
if [ $crt_count != 1 ]; then
  if [ $crt_count = 0 ]; then
    # nothing to import, check if there is already one
    if [ ! -e "$SSL_CERT_FILE" ] || [ ! -f "$SSL_KEY_FILE" ]; then
        echo "No certificate found, generating self-signed"
        generate_self_signed
    fi
  else
    # multiple certificates available -> exit
    echo "[ERROR] Found too much($crt_count) possible SSL certificates, expected 1"
    exit 1
  fi
else
  #exactly one certificate found -> use it
  handle_cert_files
fi

# check if i18n update is requested
test -e /etc/openxpki/i18n/.update && /usr/bin/update-i18n && rm -f /etc/openxpki/i18n/.update

# finally: start apache
/usr/sbin/apache2ctl -D FOREGROUND
