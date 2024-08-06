#!/bin/bash

# Assign arguments to variables
pkgDirName=$1
specFile=$2

# Extract data from the JSON spec file
apiId=$(basename "$pkgDirName")
pkgName="@cubeca/${apiId}-api-spec"

# Create package.json content
pkg=$(cat <<EOF
{
  "name": "$pkgName",
  "version": "0.0.1",
  "description": "Cube Commons API Client",
  "author": "Cube Commons Contributors",
  "repository": {
    "type": "git",
    "url": "https://github.com/cubeca/api-specs.git"
  },
  "keywords": [
    "cubecommons",
    "openapi"
  ],
  "license": "MIT",
  "scripts": {
    "build": "echo \\"INFO: no build step necessary\\" && exit 0",
    "prepare": "npm run build"
  },
  "exports": {
    "node": {
      "import": "./index.mjs",
      "require": "./index.cjs"
    },
    "default": "./index.mjs"
  },
  "typings": "./index.d.ts",
  "registry": "https://registry.npmjs.org"
}
EOF
)

# Write to package.json
echo "$pkg" > "$pkgDirName/package.json"

# Create index.d.ts, index.cjs, index.mjs
echo "declare module '$pkgName';" > "$pkgDirName/index.d.ts"

# Get the spec content using Node.js command
specContent=$(node -e "console.log(JSON.stringify(require('$specFile')));")

# Write to index.cjs
echo "module.exports = { spec: $specContent }" > "$pkgDirName/index.cjs"

# Write to index.mjs
echo "export const spec = $specContent" > "$pkgDirName/index.mjs"
