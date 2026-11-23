#!/usr/bin/env bash
# Minimal test runner. Extend this with the project's real tests; CI runs it.
set -eu
cd "$(dirname "$0")/.."
echo PASS
