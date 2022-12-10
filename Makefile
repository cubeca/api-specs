
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


MOCK_SERVER_DOCKER_IMAGE = cubeca/bff_mock_server:latest

.PHONY: mock_build
mock_build:
	docker build \
	--file ./mock-server.dockerfile \
	--tag $(MOCK_SERVER_DOCKER_IMAGE) \
	.

.PHONY: mock_run
mock_run:
	docker run \
	--rm \
	--detach \
	--publish 8080:4010 \
	$(MOCK_SERVER_DOCKER_IMAGE)


.PHONY: setup_google_artifact_registry
setup_google_artifact_registry:
	gcloud auth configure-docker northamerica-northeast2-docker.pkg.dev


.PHONY: req_echo
req_echo:
	curl http://localhost:8080/echo \
		--request POST \
		--data '{"shout":"Hello CUBE"}' \
		--header "Authorization: Bearer FAKETOKEN" \
		--header "Accept: application/json" \
		--header "Content-Type: application/json" \
		--include


.PHONY: merge
merge: merge--bff merge--bff-auth

merge--%:
	npx speccy resolve -i specs/$*.yaml -o build/$*.yaml


.PHONY: filter
filter: merge filter--bff filter--bff-auth

filter--%:
	cat $(HERE)/build/$*.yaml > $(HERE)/build/$*-filtered.yaml
	yq --inplace 'del(.. | .["$$schema"]?)' $(HERE)/build/$*-filtered.yaml
	yq --inplace 'del(.. | .["$$id"]?)' $(HERE)/build/$*-filtered.yaml
	yq --inplace '(.. | select(has("const")) | .const | key) = "default"' $(HERE)/build/$*-filtered.yaml
	yq --output-format=json '.' $(HERE)/build/$*-filtered.yaml > $(HERE)/build/$*-filtered.json

.PHONY: filterdiff
filterdiff: filter filterdiff--bff filterdiff--bff-auth

filterdiff--%:
	yq '.' $(HERE)/build/$*.yaml > $(HERE)/build/$*-yq.yaml
	git diff --no-index build/$*-yq.yaml build/$*-filtered.yaml


.PHONY: gen_openapi
gen_openapi_client: filter gen_openapi_client--bff gen_openapi_client--bff-auth

gen_openapi_client--%:
	-mkdir -p $(HERE)/build/gen/typescript-axios/$*
	cp $(HERE)/gen/openapi-generator/typescript-axios.config.yaml $(HERE)/build/gen/typescript-axios.config.yaml
	$(DOCKER) \
		run --rm \
		--volume $(HERE)/build:/build \
		openapitools/openapi-generator-cli \
		generate \
		--input-spec /build/$*-filtered.yaml \
		--generator-name typescript-axios \
		--config /build/gen/typescript-axios.config.yaml \
		--global-property verbose=true \
		--global-property apiDocs=true \
		--global-property modelDocs=true \
		--global-property apiTests=true \
		--global-property modelTests=true \
		--additional-properties=npmName="@cubeca/$*-client-oas-axios" \
		--output /build/gen/typescript-axios/$*


.PHONY: gen_openapi_help
gen_openapi_help:
	$(DOCKER) \
		run --rm \
		openapitools/openapi-generator-cli \
		help


.PHONY: gen_openapi_help_generate
gen_openapi_help_generate:
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


.PHONY: ci_gha_install
ci_gha_install:
	sudo snap install yq
	npm ci


.PHONY: ci_gha
ci_gha: ci_gha_install gen_openapi_client fix_package_json


.PHONY: fix_package_json
fix_package_json: gen_openapi_client fix_package_json--bff fix_package_json--bff-auth

fix_package_json--%:
	cat $(HERE)/build/gen/typescript-axios/$*/package.json | jq '.repository.url = "https://github.com/cubeca/api-specs.git"' > $(HERE)/build/gen/typescript-axios/$*/package-edited.json
	mv $(HERE)/build/gen/typescript-axios/$*/package-edited.json $(HERE)/build/gen/typescript-axios/$*/package.json
