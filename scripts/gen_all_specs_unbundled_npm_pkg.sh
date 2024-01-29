#!/usr/bin/env bash

# Make Bash's error handling strict(er).
set -o nounset -o pipefail -o errexit

export HERE=$1
export NEW_VERSION=$2

mkdir -p ${HERE}/build/gen/all-specs-unbundled-npm-pkg
cp -rp ${HERE}/schemas ${HERE}/build/gen/all-specs-unbundled-npm-pkg/schemas

find specs -type f | while read yaml_file; do
  source=${HERE}/$yaml_file
  target=${HERE}/build/gen/all-specs-unbundled-npm-pkg/${yaml_file%.yaml}.json
  mkdir -p `dirname ${target}`
  yq '.' ${source} --output-format=json > ${target}
  yq '(.. | select(has("$ref")) | .["$ref"]) |= sub(".yaml", ".json")' --inplace --output-format=json ${target}
done

API_IDS=,
while read api_id; do
  yq '.info.version = "'${NEW_VERSION}'"' --inplace --output-format=json ${HERE}/build/gen/all-specs-unbundled-npm-pkg/specs/${api_id}.json
  API_IDS=${API_IDS},$api_id
done <<EOF
cube-svc
cloudflare
content
identity
profile
EOF

node ${HERE}/gen/all-specs-unbundled-npm-pkg/write-package.mjs ${HERE}/build/gen/all-specs-unbundled-npm-pkg ${NEW_VERSION} ${API_IDS}
