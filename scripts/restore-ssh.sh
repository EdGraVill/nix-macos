#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SRC="./secrets/ssh"
DEST="$HOME/.ssh"

if [ ! -d "$SRC" ]; then
  echo "No SSH backup found at $SRC"
  exit 0
fi

mkdir -p "$DEST"

rsync -a \
  --exclude='permissions.tsv' \
  "$SRC/" "$DEST/"

chmod 700 "$DEST"
find "$DEST" -type d -exec chmod 700 {} \;
find "$DEST" -type f -exec chmod go-rwx {} \;

echo "SSH keys/config restored to $DEST"
