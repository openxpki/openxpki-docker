# OpenXPKI with Docker

## Prebuilt Images

Prebuilt images for the official releases are provided by White Rabbit Security via a public Docker repository on DockerHub `whiterabbitsecurity/openxpki3`. Those are created from the `Dockerfile` found in this repository.

## Container Layout

This repository contains a `docker-compose.yml` that spawns four containers

- Database (based on mariadb:10)
- OpenXPKI Server
- OpenXPKI Client
- OpenXPKI WebUI

## Configuration

Before running compose you **MUST** place a configuration directory named `openxpki-config` in the current directory, the easiest way is to clone the branch `community` from the `openxpki-config` repository at github.

```bash
$ git clone https://github.com/openxpki/openxpki-config.git \
	--single-branch --branch=community
```

The remainder of this guide is based on an unmodified confguration, if you want to run your adapted configuration you might need to adapt the steps.

### Database Configuration

The example configuration uses the same passwords as those given in the compose file,
if you change them, also update them in `config.d/system/database.yaml`.

### Session Storage Driver

You **MUST** configure the session storage driver for the WebUi in
`client.d/service/webui/default.yaml` by either:

  creating the user and permissions on the database as outlined in the [QUICKSTART](https://github.com/openxpki/openxpki/blob/master/QUICKSTART.md) document

*or*

  Disable the database driver to fall back to the file system storage driver

Do **NOT** use the same credentials as for the backend database as this
gives the frontend client full database access which is a security risk!
You might deviate from this for a local test run, but you have been warned!

### Webserver Certificate

The webserver container maps the folder `openxpki-config/tls/` to `/etc/openxpki/tls/`, the related configuration items are: 

```ini
SSLCertificateFile /etc/openxpki/tls/endentity/openxpki.crt
SSLCertificateChainFile /etc/openxpki/tls/endentity/openxpki.crt
SSLCertificateKeyFile /etc/openxpki/tls/private/openxpki.pem
SSLCACertificatePath /etc/openxpki/tls/chain/
```

Place certificate and key in the given places. The `chain` folder is used to validate incoming TLS Client request, it must in any case hold a single file as the apache does not start otherwise. If you do not provide any files, dummy certificates will be created on first startup. 

## Bring It Up

The old `docker-compose` (Version 1) is no longer supported, you need a recent version of `docker`with the `compose` plugin. It should be sufficient to start the *web* container as this depends on all others so they will also be started:

```bash
$ docker compose up -d web 

[+] Running 4/4
 ✔ Container OpenXPKI_Database  Healthy                                    0.5s 
 ✔ Container OpenXPKI_Server    Running                                    0.0s 
 ✔ Container OpenXPKI_Client    Running                                    0.0s 
 ✔ Container OpenXPKI_WebUI     Running                                    0.0s 

```

In case you have `make` installed you can also just run `make compose` which does all the above for you.

The system should now be up and running and you can access the WebUI via https://localhost:8443/webui/index/.

You can already have a look around but to issue certificates you need to generate and import your Root and Issuing CA certificates and load them into the system.

## Issuing CA Setup

### Production

To import your own keys and certificates follow the instructions given in the QUICKSTART tutorial. If you want to setup a two-tier hierarchy we recommend using our command line ca tool `clca` (https://github.com/openxpki/clca).

### Testdrive

The repository comes with a bootstrap script, that generates a two-tier PKI hierarchy and prepares anything "ready-to-go".

```bash
$ docker compose exec -u root  -it server /usr/share/doc/libopenxpki-perl/examples/sampleconfig.sh
```

If you have `make` installed, just run `make sample-config` which will run the above command for you.

## Troubleshooting

### 500 Server Error / No WebUI

Most likely your session storage driver setup is broken, check the logs of the client container. 

### Running on SELinux

Some distros, e.g. CentOS/RHEL, have SELinux enabled by default which will likely prevent the docker container to read the mounted config volume. You can work around this by adding a `:z` to the volume path in the docker-compose.yml - please read https://github.com/moby/moby/issues/30934 **before** doing so as it can make your system unusable!

### Running on Windows

The sample configuration uses a so called symlink to a template directory to create the "democa". Windows does not support symlinks and when you clone
and mount the repository from a host running windows this configuration is missing. If you get `No workflow configuration found for current realm`
when starting OpenXPKI try to replace the (broken) symlink in openxpki-config/config.d/realm by a full copy.

Another option is to activate symlink emulation in git, see https://github.com/git-for-windows/git/wiki/Symbolic-Links.

