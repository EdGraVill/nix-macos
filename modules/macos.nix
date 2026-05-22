{ username, ... }:

{
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleAccentColor = -1;
      AppleHighlightColor = "0.847059 0.847059 0.862745 Graphite";

      AppleShowAllExtensions = true;
      AppleEnableSwipeNavigateWithScrolls = false;

      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;

      "com.apple.sound.beep.feedback" = 0;
      "com.apple.sound.beep.flash" = 0;
      "com.apple.sound.beep.sound" = "/System/Library/Sounds/Morse.aiff";

      "com.apple.springing.delay" = "0.5";
      "com.apple.springing.enabled" = true;
      "com.apple.swipescrolldirection" = true;
      "com.apple.trackpad.forceClick" = false;
    };

    screencapture = {
      location = "/Users/${username}/Desktop/Screenshots";
      type = "png";
      show-thumbnail = false;
      disable-shadow = false;
    };

    trackpad = {
      Clicking = false;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = false;
    };

    loginwindow = {
      GuestEnabled = false;
    };
  };

  system.activationScripts.macosPreferences.text = ''
    mkdir -p "/Users/${username}/Desktop/Screenshots"
    chown ${username}:staff "/Users/${username}/Desktop/Screenshots" || true

    # Disable all hot corners.
    /usr/bin/defaults write com.apple.dock wvous-tl-corner -int 1
    /usr/bin/defaults write com.apple.dock wvous-tr-corner -int 1
    /usr/bin/defaults write com.apple.dock wvous-bl-corner -int 1
    /usr/bin/defaults write com.apple.dock wvous-br-corner -int 1

    # Battery percentage in menu bar.
    /usr/bin/defaults write com.apple.menuextra.battery ShowPercent -string "YES"

    # Best-effort default browser.
    if [ -x /opt/homebrew/bin/defaultbrowser ]; then
      /opt/homebrew/bin/defaultbrowser brave || true
    fi
  '';
}
