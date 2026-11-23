#!/bin/sh
# Copyright (C) 2026 Rootiest
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Functional tests for yk-key. POSIX sh, no test framework: run it with any
# shell (sh, dash, busybox ash, bash). YK_SH picks the shell that runs
# yk-key itself (default: sh). gpg is replaced by tests/stubs/gpg; git is
# the real one, pointed at a temporary global config.
# shellcheck disable=SC2015 # `test && ok || bad`: ok never fails
set -u
unset CDPATH
cd -- "$(dirname -- "$0")/.." || exit 1
ROOT=$(pwd)
YK_SH=${YK_SH:-sh}

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT INT TERM

export HOME="$WORK/home" XDG_CONFIG_HOME="$WORK/xdg" NO_COLOR=1
export GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1
export PATH="$ROOT/tests/stubs:$PATH"
unset YK_KEY_DB YK_TEST_CARD_FP YK_TEST_CARD_SERIAL YK_TEST_PRIMARY YK_TEST_KEYRING
mkdir -p "$HOME/.ssh" "$WORK/repo"
: >"$GIT_CONFIG_GLOBAL"
git -C "$WORK/repo" init -q

pass=0 fail=0

# reset_db: a fresh copy of the fixture at $DB.
DB="$WORK/cards.json"
# The fixture's SSH key paths sit under /home/test; they are moved under
# $HOME so the ~ shortening can be checked.
sed "s|/home/test|$HOME|g" "$ROOT/tests/fixtures/cards.json" >"$WORK/fixture.json"
reset_db() { cp "$WORK/fixture.json" "$DB"; }

# yk ARGS...: run yk-key against $DB with no stdin; output in $out/$errout,
# status in $st.
yk() {
  out=$(YK_KEY_DB=$DB $YK_SH "$ROOT/yk-key" "$@" 2>"$WORK/stderr" </dev/null)
  st=$?
  errout=$(cat "$WORK/stderr")
}

# yk_in INPUT ARGS...: the same, with INPUT (printf format) on stdin.
yk_in() {
  _in=$1
  shift
  # shellcheck disable=SC2059 # INPUT is a printf format on purpose
  out=$(printf "$_in" | YK_KEY_DB=$DB $YK_SH "$ROOT/yk-key" "$@" 2>"$WORK/stderr")
  st=$?
  errout=$(cat "$WORK/stderr")
}

ok() {
  pass=$((pass + 1))
}
bad() {
  fail=$((fail + 1))
  printf 'FAIL: %s\n' "$1" >&2
  printf '  status: %s\n  stdout: %s\n  stderr: %s\n' "$st" "$out" "$errout" >&2
}

# expect NAME STATUS [STDOUT]: check the last run.
expect() {
  if [ "$st" -ne "$2" ]; then
    bad "$1 (wanted status $2)"
  elif [ $# -ge 3 ] && [ "$out" != "$3" ]; then
    bad "$1 (wanted stdout: $3)"
  else
    ok
  fi
}

# expect_err NAME TEXT: the last run's stderr contains TEXT.
expect_err() {
  case $errout in
    *"$2"*) ok ;;
    *) bad "$1 (wanted stderr containing: $2)" ;;
  esac
}

# expect_db NAME JQ_EXPR: the expression is true for the database.
expect_db() {
  if jq -e "$2" "$DB" >/dev/null 2>&1; then ok; else bad "$1 (database: $2)"; fi
}

FP_PRIMARY=AAAA1111BBBB2222CCCC3333DDDD4444EEEE5555
FP_SAT=0123456789ABCDEF0123456789ABCDEF01234567
FP_TRAVEL=FEDCBA9876543210FEDCBA9876543210FEDCBA98
FP_NEW=ABCDABCDABCDABCDABCDABCDABCDABCDABCDABCD

# ---- list ------------------------------------------------------------------
reset_db
yk
expect "list: header and rows" 0
case $out in
  "NAME           FINGERPRINT                                SERIAL     SSH KEY"*) ok ;;
  *) bad "list: header" ;;
esac
yk list -q
expect "list -q: first row" 0
[ "$(printf '%s\n' "$out" | sed -n 1p)" = "primary        $FP_PRIMARY   11111111   $HOME/.ssh/id_ed25519_sk_primary" ] && ok || bad "list -q row"
yk ls -n
expect "ls -n" 0 "primary
secondary
travel
primary-backup"
yk -f --short
expect "list -f --short" 0 "EEEE5555
01234567
FEDCBA98
11110000"
yk list -k
expect "list -k" 0 "$HOME/.ssh/id_ed25519_sk_primary
$HOME/.ssh/id_ed25519_sk_secondary"
[ "$(YK_KEY_DB=$DB $YK_SH "$ROOT/yk-key" list -k | wc -l | tr -d ' ')" = 4 ] && ok || bad "list -k: one line per key"
yk list -j --long
expect "list -j --long" 0
[ "$(printf '%s' "$out" | jq -r '.[2] | "\(.fingerprint) \(."ssh-key")"')" = "76543210FEDCBA98 null" ] && ok || bad "list -j values"
yk list -j -s
[ "$(printf '%s' "$out" | jq -c '.[0]')" = '{"serial":"11111111"}' ] && ok || bad "list -j -s"

