DOCKER_DIR=$(shell basename $(dir $$PWD/.))
IMAGE = whiterabbitsecurity/openxpki3
export COMPOSE_PROJECT_NAME=openxpki

-include Makefile.local

help:
	@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | awk -F ':.*?## ' 'NF==2 {printf "  %-26s%s\n", $$1, $$2}'

test:
	$(info $(DOCKER_DIR))

build:  ## rebuild openxpki image using Dockerfile
	docker build -t $(IMAGE) .

build-nocache:  ## rebuild openxpki image using Dockerfile
	docker build --no-cache -t $(IMAGE) .

prune:  ## prune unused images (all!)
	docker image prune -f

init: openxpki-config  ## clone initial config from github

openxpki-config:
	git clone  https://github.com/openxpki/openxpki-config --single-branch --branch=develop

compose: openxpki-config  ## call docker-compose, implies init
	cp -n local.yaml openxpki-config/config.d/local.yaml
	docker-compose up

clean:  ## remove containers but keep volumes
	docker-compose stop || /bin/true
	docker rm $(COMPOSE_PROJECT_NAME)_openxpki-client_1 $(COMPOSE_PROJECT_NAME)_openxpki-server_1 $(COMPOSE_PROJECT_NAME)_db_1 || /bin/true

purge:	clean  ## remove containers and volumes
	docker volume rm $(COMPOSE_PROJECT_NAME)_openxpkidb $(COMPOSE_PROJECT_NAME)_openxpkilog $(COMPOSE_PROJECT_NAME)_openxpkisocket || /bin/true

purge-all: purge
	rm -rf openxpki-config

