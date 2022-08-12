
DOCKER ?= docker
DOCKER_COMPOSE ?= docker-compose

export PROJECT_NAME ?= cube_api_mock
PROJECT_DOCKER_COMPOSE = $(DOCKER_COMPOSE) --project-name $(PROJECT_NAME) --file ./docker-compose.yaml --project-directory . --env-file ./.env

up:
	$(PROJECT_DOCKER_COMPOSE) up -d --force-recreate

down:
	$(PROJECT_DOCKER_COMPOSE) down

clean:
	-$(PROJECT_DOCKER_COMPOSE) rm
	-$(DOCKER) container rm $(PROJECT_NAME)_stoplightio_prism
	-$(DOCKER) image rm $(PROJECT_NAME)_stoplightio_prism

logs:
	$(PROJECT_DOCKER_COMPOSE) logs -f

merge:
	npx speccy resolve -i specs/bff.yaml -o build/bff.yaml

req_auth:
	curl http://localhost:8080/auth/token \
		--request POST \
		--data "username=me&password=secret&grant_type=password&scope=art_org&client_id=FRONTEND_CLIENT_ID" \
		--header "Accept: application/json" \
		--header "Content-Type: application/x-www-form-urlencoded" \
		--include

req_auth_broken:
	curl http://localhost:8080/auth/token \
		--request POST \
		--data "username=me&grant_type=password&scope=art_org&client_id=FRONTEND_CLIENT_ID" \
		--header "Accept: application/json" \
		--header "Content-Type: application/x-www-form-urlencoded" \
		--include

req_echo:
	curl http://localhost:8080/echo \
		--request POST \
		--data '{"shout":"Hello CUBE"}' \
		--header "Authorization: Bearer FAKETOKEN" \
		--header "Accept: application/json" \
		--header "Content-Type: application/json" \
		--include
