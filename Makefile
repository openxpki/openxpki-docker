DOCKER_DIR=$(shell basename $(dir $$PWD/.))
IMAGE = whiterabbitsecurity/openxpki3

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
	git clone  https://github.com/openxpki/openxpki-config --single-branch --branch=docker

compose: openxpki-config  ## call docker-compose, implies init
	docker-compose up

clean:  ## remove containers but keep volumes
	docker-compose stop || /bin/true
	docker rm $(DOCKER_DIR)_openxpki-client_1 $(DOCKER_DIR)_openxpki-server_1 $(DOCKER_DIR)_db_1 || /bin/true

purge:	clean  ## remove containers and volumes
	docker volume rm $(DOCKER_DIR)_openxpkidb $(DOCKER_DIR)_openxpkilog $(DOCKER_DIR)_openxpkisocket || /bin/true

purge-all: purge
	rm -rf openxpki-config

