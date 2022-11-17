
HERE = $(shell pwd)

DOCKER ?= docker
DOCKER_COMPOSE ?= docker-compose

export PROJECT_NAME ?= cube_api_mock
PROJECT_DOCKER_COMPOSE = $(DOCKER_COMPOSE) --project-name $(PROJECT_NAME) --file ./docker-compose.yaml --project-directory . --env-file ./.env

.PHONY: up
up:
	$(PROJECT_DOCKER_COMPOSE) up -d --force-recreate

.PHONY: down
down:
	$(PROJECT_DOCKER_COMPOSE) down

.PHONY: clean
clean:
	-$(PROJECT_DOCKER_COMPOSE) rm
	-$(DOCKER) container rm $(PROJECT_NAME)_stoplightio_prism
	-$(DOCKER) image rm $(PROJECT_NAME)_stoplightio_prism

.PHONY: logs
logs:
	$(PROJECT_DOCKER_COMPOSE) logs -f

.PHONY: merge
merge:
	npx speccy resolve -i specs/bff.yaml -o build/bff.yaml

.PHONY: req_auth
req_auth:
	curl http://localhost:8080/auth/token \
		--request POST \
		--data "username=me&password=secret&grant_type=password&scope=art_org&client_id=FRONTEND_CLIENT_ID" \
		--header "Accept: application/json" \
		--header "Content-Type: application/x-www-form-urlencoded" \
		--include

.PHONY: req_auth_broken
req_auth_broken:
	curl http://localhost:8080/auth/token \
		--request POST \
		--data "username=me&grant_type=password&scope=art_org&client_id=FRONTEND_CLIENT_ID" \
		--header "Accept: application/json" \
		--header "Content-Type: application/x-www-form-urlencoded" \
		--include

.PHONY: req_echo
req_echo:
	curl http://localhost:8080/echo \
		--request POST \
		--data '{"shout":"Hello CUBE"}' \
		--header "Authorization: Bearer FAKETOKEN" \
		--header "Accept: application/json" \
		--header "Content-Type: application/json" \
		--include


.PHONY: filter
filter: merge
	cat $(HERE)/build/bff.yaml > $(HERE)/build/bff-filtered.yaml
	yq --inplace 'del(.. | .["$$schema"]?)' $(HERE)/build/bff-filtered.yaml
	yq --inplace 'del(.. | .["$$id"]?)' $(HERE)/build/bff-filtered.yaml
	yq --inplace '(.. | select(has("const")) | .const | key) = "default"' $(HERE)/build/bff-filtered.yaml


.PHONY: filterdiff
filterdiff: filter
	yq '.' $(HERE)/build/bff.yaml > $(HERE)/build/bff-yq.yaml
	git diff --no-index build/bff-yq.yaml build/bff-filtered.yaml


.PHONY: gen_openapi
gen_openapi: filter
	-mkdir -p $(HERE)/build/gen/typescript-axios
	cp $(HERE)/gen/openapi-generator/typescript-axios.config.yaml $(HERE)/build/gen/typescript-axios.config.yaml
	$(DOCKER) \
		run --rm \
		--volume $(HERE)/build:/build \
		openapitools/openapi-generator-cli \
		generate \
		--input-spec /build/bff-filtered.yaml \
		--generator-name typescript-axios \
		--config /build/gen/typescript-axios.config.yaml \
		--global-property verbose=true \
		--global-property apiDocs=true \
		--global-property modelDocs=true \
		--global-property apiTests=true \
		--global-property modelTests=true \
		--output /build/gen/typescript-axios


		# --env GIT_USER_ID=cubeca \
		# --env GIT_REPO_ID=api-specs \


.PHONY: gen_openapi_help
gen_openapi_help:
	$(DOCKER) \
		run --rm \
		openapitools/openapi-generator-cli \
		help


.PHONY: gen_openapi_help_generate
gen_openapi_help:
	$(DOCKER) \
		run --rm \
		openapitools/openapi-generator-cli \
		help \
		generate


.PHONY: gen_openapi_config_help
gen_openapi_config_help:
	$(DOCKER) \
		run --rm \
		openapitools/openapi-generator-cli \
		config-help \
		--generator-name typescript-axios


# .PHONY: gen_kiota
# gen_kiota: filter
# 	-mkdir -p $(HERE)/build/gen/typescript-kiota
# 	$(DOCKER) \
# 		run --rm \
# 		--volume $(HERE)/build:/build \
# 		mcr.microsoft.com/openapi/kiota \
# 		generate \
# 		--language TypeScript \
# 		--openapi /build/bff-filtered.yaml \
# 		--output /build/gen/typescript-kiota \
# 		--class-name CubeApiClient \
# 		--namespace-name cubedao
#
#
# .PHONY: gen_kiota_help
# gen_kiota_help:
# 	$(DOCKER) run --rm \
# 		mcr.microsoft.com/openapi/kiota \
# 		generate \
# 		--help


.PHONY: ci_gha_install
ci_gha_install:
	sudo snap install yq
	npm ci


.PHONY: ci_gha
ci_gha: ci_gha_install
	$(MAKE) gen_openapi
	echo ".npmrc" >> $(HERE)/build/gen/typescript-axios/.npmignore
	cp $(HERE)/.npmrc $(HERE)/build/gen/typescript-axios/.npmrc
	cat $(HERE)/build/gen/typescript-axios/package.json | jq '.repository.url = "https://github.com/cubeca/api-specs.git"' > $(HERE)/build/gen/typescript-axios/package-edited.json
	mv $(HERE)/build/gen/typescript-axios/package-edited.json $(HERE)/build/gen/typescript-axios/package.json
