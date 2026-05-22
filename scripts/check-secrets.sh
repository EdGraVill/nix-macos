#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -d "./secrets" ]; then
  echo "Missing ./secrets folder."
  exit 1
fi

echo "Checking secrets structure..."

[ -d "./secrets/ssh" ] && echo "OK: secrets/ssh" || echo "WARN: missing secrets/ssh"
[ -d "./secrets/gpg" ] && echo "OK: secrets/gpg" || echo "WARN: missing secrets/gpg"
[ -d "./secrets/home-files" ] && echo "OK: secrets/home-files" || echo "WARN: missing secrets/home-files"
[ -f "./secrets/repos/restore-plan.tsv" ] && echo "OK: secrets/repos/restore-plan.tsv" || echo "WARN: missing repo restore plan"
[ -f "./secrets/keyvalue.txt" ] && echo "OK: secrets/keyvalue.txt" || echo "WARN: missing secrets/keyvalue.txt"

echo "Done."
