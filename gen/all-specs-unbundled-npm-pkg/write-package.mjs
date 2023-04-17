import fs from 'node:fs';
import path from 'node:path';
import { argv } from 'node:process';

const [_argv0, _scriptname, pkgDirName, version] = argv;

const INDENTATION = 2;

const bffApiSpec = JSON.parse(fs.readFileSync(path.join(pkgDirName, 'specs/bff.json'), 'utf8'));


const pkgName = `@cubeca/api-specs`;

const pkg = {
  "name": pkgName,
  version,
  "description": `OpenAPI specifications for The Association for Cube Commons Canada`,
  "author": "Cube Commons Contributors",
  "repository": {
    "type": "git",
    "url": "https://github.com/cubeca/api-specs.git"
  },
  "keywords": [
    "cubecommons",
    "openapi"
  ],
  "license": "UNLICENSED",
  "scripts": {
    "build": "echo \"INFO: no build step necessary\" && exit 0",
    "prepare": "npm run build"
  },
  "exports": {
    "node": {
      "import": "./index.mjs",
      "require": "./index.cjs",
    },
    "default": "./index.mjs"
  },
  "typings": "./index.d.ts",
  "registry": "https://registry.npmjs.org"
}

fs.writeFileSync(path.join(pkgDirName, 'package.json'), JSON.stringify(pkg, undefined, INDENTATION));
fs.writeFileSync(path.join(pkgDirName, 'index.d.ts'), `declare module '${pkgName}';`);
