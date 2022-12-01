#!/usr/bin/env bash

# Make Bash's error handling strict(er).
set -o nounset -o pipefail -o errexit

API=$1

cd ./build/gen/typescript-axios/$API
LATEST=`npm view . version 2>/dev/null || echo "0"`
echo "LATEST==$LATEST"
CURRENT=`cat package.json | jq -r .version`
echo "CURRENT==$CURRENT"
if [ "$LATEST" != "$CURRENT" ]
then
    npm install
    npm run build
    npm publish
fi
