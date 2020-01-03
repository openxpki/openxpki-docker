# OpenXPKI@docker

## Using Docker Compose

The provided docker-compose provided creates three containers:

- Database (based on mysql:5.7)
- OpenXPKI Server
- OpenXPKI WebUI

Before running compose you **MUST** place a configuration directory named `openxpki-config` in the current directory, the easiest way is to clone the branch `docker` from the `openxpki-config` repository at github.

```bash
$ git clone https://github.com/openxpki/openxpki-config.git --branch=docker
$ docker-compose  up 
```

If you dont provide a TLS certificate for the webserver yourself (see below), the init script creates a self-signed one and exposes the webserver UI on port 8443 (`https://localhost:8443/openxpki/`). The SCEP and RPC interface is available via plain HTTP on port 8080 (`http://localhost:8080`). The system is started with the configuration found in the openxpki-config path, without tokens installed! Place your keys and certificates into the `ca` directory of the config directory and follow the instructions given in the quickstart tutorial: https://openxpki.readthedocs.io/en/latest/quickstart.html#setup-base-certificates.

## Prebuilt images

Prebuilt images for the official releases are provided by WhiteRabbitSecurity via a public Docker repository `whiterabbitsecurity/openxpki3`. 

Those are also used by the docker-compose file.

## Building your own images

The Dockerfile creates a container based on Debian Jessie using prebuilt deb packages which are downloaded from the OpenXPKI package mirror (https://packages.openxpki.org).

The image has all code components installed but comes without any configuration.

The easiest way to start is to clone the `docker` branch from the openxpki-config repository from github `https://github.com/openxpki/openxpki-config` and mount it to `/etc/openxpki`.

As the container comes without a database engine installed, you must setup a database container yourself and put the connection details into `config.d/system/database.yaml`.

### WebUI

The container runs only the OpenXPKI daemon but not the WebUI frontend. You can either start apache inside the container or create a second container from the same image that runs the UI. In this case you must create a shared volume for the communication socket mounted at `/var/openxpki/` (this will be changed to (`/run/openxpki/` with one of the next releases!).

## Helpers

### Automatic import of certificates

Start the server container and run `setup-cert` to setup the CA certificates and matching keys. The artifacts need to be placed in `openxpki-config/ca/[REALM]/` and file names must match one of the following patterns (case insensitive):

`root(-XX).crt` for root certificates
`ca-signer(-XX).crt` for signer certificates
`vault(-XX).crt` for vault certificates
`scep(-XX).crt` for vault certificates

The suffix -XX must contain only numbers and is used as generation identifier on import. If the suffix is omitted, the certificate is imported with the next available generation identifier. The corresponding key files must have the same basename with file ending (*.pem), the key file is copied to $alias.pem so it will be found by the default key specification of the sample config (if the file already exists, nothing is copied).

Certificates/keys for data vault can also be placed in `openxpki-config/ca/`. Then, the startup script will detect it and create aliases for all realms.

All key files (except for data vault) are stored in the database so make sure all other tokens (e.g. certsign) are configured correctly:
```yaml
    key_store: DATAPOOL
    key: "[% ALIAS %]"
```

### Automatic setup of custom translations

Translations are done using gettext. By default the container comes with a file that covers translations of the sample config and the backend. If you need to modify or extend the translations, you must generate your own po file.

Create a folder `openxpki-config/i18n/en_US` and place your overrides/extensions in one or muliple files ending with `.po`. When you need to update the internal translations, either create a file `openxpki-config/i18n/.update` (can be empty) or run `update-i18n` inside the **client** container. The script will merge the contents of `contrib/i18n/` with your local extensions, so make sure you update this when you install a new release. You need to restart the client container afterwards to pull in the new translation file.

