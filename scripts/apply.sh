#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if command -v darwin-rebuild >/dev/null 2>&1; then
  darwin-rebuild switch --flake .#macbook
else
  nix run nix-darwin -- switch --flake .#macbook
fi