# ---- info and matching ---------------------------------------------------
yk primary -q
expect "bare query is info" 0 "primary	$FP_PRIMARY	11111111	$HOME/.ssh/id_ed25519_sk_primary"
yk info primary
expect "info primary" 0 "primary  fingerprint=$FP_PRIMARY  serial=11111111  ssh-key=~/.ssh/id_ed25519_sk_primary"
yk show primary --short
expect "--short implies -f" 0 "EEEE5555"
yk primary -l long -n
expect "-n beats the -f a length implies" 0 "primary"
yk sec
expect "substring match" 0
yk ry
expect "ambiguous match" 1
expect_err "ambiguous lists the matches" "matches 3 keys"
yk ry -q
expect "ambiguous -q is silent" 1 ""
[ -z "$errout" ] && ok || bad "ambiguous -q stderr"
yk nomatch
expect "no match" 1
expect_err "no match message" "no key matches 'nomatch'"
yk 0123456789ABCDEF -n
expect "long key ID" 0 "secondary"
yk 'eeee 5555' -n
expect "spaces in a query are ignored" 0 "primary"
yk 22222222 -n
expect "serial match" 0 "secondary"
yk 1111 -n
expect "substring hits name/fp/serial" 1
yk 1111 -S -n
expect "-S restricts to serials" 0 "primary"
yk primary -N -n
expect "-N exact name beats substring" 0 "primary"
yk travel -k
expect "-k with no SSH key" 1
yk travel -k -j
expect "-k -j with no SSH key is null" 0 '{
  "ssh-key": null
}'
yk primary -j
[ "$(printf '%s' "$out" | jq -c .)" = "{\"name\":\"primary\",\"fingerprint\":\"$FP_PRIMARY\",\"serial\":\"11111111\",\"ssh-key\":\"$HOME/.ssh/id_ed25519_sk_primary\"}" ] && ok || bad "info -j"

# ---- options -------------------------------------------------------------
yk primary -qn
expect "bundled short flags" 0 "primary"
yk primary -lshort
expect "attached short value" 0 "EEEE5555"
yk primary --length=8
expect "--opt=value" 0 "EEEE5555"
yk primary -l bogus
expect "invalid length" 2
yk -x
expect "unknown short option" 2
yk --bogus
expect "unknown long option" 2
yk --json=1
expect "flag given a value" 2
yk -l
expect "missing option value" 2
yk info
expect "missing QUERY" 2
yk rm
expect "rm without QUERY" 2
yk -n -- primary
expect "-- ends options" 0 "primary"
yk --version
case $out in "yk-key "[0-9]*) ok ;; *) bad "--version" ;; esac
yk --help
expect "--help" 0
case $out in "Usage: yk-key"*) ok ;; *) bad "--help text" ;; esac
yk -qh
expect "bundled -h" 0
yk help -j
printf '%s' "$out" | jq -e '.commands | length > 0' >/dev/null && ok || bad "help -j is JSON"

# ---- database location ---------------------------------------------------
YK_KEY_DB='' $YK_SH "$ROOT/yk-key" >/dev/null 2>"$WORK/stderr"
st=$? out='' errout=$(cat "$WORK/stderr")
expect "no database" 1
expect_err "no database names the XDG path" "$XDG_CONFIG_HOME/yk-key/cards.json"
mkdir -p "$XDG_CONFIG_HOME/yk-key" && cp "$DB" "$XDG_CONFIG_HOME/yk-key/cards.json"
out=$($YK_SH "$ROOT/yk-key" -n 2>/dev/null | sed -n 1p) st=0
expect "XDG database is found" 0 "primary"
out=$(YK_KEY_DB="$WORK/missing.json" $YK_SH "$ROOT/yk-key" -n 2>/dev/null | sed -n 1p)
expect "missing \$YK_KEY_DB falls back to an existing XDG file" 0 "primary"
out=$(XDG_CONFIG_HOME='' $YK_SH "$ROOT/yk-key" --db "$DB" -n 2>/dev/null | sed -n 1p)
expect "--db wins" 0 "primary"
rm -rf "$XDG_CONFIG_HOME/yk-key"
printf 'nova\n%s\n55555555\n\n' "$FP_NEW" | $YK_SH "$ROOT/yk-key" add -q >/dev/null 2>&1
st=$?
expect "add creates the XDG database" 0
jq -e 'length == 1 and .[0].name == "nova"' "$XDG_CONFIG_HOME/yk-key/cards.json" >/dev/null 2>&1 && ok || bad "XDG database contents"
rm -rf "$XDG_CONFIG_HOME/yk-key"

