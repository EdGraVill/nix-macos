#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install)
  echo "Nix installed. Open a new terminal if this shell cannot find nix yet."
fi

./scripts/apply.sh

if [ -d "./secrets" ]; then
  ./scripts/restore-ssh.sh || true
  ./scripts/restore-gpg.sh || true
  ./scripts/restore-home-files.sh || true
  ./scripts/restore-repos.sh || true
else
  echo "No ./secrets folder found. Skipping secrets restore."
fi

./scripts/apply.sh

mkdir -p "$HOME/Desktop"
cp ./todo.md "$HOME/Desktop/nix-restore-todo.md"

if command -v code >/dev/null 2>&1; then
  code "$HOME/Desktop/nix-restore-todo.md" || true
else
  open -a "Visual Studio Code" "$HOME/Desktop/nix-restore-todo.md" 2>/dev/null || true
fi

echo
echo "Bootstrap complete."
echo "Review: $HOME/Desktop/nix-restore-todo.md"
