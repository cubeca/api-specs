#!/usr/bin/env bash

# Make Bash's error handling strict(er).
set -o nounset -o pipefail -o errexit

NPMRC_FILEPATH=$1
NPMJS_ACCESS_TOKEN=$2

printf "//registry.npmjs.org/:_authToken=$NPMJS_ACCESS_TOKEN" > $NPMRC_FILEPATH
