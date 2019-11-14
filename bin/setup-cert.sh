#!/bin/bash
BASE_PATH="/etc/openxpki/ca"

#computes alias for identifier
function alias_for_identifier() {
  declare -n ret=$3
  ret="$(openxpkiadm alias --realm "$1" | perl -0777 -ne "\$str=\$_; print \$str =~ /Alias\s*:\s*(.*)\s*\n\s*Identifier\s*:\s*$2/ ;")"
}
# carries out the whole import process
# Parameters: [1]: realm (e.g. "ca-one") [2]: path to certificate file [3]: certificate type
function import_cert() {
  realm="$1"
  file="$2"
  type="$3"
  echo "detected $type certificate for realm '$realm': $(basename "$file")"
  #expected location of keyfile
  key_file="$BASE_PATH/$realm/$(basename "$file" .crt).pem"
  #extract optional generation parameter which is part of the file name
  generation="$( echo "$file" | sed -rn 's/.*-([0-9]+)\.crt/\1/p')"
  # calculate identifier for certificate
  identifier="$(openxpkiadm certificate id --file "$file")"
  # check if certificate is already imported
  if openxpkicli get_cert --realm "$realm" --arg identifier="$identifier" >/dev/null 2>/dev/null; then
    echo "IGNORING $file as it is already imported"
  else
      #import certificate with/without generation
      if [ ! -z "$generation" ]; then
        openxpkiadm certificate import --file "$file" --realm "$realm" --token "$type" --generation $generation
      else
        openxpkiadm certificate import --file "$file" --realm "$realm" --token "$type"
      fi
      if [ ! -f "$key_file" ]; then
        echo "WARNING: '$realm'/$(basename "$file"): No matching key file exists"
      else
        #move keyfile to the right place so that it can be found by openxpki
        alias=""
        alias_for_identifier "$realm" "$identifier" alias
        cp -n "$key_file" "$BASE_PATH/$realm/$alias.pem"
      fi
  fi

}

function do_realm_dir() {
  realm_dir="$1"
  realm="$(basename "$realm_dir")"
  if openxpkiadm certificate list --realm "$realm" >/dev/null; then
    # regular expressions for finding the right files
    root_regex=".*/root\(-[0-9]*\)\{0,1\}\.crt"
    vault_regex=".*/vault\(-[0-9]*\)\{0,1\}\.crt"
    issuing_regex=".*/ca-signer\(-[0-9]*\)\{0,1\}\.crt"
    scep_regex=".*/scep\(-[0-9]*\)\{0,1\}\.crt"

    # look for global vault cert/key in ../
    for f in $(find "$BASE_PATH" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$vault_regex"); do
        key_file="$BASE_PATH/$(basename "$f" .crt).pem"
        if [ -f "$key_file" ]; then
          vault_identifier="$(openxpkiadm certificate id --file "$f")"
          if openxpkicli get_cert --realm "$realm" --arg identifier="$vault_identifier" >/dev/null 2>/dev/null; then
            echo "vault certificate already imported"
          else
            # import vault certificate globally
            openxpkiadm certificate import --file "$f"
            #set realm alias
            openxpkiadm alias --realm "$realm" --token datasafe --identifier "$vault_identifier"
            alias=""
            alias_for_identifier "$realm" "$identifier" alias
            cp -n "$key_file" "$BASE_PATH/$alias.pem"
          fi
        else
          echo "IGNORING $(basename "$f"): No matching key file exists"
        fi
    done
    #import root certificate
    for f in $(find "$realm_dir" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$root_regex"); do
      root_identifer="$(openxpkiadm certificate id --file "$f")"
      if openxpkicli get_cert --realm "$realm" --arg identifier="$root_identifer" >/dev/null 2>/dev/null; then
        echo "root certificate already imported"
      else
        echo "importing root"
        openxpkiadm certificate import --file "$f"
      fi
    done
    #generic import of certsign/scep tokens
    for f in $(find "$realm_dir" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$scep_regex"); do
      import_cert "$realm" "$f" "scep"
    done
    for f in $(find "$realm_dir" -mindepth 1 -maxdepth 1 -type f -regextype sed -iregex "$issuing_regex"); do
      import_cert "$realm" "$f" "certsign"
    done

  else
    echo "IGNORING directory $realm ..."
  fi
}

#look for realm folders and export contained certificates
for D in $(find "$BASE_PATH" -mindepth 1 -maxdepth 1 -type d); do
  do_realm_dir "$D"
done
