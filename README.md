# yk-key

Manage YubiKey GPG signing keys and the Git signing key from any POSIX shell.

`yk-key` keeps a small database of OpenPGP smartcards (a name, the signing key's fingerprint, the card's serial number and
optionally the card's SSH key), tells you which one is plugged in, and switches Git's `user.signingkey` between them. It is
one POSIX `sh` script with a single hard dependency, `jq`.

```sh
yk-key                    # list every key
yk-key primary            # look one up by name, fingerprint or serial
yk-key current -k         # the SSH key file of the inserted YubiKey
yk-key git primary --long # sign this repo's commits with "primary"
```

## Install

Copy the script anywhere on your `PATH`:

```sh
install -m 755 yk-key ~/.local/bin/yk-key
```

It needs `jq`; `current` and `add` use `gpg` to read the inserted card, and `git` needs `git`. The database lives at
`${XDG_CONFIG_HOME:-~/.config}/yk-key/cards.json` unless `$YK_KEY_DB` or `--db` says otherwise. See
[docs/install.md](docs/install.md) for shell completions (`yk-key completion bash|zsh|fish`), using an existing database, and pinning a copy inside another
repository.

## Build and test

- Build: none. `yk-key` is the shipped file.
- Test: `./tests/run-tests.sh` (syntax, shellcheck, then the functional tests under every installed shell among `sh`, `dash`,
  `bash` and `busybox sh`). CI runs the same command.

## Documentation

- [docs/usage.md](docs/usage.md): commands, options, matching, the database, JSON output and exit status
- [docs/install.md](docs/install.md): installing, completions, an existing database, vendoring
- [docs/development.md](docs/development.md): tests, portability rules and releases

## Contributing

This project follows the Rootiest project conventions: branch before editing, never push `main`, Conventional Commits, labeled
PRs, docs as the single source of truth. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## License

Released under the AGPL-3.0-or-later license. See [LICENSE](LICENSE).
