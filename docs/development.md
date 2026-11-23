# Development

## Layout

| Path | What |
|---|---|
| `yk-key` | The script: the one file that ships |
| `completions/yk-key.fish` | fish completions |
| `tests/run-tests.sh` | The test entry point (CI runs it) |
| `tests/test-yk-key.sh` | Functional tests |
| `tests/stubs/gpg` | A stand-in for gpg that the tests put first on `PATH` |
| `tests/fixtures/cards.json` | The test database (made-up keys) |

## Tests

```sh
./tests/run-tests.sh
```

It checks syntax (`sh -n`), runs shellcheck in `sh` mode when installed, checks the fish completion when fish is installed,
then runs `tests/test-yk-key.sh` once for each installed shell among `sh`, `dash`, `bash` and `busybox sh` (`YK_SH` picks the
shell that runs yk-key). One shell is enough to pass locally; CI installs dash and busybox so every push is checked under all
of them. To try one shell by hand:

```sh
YK_SH=dash sh tests/test-yk-key.sh
```

The tests never touch your keys or config: `HOME`, `XDG_CONFIG_HOME` and Git's global config point into a temporary directory,
and gpg is the stub. The stub reads the card it should report from `YK_TEST_CARD_FP` and `YK_TEST_CARD_SERIAL`, a
subkey-to-primary mapping from `YK_TEST_PRIMARY` (`SUBKEY=PRIMARY`), and keyring fingerprints for key ID expansion from
`YK_TEST_KEYRING`.

## Portability rules

- POSIX `sh` only: no arrays, `local`, `[[ ]]`, `$'…'`, `<<<`, `${var:off:len}` or `printf %*s`. The one exception is the
  editable prompt in `ask`, which runs only when `$BASH_VERSION` is set.
- `shellcheck -s sh` must pass; disable a check only with a comment saying why.
- Data from the database reaches the shell only through jq's `@sh`, then `eval`, so names and paths are never split or
  expanded.
- No dependency beyond `jq`, `gpg`, `git` and what coreutils and busybox both provide.

## Releasing

1. On a branch, set `YK_KEY_VERSION` in `yk-key` to the new version (semantic versioning: a change to output, options or the
   database format that breaks scripts is a major bump) and merge it through a PR.
2. Tag the merge commit `vX.Y.Z` on `main` and create a Gitea release for it.
3. Repositories that vendor yk-key move to the new tag when they choose (see [install.md](install.md)).
