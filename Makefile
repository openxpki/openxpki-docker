DOCKER_DIR=$(shell basename $(dir $$PWD/.))
IMAGE = whiterabbitsecurity/openxpki3

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
	sed -r "/driver:openxpki/d" openxpki-config/client.d/service/webui/default.yaml

compose: openxpki-config  ## call docker-compose, implies init
	docker compose up -d web

sample-config: ## run the sampleconfig script
	docker compose exec -u root  -it server /usr/share/doc/libopenxpki-perl/examples/sampleconfig.sh

restart-client: ## restart the client container
	docker compose restart client

restart-server: ## restart the server container
	docker compose restart server

restart-webui: ## restart the server container
	docker compose restart web

clean:  ## remove containers but keep volumes
	docker compose stop && docker compose rm

purge:	clean  ## remove containers and volumes
	docker volume rm $(COMPOSE_PROJECT_NAME)_openxpkidb $(COMPOSE_PROJECT_NAME)_openxpkilog $(COMPOSE_PROJECT_NAME)_openxpkisocket || /bin/true

purge-all: purge
	rm -rf openxpki-config

