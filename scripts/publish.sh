#!/usr/bin/env bash

# Make Bash's error handling strict(er).
set -o nounset -o pipefail -o errexit

export API=$1
export NEW_VERSION=$2

cd ./build/gen/typescript-axios/$API

LATEST_PUBLISHED_VERSION=`npm view . version 2>/dev/null || echo "0"`
echo "LATEST_PUBLISHED_VERSION($API)==$LATEST_PUBLISHED_VERSION"
echo "NEW_VERSION($API)==$NEW_VERSION"

if [ -n "$NEW_VERSION" ] && [ "$LATEST_PUBLISHED_VERSION" != "$NEW_VERSION" ]; then
  cat ./package.json | jq '.version = $ENV.NEW_VERSION' > ./package-edited.json
  mv ./package-edited.json ./package.json

  npm install
  npm run build
  npm publish
fi
