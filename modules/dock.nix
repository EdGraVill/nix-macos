{ username, ... }:

{
  system.defaults.dock = {
    orientation = "bottom";
    tilesize = 55;
    largesize = 70;
    magnification = true;
    minimize-to-application = true;
    autohide = true;
    launchanim = true;
    show-process-indicators = true;
    show-recents = false;
  };

  system.activationScripts.dock.text = ''
    DOCKUTIL="/opt/homebrew/bin/dockutil"

    if [ -x "$DOCKUTIL" ]; then
      # Finder and Trash are managed by macOS. YouTube PWA is manual because Safari creates it after login.
      "$DOCKUTIL" --remove all --no-restart "/Users/${username}" || true

      "$DOCKUTIL" --add "/Applications/Brave Browser.app" --no-restart "/Users/${username}" || true
      "$DOCKUTIL" --add "/Applications/Visual Studio Code.app" --no-restart "/Users/${username}" || true
      "$DOCKUTIL" --add "/System/Applications/iPhone Mirroring.app" --no-restart "/Users/${username}" || true
      "$DOCKUTIL" --add "/Applications/WhatsApp.app" --no-restart "/Users/${username}" || true
      "$DOCKUTIL" --add "/System/Applications/Mail.app" --no-restart "/Users/${username}" || true
      "$DOCKUTIL" --add "/Applications/Slack.app" --no-restart "/Users/${username}" || true
      "$DOCKUTIL" --add "/Applications/iTerm.app" --no-restart "/Users/${username}" || true
      "$DOCKUTIL" --add "/System/Applications/Calendar.app" --no-restart "/Users/${username}" || true
    fi

    /usr/bin/killall Dock 2>/dev/null || true
  '';
}
