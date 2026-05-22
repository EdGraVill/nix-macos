#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SRC="./secrets/gpg"

if [ ! -d "$SRC" ]; then
  echo "No GPG backup found at $SRC"
  exit 0
fi

if ! command -v gpg >/dev/null 2>&1; then
  echo "gpg command not found. Make sure GPG Suite is installed, then rerun this script."
  exit 1
fi

if [ -f "$SRC/public-keys.asc" ]; then
  gpg --import "$SRC/public-keys.asc" || true
fi

if [ -f "$SRC/private-keys.asc" ]; then
  gpg --import "$SRC/private-keys.asc"
fi

if [ -f "$SRC/ownertrust.txt" ]; then
  gpg --import-ownertrust "$SRC/ownertrust.txt" || true
fi

echo
echo "GPG keys after restore:"
gpg --list-secret-keys --keyid-format=long || true

echo
echo "If signing fails, set user.signingkey in home/git.nix with the restored key id."
