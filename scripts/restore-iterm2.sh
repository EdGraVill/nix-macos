#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SRC="./secrets/app-configs/iterm2"
PREF_DEST="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
APP_SUPPORT_DEST="$HOME/Library/Application Support/iTerm2"

if [ ! -d "$SRC" ]; then
  echo "No iTerm2 backup found at $SRC"
  exit 0
fi

if pgrep -x "iTerm2" >/dev/null 2>&1; then
  echo "Closing iTerm2 before restoring preferences..."
  osascript -e 'quit app "iTerm2"' || true
  sleep 2
fi

if [ -f "$SRC/com.googlecode.iterm2.plist" ]; then
  mkdir -p "$(dirname "$PREF_DEST")"
  cp -p "$SRC/com.googlecode.iterm2.plist" "$PREF_DEST"
fi

if [ -d "$SRC/Application Support iTerm2" ]; then
  mkdir -p "$APP_SUPPORT_DEST"
  rsync -a "$SRC/Application Support iTerm2/" "$APP_SUPPORT_DEST/"
fi

killall cfprefsd 2>/dev/null || true

echo "iTerm2 configuration restored."
