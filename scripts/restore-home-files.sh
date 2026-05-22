#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SRC="./secrets/home-files"

if [ ! -d "$SRC" ]; then
  echo "No personal home files backup found at $SRC"
  exit 0
fi

rsync -a "$SRC/" "$HOME/"

# Best-effort permission restore from manifest.
if [ -f "$SRC/manifest.tsv" ]; then
  while IFS=$'\t' read -r rel mode; do
    [ -z "${rel:-}" ] && continue
    [ "$rel" = "manifest.tsv" ] && continue
    [ "$mode" = "missing" ] && continue
    target="$HOME/$rel"
    if [ -e "$target" ] && [ -n "${mode:-}" ]; then
      chmod "$mode" "$target" 2>/dev/null || true
    fi
  done < "$SRC/manifest.tsv"
fi

echo "Personal sourced home files restored."
