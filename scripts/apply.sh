#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

load_nix_profile() {
  if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    # Multi-user Nix installer
    # shellcheck disable=SC1091
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # Single-user Nix installer
    # shellcheck disable=SC1090
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
}

load_nix_profile

if command -v darwin-rebuild >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    darwin-rebuild switch --flake .#macbook
  else
    sudo darwin-rebuild switch --flake .#macbook
  fi
else
  if [ "$(id -u)" -eq 0 ]; then
    nix \
      --extra-experimental-features "nix-command flakes" \
      run github:nix-darwin/nix-darwin/master#darwin-rebuild -- \
      switch --flake .#macbook
  else
    sudo nix \
      --extra-experimental-features "nix-command flakes" \
      run github:nix-darwin/nix-darwin/master#darwin-rebuild -- \
      switch --flake .#macbook
  fi
fi
