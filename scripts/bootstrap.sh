#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

load_nix_profile() {
  if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
}

prepare_etc_for_nix_darwin() {
  for file in /etc/bashrc /etc/zshrc; do
    if [ -e "$file" ] && [ ! -e "$file.before-nix-darwin" ]; then
      echo "Moving $file to $file.before-nix-darwin so nix-darwin can manage it..."
      sudo mv "$file" "$file.before-nix-darwin"
    fi
  done
}

if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install)

  echo "Loading Nix profile into current shell..."
  load_nix_profile
else
  load_nix_profile
fi

if ! command -v nix >/dev/null 2>&1; then
  echo
  echo "Nix was installed, but it is still not available in this shell."
  echo "Close this terminal, open a new one, and run:"
  echo
  echo "  ./scripts/bootstrap.sh"
  echo
  exit 1
fi

prepare_etc_for_nix_darwin

./scripts/apply.sh

if [ -d "./secrets" ]; then
  ./scripts/restore-ssh.sh || true
  ./scripts/restore-gpg.sh || true
  ./scripts/restore-home-files.sh || true
  ./scripts/restore-iterm2.sh || true
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
