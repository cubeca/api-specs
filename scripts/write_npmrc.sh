#!/usr/bin/env bash

# Make Bash's error handling strict(er).
set -o nounset -o pipefail -o errexit

API=$1
GITHUB_TOKEN=$2
REPOSITORY_OWNER=$3

cd ./build/gen/typescript-axios/$API
printf "//npm.pkg.github.com/:_authToken=$GITHUB_TOKEN\n@$REPOSITORY_OWNER:registry=https://npm.pkg.github.com" > ./.npmrc
