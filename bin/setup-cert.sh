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
  echo "detected $type certificate for realm '$realm': $(basename "$file")"
  key_file="$BASE_PATH/$realm/$(basename "$file" .crt).pem"
  # if certificate is not root certificate, it needs a corresponding key file
  if [ -f "$key_file" ] || [ "$type" = "root" ]; then
    # calculate identifier for certificate
    identifier="$(openxpkiadm certificate id --file "$file")"
    # check if certificate is already imported
    if openxpkicli get_cert --realm "$realm" --arg identifier="$identifier" >/dev/null 2>/dev/null; then
      echo "IGNORING $file as it is already imported"
    else
      # import certificate depending on its type
      if [ "$type" = "root" ]; then
        openxpkiadm certificate import --file "$file"
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
  if openxpkiadm certificate list --realm "$realm" >/dev/null; then
    # regular expressions for finding the right files
    root_regex=".*/\(.*_\)*$(echo "$realm")_root_ca\(_.*\)*\.crt"
    vault_regex=".*/\(.*_\)*$(echo "$realm")_datavault\(_.*\)*\.crt"
    issuing_regex=".*/\(.*_\)*$(echo "$realm")_issuing_ca\(_.*\)*\.crt"

    vault_cert_location="global"
    # start import process for detected root/vault/signing certificates
    for f in $(find "$realm_dir" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$root_regex"); do
      import_cert "$realm" "$f" "root"
    done
    for f in $(find "$realm_dir" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$vault_regex"); do
      import_cert "$realm" "$f" "vault"
      vault_cert_location="local"
    done

    # if no local datavault certificate/key was found: look for global cert/key in ../
    if [ "$vault_cert_location" = "global" ]; then
      echo "searching for global vault certificate"
      for f in $(find "$BASE_PATH" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$vault_regex"); do
        key_file="$BASE_PATH/$(basename "$f" .crt).pem"
        if [ -f "$key_file" ]; then
          # import vault certificate globally
          openxpkiadm certificate import --file "$f"
          #set realm alias
          vault_identifer="$(openxpkiadm certificate id --file "$f")"
          openxpkiadm alias --realm "$realm" --token datasafe --identifier $vault_identifer
          #get alias name for imported certificate
          vault_alias=""
          alias_for_identifier "$realm" "$vault_identifer" vault_alias
          #copy vault key to realm folder (otherwise openxpki can not find it)
          cp "$key_file" "$BASE_PATH/$vault_alias.pem"
        else
          echo "IGNORING $(basename "$f"): No matching key file exists"
        fi
      done
    fi
    for f in $(find "$realm_dir" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$issuing_regex"); do
      import_cert "$realm" "$f" "signer"
    done

  else
    echo "IGNORING directory $realm ..."
  fi
}

#look for realm folders and export contained certificates
for D in $(find "$BASE_PATH" -mindepth 1 -maxdepth 1 -type d); do
  do_realm_dir "$D"
done
