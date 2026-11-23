# Usage

```text
yk-key [list] [-n|-f|-s|-k] [-l LEN] [-j]
yk-key [info|show] QUERY [-N|-F|-S] [-n|-f|-s|-k] [-l LEN] [-j]
yk-key current [-n|-f|-s|-k] [-l LEN] [-j]
yk-key add [-j]
yk-key edit QUERY [-N|-F|-S] [-j]
yk-key rm QUERY [-N|-F|-S] [-y] [-j]
yk-key git [QUERY] [-g] [-n|-f|-s|-k] [-l LEN] [-j]
yk-key completion [bash|zsh|fish]
```

## Commands

| Command | Does |
|---|---|
| `list`, `ls` | List every key (the default) |
| `info`, `show` QUERY | Look up one key. A bare QUERY with no command is an `info`: `yk-key primary` is `yk-key info primary` |
| `current`, `inserted` | Show the inserted YubiKey |
| `add` | Add a key, asking for each field |
| `edit` QUERY | Edit a key, asking for each field |
| `rm`, `delete`, `remove` QUERY | Remove a key (asks first unless `-y` or `-q`) |
| `git` [QUERY] | Show or set Git's `user.signingkey` |
| `completion`, `completions` [SHELL] | Print the completion script for `bash`, `zsh` or `fish` (default: the shell named in `$SHELL`) |
| `help` | Show the help (`-h`, `--help` too) |

## Options

Options may come before or after the command and its QUERY. Short options bundle (`-qj`) and take a value attached or as the
next word (`-lshort`, `-l short`); long ones take `--db=PATH` or `--db PATH`. `--` ends the options.

| Option | Meaning |
|---|---|
| `-n`, `--name` | Print only the key name |
| `-f`, `--fingerprint` | Print only the fingerprint |
| `-s`, `--serial` | Print only the serial number |
| `-k`, `--ssh-key` | Print only the SSH key path |
| `-l`, `--length` LEN | Fingerprint length: `short` (8), `long` (16) or `full` (40); `s`, `l`, `f`, `8`, `16`, `40` work too |
| `--short`, `--long`, `--full` | Shorthand for `-l`. On `info` and `current` with no other field flag they also imply `-f` |
| `-N`, `--by-name` | Match QUERY against names only |
| `-F`, `--by-fingerprint` | Match QUERY against fingerprints only |
| `-S`, `--by-serial` | Match QUERY against serials only |
| `-g`, `--global` | `git`: use the global Git config |
| `-d`, `--db` PATH | Use PATH as the database |
| `-y`, `--yes` | `rm`: do not ask |
| `-j`, `--json` | Print JSON (see below) |
| `-q`, `--silent`, `--quiet` | Print only the data: no headings, colour, confirmations or error messages |
| `-C`, `--no-color` | No colour |
| `-V`, `--version` | Print the version |
| `-h`, `--help` | Show the help |

When several are given, `--length` wins over the shorthands (then `--short`, `--long`, `--full`); for fields, `-n` wins, then
`-f`, `-s`, `-k`; for matching, `-N`, then `-F`, `-S`.

## The database

A JSON array, one object per key:

```json
[
  {"name": "primary", "fingerprint": "AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555", "serial": "11111111", "ssh-key": "/home/me/.ssh/id_ed25519_sk_primary"}
]
```

`ssh-key` is optional. The file used is the first that applies of:

1. `--db PATH` (when not empty)
2. `$YK_KEY_DB`, when that file exists
3. `${XDG_CONFIG_HOME:-~/.config}/yk-key/cards.json`, when that file exists (a relative `XDG_CONFIG_HOME` is ignored, as the
   XDG spec says)
4. otherwise `$YK_KEY_DB` if set, else the XDG path. Only `add` goes on from here: it creates the file (and its directory).

Every write goes through a temporary file beside the database, renamed into place, so an interrupted write never leaves a
half-written file. The new file is created mode 0600. When the database is a symlink, the file it points to is written and the
link stays.

