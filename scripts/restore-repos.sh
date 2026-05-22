#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PLAN="./secrets/repos/restore-plan.tsv"
CODE_DIR="${CODE_DIR:-$HOME/code}"

if [ ! -f "$PLAN" ]; then
  echo "No repo restore plan found at $PLAN"
  exit 0
fi

mkdir -p "$CODE_DIR"

tail -n +2 "$PLAN" | while IFS=$'\t' read -r rel remote; do
  [ -z "${rel:-}" ] && continue
  [ -z "${remote:-}" ] && continue

  target="$CODE_DIR/$rel"

  if [ -d "$target/.git" ]; then
    echo "Repo already exists, skipping: $rel"
    continue
  fi

  mkdir -p "$(dirname "$target")"

  echo "Cloning $remote -> $target"
  git clone "$remote" "$target" || {
    echo "WARNING: Failed to clone $remote into $target"
    continue
  }
done

echo "Repository restore completed."
