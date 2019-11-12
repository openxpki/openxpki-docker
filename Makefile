help:
	@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | awk -F ':.*?## ' 'NF==2 {printf "  %-26s%s\n", $$1, $$2}'

build:  ## rebuild openxpki image using Dockerfile
	docker build -t whiterabbitsecurity/openxpki3 . 

build-nocache:  ## rebuild openxpki image using Dockerfile
	docker build --no-cache -t whiterabbitsecurity/openxpki3 . 

prune:  ## prune unused images (all!)
	docker image prune -f

init: openxpki-config  ## clone initial config from github

openxpki-config:
	git clone  https://github.com/openxpki/openxpki-config --single-branch --branch=docker

compose: openxpki-config  ## call docker-compose, implies init
	docker-compose up

clean:  ## remove containers but keep volumes
	docker-compose stop || /bin/true
	docker rm openxpki-docker_openxpki-client_1 openxpki-docker_openxpki-server_1 openxpki-docker_db_1 || /bin/true

purge:	clean  ## remove containers and volumes
	docker volume rm openxpki-docker_openxpkidb openxpki-docker_openxpkilog openxpki-docker_openxpkisocket || /bin/true

purge-all: purge
	rm -rf openxpki-config

