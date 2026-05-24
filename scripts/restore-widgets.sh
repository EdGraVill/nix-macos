#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SRC="./secrets/app-configs/widgets"

if [ ! -d "$SRC" ]; then
  echo "No widgets backup found at $SRC"
  exit 0
fi

restore_if_exists() {
  local src="$1"
  local dest="$2"

  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dest")"
    rsync -a "$src" "$dest" 2>/dev/null || true
  fi
}

restore_if_exists "$SRC/group.com.apple.widgets" "$HOME/Library/Group Containers/"
restore_if_exists "$SRC/com.apple.notificationcenterui.plist" "$HOME/Library/Preferences/com.apple.notificationcenterui.plist"
restore_if_exists "$SRC/com.apple.widgets.plist" "$HOME/Library/Preferences/com.apple.widgets.plist"
restore_if_exists "$SRC/NotificationCenter" "$HOME/Library/Application Support/"

killall NotificationCenter 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

echo "Widgets restore completed as best effort. You may need to log out/in."
