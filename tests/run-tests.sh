#!/bin/sh
# Syntax, shellcheck, then the functional tests under every POSIX shell that
# is installed (sh, dash, busybox ash, bash). CI runs the same command.
set -eu
unset CDPATH
cd -- "$(dirname -- "$0")/.." || exit 1

sh -n yk-key
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck -s sh yk-key tests/run-tests.sh tests/test-yk-key.sh tests/stubs/gpg
else
  echo "run-tests: shellcheck not installed; skipped" >&2
fi

ran=0
for shell in sh dash bash 'busybox sh'; do
  command -v "${shell%% *}" >/dev/null 2>&1 || continue
  case $shell in busybox*) busybox sh -c : 2>/dev/null || continue ;; esac
  YK_SH=$shell sh tests/test-yk-key.sh
  ran=$((ran + 1))
done
[ "$ran" -gt 0 ]
echo PASS
