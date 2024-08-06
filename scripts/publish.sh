#!/usr/bin/env bash

# Make Bash's error handling strict(er).
set -o nounset -o pipefail -o errexit

export PACKAGE_DIR=$1
export NEW_VERSION=$2

cd $PACKAGE_DIR

LATEST_PUBLISHED_VERSION=`npm view . version 2>/dev/null || echo "0"`
echo "LATEST_PUBLISHED_VERSION($PACKAGE_DIR)==$LATEST_PUBLISHED_VERSION"
echo "NEW_VERSION($PACKAGE_DIR)==$NEW_VERSION"

if [ -n "$NEW_VERSION" ] && [ "$LATEST_PUBLISHED_VERSION" != "$NEW_VERSION" ]; then
  cat ./package.json | jq '.version = $ENV.NEW_VERSION' > ./package-edited.json
  mv ./package-edited.json ./package.json

  cat ./package.json | jq '.license.name = MIT' > ./package-edited.json
  mv ./package-edited.json ./package.json

  npm install
  npm run build
  npm publish --access public
fi
