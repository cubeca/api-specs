# Internal API specifications

API specifications for all internal APIs.

## Versioning

To trigger correct version bumps, please start your commit messages with one of these:

To bump the patch version:

- `patch(XYZ_SCOPE): <your short description>`
- `fix(XYZ_SCOPE): <your short description>`
- `bug(XYZ_SCOPE): <your short description>`
- `chore(XYZ_SCOPE): <your short description>`

To bump the minor version:

- `minor(XYZ_SCOPE): <your short description>`
- `feat(XYZ_SCOPE): <your short description>`
- `feature(XYZ_SCOPE): <your short description>`

To bump the major version:

- `major(XYZ_SCOPE): <your short description>`
- `breaking(XYZ_SCOPE): <your short description>`

See also:

- https://github.com/mathieudutour/github-tag-action/blob/master/package.json#L27-L29
- https://www.npmjs.com/package/@semantic-release/commit-analyzer
- https://github.com/semantic-release/semantic-release/blob/master/docs/usage/configuration.md#configuration

## Notes  

You can add a `FORCE=True` prefix to the `make` invocations. Currently it allows the code generator for the API client NPM package to ignore validation errors.