## Matching a QUERY

A QUERY matches a name, a fingerprint (its full 40, last 16 or last 8 characters) or a serial, ignoring case and spaces. Exact
matches win; when there are none, a substring match is tried. `-N`, `-F` and `-S` restrict both steps to one field. `info` with
several matches lists them on stderr and exits 1; `edit`, `rm` and `git QUERY` need exactly one.

## current

Reads the inserted card with `gpg --card-status --with-colons`. The card reports its signature subkey; when that key is in the
local keyring, the primary key's fingerprint is used instead, since that is what the database stores. The card is looked up by
fingerprint, then by serial. A card that is not in the database prints as `unlisted` (with `--json`, a null `name`); asking it
for `-n` or `-k` exits 1.

## add and edit

`add` asks for the name, fingerprint, serial and SSH key path. It offers the inserted card's fingerprint and serial as defaults,
and `~/.ssh/id_ed25519_sk_NAME` as the SSH key when that file exists. A short or long key ID typed for the fingerprint is
expanded from the local keyring. `edit` offers the entry's current values.

Under bash on a terminal (Arch, Fedora and macOS ship bash as `sh`), the default is pre-filled and can be edited. Under other
shells it is shown in brackets and an empty answer keeps it. For the SSH key, `-` means none. Prompts go to stderr, so
`--json` output stays clean; answers can also be piped in, one per line.

An entry is refused when a field is missing, the fingerprint is not 40 hex characters, the name is a command name (including `completion`) or looks
like a hex ID (8 or more hex characters), the name or SSH key path holds control characters, two fields are equal, or any
field collides with another entry's name, fingerprint (full or last 16) or serial. A missing SSH key file only warns.

## git

With no QUERY, shows the `user.signingkey` Git uses here, which config it comes from (`local`, `global`, `system`, ...), and the
entry it belongs to; `-g` looks at the global config only. A trailing `!` (a pinned subkey) is ignored for the lookup. With a
QUERY, sets `user.signingkey` to that entry's fingerprint in this repository's config, or with `-g` the global one; `-l`
controls the length written.

## completion

Prints a completion script on stdout, for the shell to load. It needs neither jq nor a database. The scripts complete commands,
options, `--length` values and shell names, and key names (with their long key ID and serial in zsh and fish), asking `yk-key`
itself for them and honouring a `--db` already typed. Loading them is described in [install.md](install.md#completions).

## Output

`list`, `info` and `current` print one line per key: the name, fingerprint, serial and SSH key path (tab-separated under `-q`
for `info` and `current`, padded columns for `list`), or the one field chosen with `-n`, `-f`, `-s` or `-k`.

Colour is off when stdout is not a terminal, with `-C` or `--json`, or when `NO_COLOR` is set to anything non-empty.

### JSON

With `--json`, stdout carries only JSON: `list` prints an array, every other command one object with the keys `name`,
`fingerprint`, `serial` and `ssh-key` (null when unknown). A field flag cuts each object down to that key. `git` adds `scope`
and `signingkey`; `add`, `edit`, `rm` and `git QUERY` add `action` (`added`, `updated`, `removed`, `set`). `help --json`
describes the commands and options. Errors still go to stderr, and `add` and `edit` still ask.

```sh
yk-key list --json | jq -r '.[] | select(.name == "primary") | ."ssh-key"'
```

## Exit status

| Status | Meaning |
|---|---|
| 0 | Success, or the help or version was shown |
| 1 | No match, an ambiguous match, no database, no card, no SSH key set (with `-k`, without `--json`), a missing dependency, a rejected entry, an aborted removal, or a failed write |
| 2 | Unknown option, a missing option value, an invalid `--length`, or a missing QUERY |

## Environment

| Variable | Use |
|---|---|
| `YK_KEY_DB` | Database path (see above) |
| `XDG_CONFIG_HOME` | Base of the default database path |
| `NO_COLOR` | Non-empty turns colour off |
| `GNUPGHOME` | Read by gpg as usual |
