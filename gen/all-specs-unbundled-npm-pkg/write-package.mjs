import fs from "node:fs";
import path from "node:path";
import { argv } from "node:process";

const [_argv0, _scriptname, pkgDirName, version, apiIdsArg] = argv;

const apiIds = apiIdsArg
    .replace(/^[\s,]*/, "")
    .replace(/[\s,]*$/, "")
    .split(",")
    .map((s) => s.trim());

const toCamelCase = (s) =>
    s
        .split(/[^a-zA-Z0-9]/)
        .map((part, index) => (index === 0 ? part[0].toLowerCase() : part[0].toUpperCase()) + part.substring(1).toLowerCase())
        .join("");

const INDENTATION = 2;

const pkgName = `@cubeca/api-specs`;

const pkg = {
    name: pkgName,
    version,
    description: `OpenAPI specifications for The Association for Cube Commons Canada`,
    author: "Cube Commons Contributors",
    repository: {
        type: "git",
        url: "https://github.com/cubeca/api-specs.git",
    },
    keywords: ["cubecommons", "openapi"],
    license: "MIT",
    scripts: {
        build: 'echo "INFO: no build step necessary" && exit 0',
        prepare: "npm run build",
    },
    exports: {
        node: {
            import: "./index.mjs",
            require: "./index.cjs",
        },
        default: "./index.mjs",
    },
    typings: "./index.d.ts",
    registry: "https://registry.npmjs.org",
};

fs.writeFileSync(path.join(pkgDirName, "package.json"), JSON.stringify(pkg, undefined, INDENTATION));
fs.writeFileSync(path.join(pkgDirName, "index.d.ts"), `declare module '${pkgName}';`);

const indexCjsLines = apiIds.map((a) => `  ${toCamelCase(a)}ApiSpecFile: path.join(__dirname, 'specs/${a}.json'),`);
const indexCjs = `const path = require('node:path');

module.exports = {
${indexCjsLines.join("\n")}
}
`;

fs.writeFileSync(path.join(pkgDirName, "index.cjs"), indexCjs);

const indexMjsLines = apiIds.map((a) => `export const ${toCamelCase(a)}ApiSpecFile = path.join(__dirname, 'specs/${a}.json');`);
const indexMjs = `import path from 'node:path';

${indexMjsLines.join("\n")}
`;

fs.writeFileSync(path.join(pkgDirName, "index.mjs"), indexMjs);