# ---- current -------------------------------------------------------------
yk current
expect "no card" 1
expect_err "no card message" "no YubiKey"
export YK_TEST_CARD_FP=$FP_PRIMARY YK_TEST_CARD_SERIAL=11111111
yk current
expect "current by fingerprint" 0 "primary  fingerprint=$FP_PRIMARY  serial=11111111  ssh-key=~/.ssh/id_ed25519_sk_primary"
yk inserted -k
expect "current -k" 0 "$HOME/.ssh/id_ed25519_sk_primary"
yk current --short
expect "current --short" 0 "EEEE5555"
export YK_TEST_CARD_FP=1234123412341234123412341234123412341234 YK_TEST_CARD_SERIAL=33333333
export YK_TEST_PRIMARY="$YK_TEST_CARD_FP=$FP_TRAVEL"
yk current -n
expect "card subkey resolved to the primary key" 0 "travel"
unset YK_TEST_PRIMARY
yk current -n
expect "current falls back to the serial" 0 "travel"
export YK_TEST_CARD_SERIAL=99999999
yk current -q
expect "unlisted card" 0 "unlisted	$YK_TEST_CARD_FP	99999999	"
yk current -n
expect "unlisted card with -n" 1
yk current -j
[ "$(printf '%s' "$out" | jq -c '[.name, .serial]')" = '[null,"99999999"]' ] && ok || bad "unlisted -j"
unset YK_TEST_CARD_FP YK_TEST_CARD_SERIAL

# ---- add -----------------------------------------------------------------
reset_db
yk_in "nova\n$FP_NEW\n55555555\n$HOME/.ssh/nova\n" add
expect "add" 0 "Added nova ($FP_NEW | 55555555)"
expect_err "add warns about a missing key file" "no file at $HOME/.ssh/nova"
expect_db "add wrote the entry" ".[4] == {name: \"nova\", fingerprint: \"$FP_NEW\", serial: \"55555555\", \"ssh-key\": \"$HOME/.ssh/nova\"}"
reset_db
yk_in "nova\nabcd abcd abcdabcdabcdabcdabcdabcdabcdabcd\n 5555 5555 \n\n" add -j
expect "add -j normalises ids" 0
[ "$(printf '%s' "$out" | jq -c '[.action, .fingerprint, .serial, ."ssh-key"]')" = "[\"added\",\"$FP_NEW\",\"55555555\",null]" ] && ok || bad "add -j output"
expect_db "add without SSH key omits it" '.[4] | has("ssh-key") | not'
reset_db
export YK_TEST_CARD_FP=$FP_NEW YK_TEST_CARD_SERIAL=55555555
: >"$HOME/.ssh/id_ed25519_sk_nova"
yk_in "nova\n\n\n\n" add -q
expect "add takes the card and key file defaults" 0 ""
expect_db "defaults were saved" ".[4] == {name: \"nova\", fingerprint: \"$FP_NEW\", serial: \"55555555\", \"ssh-key\": \"$HOME/.ssh/id_ed25519_sk_nova\"}"
unset YK_TEST_CARD_FP YK_TEST_CARD_SERIAL
reset_db
export YK_TEST_KEYRING=$FP_NEW
yk_in "nova\nABCDABCD\n55555555\n\n" add
expect "add expands a key ID" 0
expect_err "add says it resolved the key ID" "Resolved the full fingerprint"
expect_db "expanded fingerprint saved" ".[4].fingerprint == \"$FP_NEW\""
unset YK_TEST_KEYRING
reset_db
yk_in "nova\n~/.ssh/k\n" add
expect "add stops at end of input" 1
yk_in "nova\n$FP_NEW\n11111111\n\n" add
expect "add rejects a duplicate serial" 1
expect_err "collision message" "collide with the existing key 'primary'"
yk_in "PRIMARY\n$FP_NEW\n55555555\n\n" add
expect "add rejects a duplicate name (any case)" 1
yk_in "list\n$FP_NEW\n55555555\n\n" add
expect "add rejects a subcommand name" 1
yk_in "deadbeef\n$FP_NEW\n55555555\n\n" add
expect "add rejects a hex name" 1
yk_in "nova\nABCD\n55555555\n\n" add
expect "add rejects a short fingerprint" 1
yk_in "nova\n$FP_NEW\n\n\n" add
expect "add requires a serial" 1
yk_in "nova\n${FP_PRIMARY%5555}0000\n55555555\n\n" add
expect "add allows a fingerprint differing in the last 16" 0
reset_db
yk_in "nova\nAAAAAAAAAAAAAAAAAAAAAAAA${FP_PRIMARY#AAAA1111BBBB2222CCCC3333}\n55555555\n\n" add
expect "add rejects a long key ID collision" 1
cmp -s "$DB" "$WORK/fixture.json" && ok || bad "rejected adds left the database alone"

