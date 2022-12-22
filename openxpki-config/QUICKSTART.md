# OpenXPKI Quickstart Guide

*Prerequisites*: You have installed the OpenXPKI packages and the apache webserver and have a working database installation in place and have the contents of the configuration repository to `/etc/openxpki`.

The default configuration comes with a realm named `democa` which is used in this documentation as placeholder whenever a step needs to be done for a special realm. You need to replace `democa` with the actual name of the realm you are working on.

### Init Database

You can find the schema for the supported database systems in `contrib/sql` - choose the one for your favorite RDBMS and create the initial schema from it. SQLite should not be used for production setups as it is not thread-safe and does not support all features.

Place the connection details for the database in `config.d/system/database.yaml`.

Note that the driver names are case sensitive: `MariaDB`, `MySQL`, `PostgreSQL`, `Oracle`, `SQLite`.

### Setup Tokens

#### Internal Datavault

Create a key for the Datavault Token (RSA 3072) and place it to `ca/vault-1.pem`. The passphrase of this key is the value referenced via the secret group in the file `config.d/system/crypto.yaml`. Use this key to create a self-signed certificate with a validity of one year and a common name "DataVault".

```bash
$ openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:3072 -aes-256-cbc \
	-out ca/vault-1.pem
$ openssl req -x509 -subj "/CN=DataVault" -days 365 -extensions usr_cert \
	-key ca/vault-1.pem -out ca/vault-1.crt
```

Now import the certificate into OpenXPKI, if you have multiple realms, you must run the second command for each realm:

```bash
$ openxpkiadm certificate import --file ca/vault-1.crt
$ openxpkiadm alias --realm democa --token datasafe --file ca/vault-1.crt
```

Make sure that the access permissions are properly set so the OpenXPKI server can read the file - recommended settings are permissions set to 0400 owned by the OpenXPKI user.

#### Issuing CA

Creation of the Root CA and the Issuing CA certificates is not part of OpenXPKI, we can recommend the [clca-Tool](https://github.com/openxpki/clca) for this purpose.

If you have a 2-Tier hierarchy, please import the Root CA certificate before you proceed:

```bash
$ openxpkiadm certificate import --file root.crt
```

If you have multiple roots or a deeper hierarchy please import all certificates that will not be signer tokens to the current installation. Always start with the self-signed root.

##### Software Keys in Database

The default configuration uses the database as storage for the key blobs - if you think this does not meet your security requirements you can store the key blobs in the filesystem as described in the next section.

The `openxpkiadm` tool comes with a command that loads the private key and certificate into the system, the  prerequisite to use this command is a running OpenXPI server with a working DataVault token.

```bash
$ openxpkiadm alias --realm democa --token certsign --file signer.crt --key signer.pem
```

This will load the given certificate and key (both PEM encoded) into the database and register them as issuing ca token using the next available generation identifier. Make sure that you have imported the root ca certificate before.

The command will show the generated alias identifier (on an inital setup this is `ca-signer-1`), to check if the token was loaded properly run:

```bash
$ openxpkicli is_token_usable --realm=democa --arg alias=ca-signer-1
```

If anything went fine, this should print a literal `1`.

##### Software Keys in Filesystem

In case you want to have your key blobs in the local filesystem, you can directly place the keys in the correct locations yourself and omit the `--key` flag on the alias command.

The alias command also works with local files, but you need to create the parent folders with suitable permissions yourself and you must run the command as root as the script will set the permissions on the files when creating them.

#### SCEP Token

The SCEP certificate should be a TLS Server certificate issued by the PKI. You can import it the same way as the other tokens:

```bash
openxpkiadm alias --realm democa --token scep --file scep.crt --key scep.pem
```

#### Webserver

You can find a working configuration for the Apache webserver in `contrib/apache2-openxpki-site.conf` - copy or symlink this to your webservers config directory (`/etc/apache2/sites-enabled/` on debian). This config exposes SCEP on Port 80 and the WebUI as well as the RPC and EST APIs on Port 443 via HTTPS.

The configuration expects the TLS key in `/etc/openxpki/tls/private/openxpki.pem` and the certificate (including its chain as concatenated PEM bundle) in`/etc/openxpki/tls/endentity/openxpki.crt`.

The configuration is also set up for TLS client authentication and expects at least a single CA certificate in `/etc/openxpki/tls/chain/`. In case you want to use the certificates created by this PKI copy over the issuing certificates to this folder and run `c_rehash /etc/openxpki/tls/chain/`. If you don't need TLS Client authentication you can remove the config block starting with `SSLCACertificatePath`.
