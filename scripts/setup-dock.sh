#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${SUDO_USER:-$(whoami)}"
USER_HOME="$(dscl . -read "/Users/$USER_NAME" NFSHomeDirectory | awk '{print $2}')"
DOCKUTIL="/opt/homebrew/bin/dockutil"

if [ ! -x "$DOCKUTIL" ]; then
  echo "dockutil not found at $DOCKUTIL. Skipping Dock setup."
  exit 0
fi

echo "Configuring Dock for $USER_NAME..."

# Remove everything except Finder/Trash, which macOS manages.
sudo -u "$USER_NAME" "$DOCKUTIL" --remove all --no-restart "$USER_HOME" || true

add_app() {
  local app_path="$1"

  if [ -e "$app_path" ]; then
    echo "Adding to Dock: $app_path"
    sudo -u "$USER_NAME" "$DOCKUTIL" --add "$app_path" --no-restart "$USER_HOME" || true
  else
    echo "Missing app, skipping Dock item: $app_path"
  fi
}

add_app "/Applications/Brave Browser.app"
add_app "/Applications/Visual Studio Code.app"
add_app "/System/Applications/iPhone Mirroring.app"
add_app "/Applications/WhatsApp.app"
add_app "/System/Applications/Mail.app"
add_app "/Applications/Slack.app"
add_app "/Applications/iTerm.app"
add_app "/System/Applications/Calendar.app"

killall Dock 2>/dev/null || true

echo "Dock configured."
