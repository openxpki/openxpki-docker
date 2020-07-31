DOCKER_DIR=$(shell basename $(dir $$PWD/.))
IMAGE = whiterabbitsecurity/openxpki3
export COMPOSE_PROJECT_NAME=openxpki

-include Makefile.local

help:
	@grep '^[a-zA-Z]' Makefile | sort | awk -F ':.*?## ' 'NF==2 {printf "  %-26s%s\n", $$1, $$2}'

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
	git clone  https://github.com/openxpki/openxpki-config --single-branch --branch=community
	cp contrib/wait_on_init.yaml openxpki-config/config.d/system/local.yaml

compose: openxpki-config  ## call docker-compose, implies init
	docker-compose up

sample-config: ## run the sampleconfig script from contrib/ 
	docker exec -it $(shell docker ps -aqf "name=${COMPOSE_PROJECT_NAME}_openxpki-server_1") /bin/bash /etc/openxpki/contrib/sampleconfig.sh

restart-client: ## restart the client container
	docker restart ${COMPOSE_PROJECT_NAME}_openxpki-client_1

restart-server: ## restart the server container
	docker restart ${COMPOSE_PROJECT_NAME}_openxpki-server_1

clean:  ## remove containers but keep volumes
	docker-compose stop || /bin/true
	docker rm $(COMPOSE_PROJECT_NAME)_openxpki-client_1 $(COMPOSE_PROJECT_NAME)_openxpki-server_1 $(COMPOSE_PROJECT_NAME)_db_1 || /bin/true

purge:	clean  ## remove containers and volumes
	docker volume rm $(COMPOSE_PROJECT_NAME)_openxpkidb $(COMPOSE_PROJECT_NAME)_openxpkilog $(COMPOSE_PROJECT_NAME)_openxpkisocket || /bin/true

purge-all: purge
	rm -rf openxpki-config

