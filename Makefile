
HERE = $(shell pwd)

DOCKER ?= docker

ifneq ($(FORCE),)
	OPENAPI_GENERATOR_OPTIONS ?= --skip-validate-spec
endif

OPENAPI_GENERATOR_DOCKER_IMAGE ?= openapitools/openapi-generator-cli:v6.4.0
export DEFAULT_PREVIOUS_VERSION ?= 0.0.1
export PREVIOUS_VERSION ?= $(DEFAULT_PREVIOUS_VERSION)
export NEW_VERSION ?= $(PREVIOUS_VERSION)

NPM_PREFIX_GLOBAL ?= $(shell npm prefix -g)

.PHONY: setup_google_artifact_registry
setup_google_artifact_registry:
	gcloud auth configure-docker northamerica-northeast2-docker.pkg.dev

.PHONY: merge
merge: merge--index merge--cloudflare merge--content merge--identity merge--profile

merge--%:
	npx speccy resolve --internal-refs specs/$*.yaml -o build/$*.yaml

.PHONY: filter
filter: merge filter--index filter--cloudflare filter--content filter--identity filter--profile

filter--%:
	cat $(HERE)/build/$*.yaml > $(HERE)/build/$*-filtered.yaml
	# Only delete "id" properties which are siblings of a "$schema", otherwise we'd sabotage our DB "id" fields.
	yq --inplace 'del(.. | .["$$schema"]? | parent | .id?)' $(HERE)/build/$*-filtered.yaml
	yq --inplace 'del(.. | .["$$schema"]?)' $(HERE)/build/$*-filtered.yaml
	yq --inplace '(.. | select(has("const")) | .const | key) |= "default"' $(HERE)/build/$*-filtered.yaml
	yq --inplace '.info.version = "'$(NEW_VERSION)'"' $(HERE)/build/$*-filtered.yaml
	yq --output-format=json '.' $(HERE)/build/$*-filtered.yaml > $(HERE)/build/$*-filtered.json

.PHONY: filterdiff
filterdiff: filter filterdiff--index

filterdiff--%:
	yq '.' $(HERE)/build/$*.yaml > $(HERE)/build/$*-yq.yaml
	git diff --no-index build/$*-yq.yaml build/$*-filtered.yaml

.PHONY: gen_openapi_client
gen_openapi_client: filter gen_openapi_client--index

gen_openapi_client--%:
	-mkdir -p $(HERE)/build/gen/typescript-axios/$*
	cp $(HERE)/gen/openapi-generator/typescript-axios.config.yaml $(HERE)/build/gen/typescript-axios.config.yaml

	# If this fails with "Exception in thread "main" java.lang.RuntimeException: Could not generate model 'XYZ'"
	# then try removing the `--user` CLI option. That option is needed in CI/CD in Github Actions, though.
	# Exact reason why it's needed there and not on local, TBD.
	$(DOCKER) \
		run --rm \
		--user $(shell id -u):$(shell id -g) \
		--volume $(HERE)/build:/build \
		$(OPENAPI_GENERATOR_DOCKER_IMAGE) \
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
		$(OPENAPI_GENERATOR_OPTIONS) \
		--output /build/gen/typescript-axios/$*

.PHONY: gen_single_spec_bundled_npm_pkg
gen_single_spec_bundled_npm_pkg: filter gen_single_spec_bundled_npm_pkg--index gen_single_spec_bundled_npm_pkg--cloudflare gen_single_spec_bundled_npm_pkg--content gen_single_spec_bundled_npm_pkg--identity gen_single_spec_bundled_npm_pkg--profile

gen_single_spec_bundled_npm_pkg--%:
	-mkdir -p $(HERE)/build/gen/single-spec-bundled-npm-pkg/$*
	node $(HERE)/gen/single-spec-bundled-npm-pkg/write-package.mjs $(HERE)/build/gen/single-spec-bundled-npm-pkg/$* $(HERE)/build/$*-filtered.json

.PHONY: gen_all_specs_unbundled_npm_pkg
gen_all_specs_unbundled_npm_pkg:
	./scripts/gen_all_specs_unbundled_npm_pkg.sh $(HERE) $(NEW_VERSION)

.PHONY: ci_gha_install
ci_gha_install:
	sudo snap install yq
	npm ci

.PHONY: ci_gha
ci_gha: ci_gha_install gen_openapi_client fix_openapi_client_package_json gen_single_spec_bundled_npm_pkg gen_all_specs_unbundled_npm_pkg

.PHONY: fix_openapi_client_package_json
fix_openapi_client_package_json: gen_openapi_client fix_openapi_client_package_json--index

fix_openapi_client_package_json--%:
	# debug start
	ls -la $(HERE)/build/gen/typescript-axios/$*/package.json
	id
	# debug stop
	yq \
		--inplace \
		--output-format=json \
		'.repository.url = "https://github.com/cubeca/api-specs.git"' \
		$(HERE)/build/gen/typescript-axios/$*/package.json


.PHONY: install_local_tools
install_local_tools:
	brew install yq
