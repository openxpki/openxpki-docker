#!/bin/bash
BASE_PATH="/etc/openxpki/ca"

#computes alias for identifier
function alias_for_identifier() {
  declare -n ret=$3
  ret="$(openxpkiadm alias --realm "$1" | perl -0777 -ne "\$str=\$_; print \$str =~ /Alias\s*:\s*(.*)\s*\n\s*Identifier\s*:\s*$2/ ;")"
}
# carries out the whole import process
# Parameters: [1]: realm (e.g. "ca-one") [2]: path to certificate file [3]: list of all certificates of realm
function import_cert() {
  realm="$1"
  file="$2"
  type="$3"
  realm_certificate_list="$4"
  echo "detected $type certificate for realm '$realm': $(basename "$file")"
  key_file="$BASE_PATH/$realm/$(basename "$file" .crt).pem"
  # if certificate is not root certificate, it needs a corresponding key file
  if [ -f "$key_file" ] || [ "$type" = "root" ]; then
    # calculate identifier for certificate
    identifier="$(openxpkiadm certificate id --file "$file")"
    # check if certificate is already imported
    if echo "$realm_certificate_list" | grep -q "$identifier"; then
      echo "IGNORING $file as it is already imported"
    else
      # import certificate depending on its type
      if [ "$type" = "root" ]; then
        openxpkiadm certificate import --file "$file" --realm "$realm"
        # No key file for root certificate

      elif [ "$type" = "vault" ]; then
        openxpkiadm certificate import --file "$file" --realm "$realm" --token datasafe
        alias=""
        alias_for_identifier "$realm" "$identifier" alias
        # key file of vault can not be moved to database -> rename it such that openxpki can find it
        cp "$key_file" "$BASE_PATH/$realm/$alias.pem"
      else
        openxpkiadm certificate import --file "$file" --realm "$realm" --token certsign
        alias=""
        alias_for_identifier "$realm" "$identifier" alias
        # insert certificate key into database (this requires an active openxpki server instance)
        openxpkicli set_data_pool_entry --arg namespace=sys.crypto.keys \
          --arg key="$alias" \
          --arg encrypt=1 \
          --filearg value="$key_file" --realm "$realm"
      fi
    fi
  else
    echo "IGNORING '$realm'/$(basename "$file"): No matching key file exists"
  fi
}

function do_realm_dir() {
  realm_dir="$1"
  realm="$(basename "$realm_dir")"
  realm_certificate_list=""
  if realm_certificate_list="$(openxpkiadm certificate list --realm "$realm")"; then
    # regular expressions for finding the right files
    root_regex=".*/\(.*_\)*$(echo "$realm")_root_ca\.crt"
    vault_regex=".*/\(.*_\)*$(echo "$realm")_datavault\(_.*\)*\.crt"
    issuing_regex=".*/\(.*_\)*$(echo "$realm")_issuing_ca\(_.*\)*\.crt"
    # start import process for detected root/vault/signing certificates
    for f in $(find "$realm_dir" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$root_regex"); do
      import_cert "$realm" "$f" "root" "$realm_certificate_list"
    done
    for f in $(find "$realm_dir" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$vault_regex"); do
      import_cert "$realm" "$f" "vault" "$realm_certificate_list"
    done
    for f in $(find "$realm_dir" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$issuing_regex"); do
      import_cert "$realm" "$f" "signer" "$realm_certificate_list"
    done
  else
    echo "IGNORING directory $realm ..."
  fi
}
# enable monitor, then start openxpki server (without forking) and put it to background
# this is necessary as openxpkicli requires a running openxpki instance
set -m
/usr/bin/openxpkictl start --no-detach &
# time for openxpki to initialize
sleep 10
#look for realm folders and export contained certificates
for D in $(find "$BASE_PATH" -mindepth 1 -maxdepth 1 -type d); do
  do_realm_dir "$D"
done
#after certificates have been imported put openxpki in foreground again
fg %1