# ---- edit ----------------------------------------------------------------
reset_db
yk_in "travel2\n\n\n$HOME/.ssh/c\n" edit travel
expect "edit keeps defaults on empty input" 0 "Updated travel2 ($FP_TRAVEL | 33333333)"
expect_db "edit wrote the entry" ".[2] == {name: \"travel2\", fingerprint: \"$FP_TRAVEL\", serial: \"33333333\", \"ssh-key\": \"$HOME/.ssh/c\"}"
yk_in "\n\n\n-\n" edit travel2 -j
expect "edit - clears the SSH key" 0
expect_db "SSH key removed" '.[2] | has("ssh-key") | not'
yk_in "travel2\n\n11111111\n\n" edit travel2
expect "edit rejects a collision" 1
yk_in "primary\n\n\n\n" edit primary
expect "edit may keep its own values" 0
yk_in "" edit co
expect "edit needs exactly one match" 1

# ---- rm ------------------------------------------------------------------
reset_db
yk_in "n\n" rm travel
expect "rm aborted" 1
expect_err "rm abort message" "Aborted."
yk_in "y\n" rm travel
expect "rm confirmed" 0 "Removed travel"
expect_db "rm removed it" 'map(.name) == ["primary", "secondary", "primary-backup"]'
yk rm secondary -y -j
[ "$(printf '%s' "$out" | jq -r .action)" = removed ] && ok || bad "rm -y -j"
yk rm primary -q
expect "rm -q does not ask" 0 ""
expect_db "rm -q removed it" 'map(.name) == ["primary-backup"]'

# ---- git -----------------------------------------------------------------
reset_db
cd "$WORK/repo" || exit 1
yk git
expect "git: nothing configured" 1
yk git primary --long
expect "git sets the local key" 0 "Set local git user.signingkey -> primary (DDDD4444EEEE5555 | 11111111)"
[ "$(git config --local user.signingkey)" = DDDD4444EEEE5555 ] && ok || bad "local signingkey written"
yk git
expect "git shows the local key" 0 "Active (local): primary  signingkey=DDDD4444EEEE5555  full=$FP_PRIMARY  serial=11111111  ssh-key=~/.ssh/id_ed25519_sk_primary"
yk git -q -s
expect "git -q -s" 0 "11111111"
yk git -j
[ "$(printf '%s' "$out" | jq -c '[.scope, .signingkey, .name]')" = '["local","DDDD4444EEEE5555","primary"]' ] && ok || bad "git -j"
git config --local user.signingkey "$FP_SAT!"
yk git -n -q
expect "git ignores a trailing !" 0 "secondary"
git config --local user.signingkey 0000000000000000
yk git
expect "git: key not in the database" 0 "Active (local): 0000000000000000 (not in the database)"
yk git travel -g -j
[ "$(printf '%s' "$out" | jq -c '[.action, .scope, .signingkey]')" = "[\"set\",\"global\",\"$FP_TRAVEL\"]" ] && ok || bad "git -g set"
[ "$(git config --global user.signingkey)" = "$FP_TRAVEL" ] && ok || bad "global signingkey written"
yk git -g -n -q
expect "git -g shows the global key" 0 "travel"
cd "$ROOT" || exit 1

# ---- missing jq ----------------------------------------------------------
mkdir -p "$WORK/nojq"
for t in sed tr grep cat mkdir dirname mktemp mv rm sh; do
  p=$(command -v "$t") && ln -s "$p" "$WORK/nojq/$t"
done
out=$(PATH="$WORK/nojq" YK_KEY_DB=$DB "$WORK/nojq/sh" "$ROOT/yk-key" 2>"$WORK/stderr")
st=$? errout=$(cat "$WORK/stderr")
expect "missing jq" 1
expect_err "missing jq message" "jq is required"

printf '%s passed, %s failed (yk-key run by %s)\n' "$pass" "$fail" "$YK_SH"
[ "$fail" -eq 0 ]
