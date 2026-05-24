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

load_nix_profile

if command -v darwin-rebuild >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    darwin-rebuild switch --flake .#macbook
  else
    sudo -H darwin-rebuild switch --flake .#macbook
  fi
else
  if [ "$(id -u)" -eq 0 ]; then
    nix \
      --extra-experimental-features "nix-command flakes" \
      run github:nix-darwin/nix-darwin/master#darwin-rebuild -- \
      switch --flake .#macbook
  else
    sudo -H /nix/var/nix/profiles/default/bin/nix \
      --extra-experimental-features "nix-command flakes" \
      run github:nix-darwin/nix-darwin/master#darwin-rebuild -- \
      switch --flake .#macbook
  fi
fi
