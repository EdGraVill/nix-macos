#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SRC="./secrets/app-configs/wallpapers"
DEST="$HOME/bg"

if [ ! -d "$SRC" ]; then
  echo "No wallpapers backup found at $SRC"
  exit 0
fi

if [ -d "$SRC/images" ]; then
  mkdir -p "$DEST"
  rsync -a "$SRC/images/" "$DEST/"
  echo "Wallpapers restored to $DEST"
fi

# Best-effort: set wallpaper folder rotation using AppleScript.
# macOS support varies by version, so this may not fully configure the 5-minute rotation UI.
osascript <<EOF || true
tell application "System Events"
  tell every desktop
    set picture to POSIX file "$DEST/Halo Foundry"
  end tell
end tell
EOF

# Backup preference restore, best effort only.
if [ -f "$SRC/preferences/com.apple.desktop.plist" ]; then
  cp -p "$SRC/preferences/com.apple.desktop.plist" "$HOME/Library/Preferences/com.apple.desktop.plist" || true
fi

if [ -f "$SRC/preferences/Index.plist" ]; then
  mkdir -p "$HOME/Library/Application Support/com.apple.wallpaper/Store"
  cp -p "$SRC/preferences/Index.plist" "$HOME/Library/Application Support/com.apple.wallpaper/Store/Index.plist" || true
fi

killall WallpaperAgent 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

echo "Wallpaper restore completed as best effort."
echo "If rotation is not active, choose ~/Pictures/Wallpapers manually once in System Settings."
