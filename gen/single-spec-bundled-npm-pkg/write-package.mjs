import fs from 'node:fs';
import path from 'node:path';
import { argv } from 'node:process';

const [_argv0, _scriptname, pkgDirName, specFile] = argv;

const INDENTATION = 2;

const apiId = path.basename(pkgDirName);

const apiSpec = JSON.parse(fs.readFileSync(specFile, 'utf8'));

const version = apiSpec.info.version;
const title = apiSpec.info.title;

const pkgName = `@cubeca/${apiId}-api-spec`;

const pkg = {
  "name": pkgName,
  version,
  "description": `OpenAPI specification for ${title}`,
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
fs.writeFileSync(path.join(pkgDirName, 'index.cjs'), `module.exports = { spec: ${JSON.stringify(apiSpec, undefined, INDENTATION)} }`);
fs.writeFileSync(path.join(pkgDirName, 'index.mjs'), `export const spec = ${JSON.stringify(apiSpec, undefined, INDENTATION) }`);
