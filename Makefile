
HERE = $(shell pwd)

ifneq ($(FORCE),)
	OPENAPI_GENERATOR_OPTIONS ?= --skip-validate-spec
endif

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

# Link the BFF API client package(s) locally
# See https://docs.npmjs.com/cli/v9/commands/npm-link
# See https://www.geeksforgeeks.org/how-to-install-a-local-module-using-npm/
.PHONY: npm_link
npm_link:
	rm -rf $(HERE)/build/gen/
	make gen_openapi_client
	$(MAKE) npm_link--bff
	$(MAKE) npm_link--bff-auth

npm_link--%:
	cd $(HERE)/build/gen/typescript-axios/$* && \
	npm install && \
	npm run build && \
	npm link


.PHONY: npm_link_check
npm_link_check:
	ls -la $(NPM_PREFIX_GLOBAL)/lib/node_modules/\@cubeca

.PHONY: install_local_tools
install_local_tools:
	brew install yq
