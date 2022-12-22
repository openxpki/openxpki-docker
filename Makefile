DOCKER_DIR=$(shell basename $(dir $$PWD/.))
IMAGE = whiterabbitsecurity/openxpki3
export COMPOSE_PROJECT_NAME=openxpki-docker

-include Makefile.local

help:
	@grep '^[a-zA-Z]' Makefile | sort | awk -F ':.*?## ' 'NF==2 {printf "  %-26s%s\n", $$1, $$2}'

test:
	$(info $(DOCKER_DIR))

build:  ## DockerFileを使用してOpenXPKI imageを再構築します
	docker build -t $(IMAGE) .

build-nocache:  ## DockerFileを使用してOpenXPKI imageを再構築します
	docker build --no-cache -t $(IMAGE) .

up: ## call docker-compose up -d
	docker compose up --build -d

down: ## call docker compose down
	docker compose down

restart: ## call docker compose restart
	docker compose restart

sample-config: ## contrib/からsampleconfigスクリプトを実行する
	docker exec -it $(shell docker ps -aqf "name=${COMPOSE_PROJECT_NAME}-openxpki-server-1") /bin/bash /etc/openxpki/contrib/sampleconfig.sh

restart: ## サーバーコンテナを再起動します
	docker compose restart

clean:  ## コンテナを削除しますが、ボリュームを保持します
	docker compose stop || /bin/true
	docker rm $(COMPOSE_PROJECT_NAME)-openxpki-server-1 $(COMPOSE_PROJECT_NAME)-db-1 || /bin/true

purge:	clean  ## コンテナとボリュームを削除します
	docker volume rm $(COMPOSE_PROJECT_NAME)_openxpkidb $(COMPOSE_PROJECT_NAME)_openxpkidbsocket $(COMPOSE_PROJECT_NAME)_openxpkilog $(COMPOSE_PROJECT_NAME)_openxpkisocket || /bin/true
