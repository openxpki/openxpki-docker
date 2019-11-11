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

This will expose the OpenXPKI WebUI via `http://localhost:8080` (**unencrypted**!) with the sample configuration but without any tokens. Place your keys and certificates into the `ca` directory of the config directory and follow the instructions given in the quickstart tutorial: https://openxpki.readthedocs.io/en/latest/quickstart.html#setup-base-certificates.

## Prebuild images

Prebuild images for the official releases are provided by WhiteRabbitSecurity via a public Docker repository `whiterabbitsecurity/openxpki3`. 

Those are also used by the docker-compose file.

## Building your own images

The Dockerfile creates a container based on Debian Jessie using prebuild deb packages which are downloaded from the OpenXPKI package mirror (https://packages.openxpki.org).

The image has all code components installed but comes without any configuration.

The easiest way to start is to clone the `docker` branch from the openxpki-config repository from github `https://github.com/openxpki/openxpki-config` and mount it to `/etc/openxpki`.

As the container comes without a database engine installed, you must setup a database container yourself and put the connection details into `config.d/system/database.yaml`.

### WebUI

The container runs only the OpenXPKI daemon but not the WebUI frontend. You can either start apache inside the container or create a second container from the same image that runs the UI. In this case you must create a shared volume for the communication socket mounted at `/var/openxpki/` (this will be changed to (`/run/openxpki/` with one of the next releases!).

## Helpers

### Automatic import of certificates

Start the server container and run `setup-cert` to setup the CA certificates and matching keys. The artifacts need to be placed in `openxpki-config/ca/[REALM]/` and file names must match one of the following patterns (case insensitive):

`[...]_[REALM]_ROOT_CA[_[...]].crt` for root certificates
`[...]_[REALM]_ISSUING_CA[_[...]].crt` for signer certificates
`[...]_[REALM]_DATAVAULT[_[...]].crt` for vault certificates

The corresponding key files must have the same basename with file ending (*.pem)

Certificates/keys for data vault can also be placed in `openxpki-config/ca/`. Then, the startup script will detect it and create aliases for all realms.

All key files (except for data vault) are stored in the database so make sure all other tokens (e.g. certsign) are configured correctly:
```
    key_store: DATAPOOL
    key: "[% ALIAS %]"
```

### Automatic setup of custom translations

Translations are done using gettext. By default the container comes with a file that covers translations of the sample config and the backend. If you need to modify or extend the translations, you must generate your own po file.

Create a folder `openxpki-config/i18n/en_US` and place your overrides/extensions in one or muliple files ending with `.po`. When you need to update the internal translations, either create a file `openxpki-config/i18n/.update` (can be empty) or run `update-i18n` inside the container. The script will merge the contents of `contrib/i18n/` with your local extensions, so make sure you update this when you install a new release. You need to restart the client container afterwards to pull in the new translation file.
