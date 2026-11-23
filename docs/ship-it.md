# Shipping this project

Instructions for `/ship-it` and its steps. Each `##` section is read by the step of the same
name; anything left out uses that step's defaults.

## ship-it
- Hosting is Gitea (`git.rootiest.dev`, `rootiest/yk-key`). Use the Gitea tools, not `gh`.
- `main` takes changes through PRs: branch first, then open a PR against `main`.

## doc-it
- Keep `docs/usage.md`, the `--help` text, `help --json` and `completions/yk-key.fish` in step
  with every change to commands or options.
- Breaking issues beyond syntax errors: `shellcheck -s sh yk-key` failing, or anything that
  works only under bash outside the `ask` prompt.

## push-it
- Branch naming: `<type>/<topic>`, e.g. `feat/bash-completions`, `fix/serial-parse`.
- Commit scopes in use: `cli`, `db`, `card`, `git`, `completions`, `tests`, `docs`, `ci`, or
  none for repo-wide changes.
- Checks before pushing: `./tests/run-tests.sh` (it must print `PASS`).

## verify-it
- CI runs `./tests/run-tests.sh` on the Gitea `ubuntu-latest` runner; it takes about a minute,
  most of it installing packages.

## merge-it
- Merge method: merge commit, deleting the head branch.
- Always ask before merging.

## sync-it
- No automated commits follow a merge.

## deploy-it
- Nothing deploys on merge. A release is a `vX.Y.Z` tag on `main` after `YK_KEY_VERSION` is
  bumped (docs/development.md); ask before tagging. Consumers pull a tag themselves.
