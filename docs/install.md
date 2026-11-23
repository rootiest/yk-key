# Installing

`yk-key` is one file. Put it anywhere on your `PATH` and make it executable:

```sh
install -m 755 yk-key ~/.local/bin/yk-key
```

Or take a released version straight from Gitea (replace the tag):

```sh
curl -fsSLo ~/.local/bin/yk-key https://git.rootiest.dev/rootiest/yk-key/raw/tag/v1.0.0/yk-key && chmod 755 ~/.local/bin/yk-key
```

## Dependencies

| Tool | Needed for |
|---|---|
| a POSIX `sh` | everything (tested with bash, dash and busybox ash) |
| `jq` | everything; yk-key exits 1 with a message when it is missing |
| `gpg` (GnuPG 2) | `current`, and the card defaults and key ID expansion in `add` |
| `git` 2.26 or newer | `git` (it uses `git config --show-scope`) |
| `sed`, `grep`, `tr`, `mktemp`, `mv` | everywhere these exist already (coreutils, busybox) |

## Completions

fish: copy `completions/yk-key.fish` to `~/.config/fish/completions/`. It completes key names from the database, honouring a
`--db` already typed.

## Using an existing database

To keep a `cards.json` somewhere else, point `$YK_KEY_DB` at it (`export YK_KEY_DB=/path/to/cards.json`, or
`set -Ux YK_KEY_DB /path/to/cards.json` in fish), or symlink it to `~/.config/yk-key/cards.json`.

If a shell function named `yk-key` is defined (an older fish version, say), it runs instead of this script; remove it.

## Vendoring a pinned copy

Another repository that runs yk-key (a deploy script, say) should carry its own copy, pinned to a release, rather than depend on
what is installed. Fetch the file from a tag and record the version and checksum beside it:

```sh
tag=v1.0.0
curl -fsSL "https://git.rootiest.dev/rootiest/yk-key/raw/tag/$tag/yk-key" -o vendor/yk-key
sha256sum vendor/yk-key
```

The consuming repository decides when to move to a newer tag, and each bump is an ordinary reviewed change there. yk-key never
pushes into other repositories.
