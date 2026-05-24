{ username, ... }:

{
  system.defaults.finder = {
    AppleShowAllExtensions = true;

    FXPreferredViewStyle = "icnv";
    FXRemoveOldTrashItems = true;

    ShowExternalHardDrivesOnDesktop = false;
    ShowHardDrivesOnDesktop = false;
    ShowRemovableMediaOnDesktop = false;
    ShowMountedServersOnDesktop = false;

    ShowPathbar = true;
    ShowStatusBar = true;

    NewWindowTarget = "Other";
    NewWindowTargetPath = "file:///Users/${username}/";
  };

  system.activationScripts.finder.text = ''
    # iCloud Desktop/Documents. This assumes iCloud is already signed in before applying Nix.
    /usr/bin/defaults write com.apple.finder FXICloudDriveDesktop -bool true
    /usr/bin/defaults write com.apple.finder FXICloudDriveDocuments -bool true
    /usr/bin/defaults write com.apple.finder FXICloudDriveEnabled -bool true

    # Open folders in tabs instead of new windows where supported.
    /usr/bin/defaults write com.apple.finder FinderSpawnTab -bool true

    # Finder search: search this Mac by default.
    /usr/bin/defaults write com.apple.finder FXDefaultSearchScope -string "SCev"

    # Remove Finder recents/history state as best effort.
    /usr/bin/defaults delete com.apple.finder GoToFieldHistory 2>/dev/null || true
    /usr/bin/defaults delete com.apple.finder FXRecentFolders 2>/dev/null || true
    /usr/bin/defaults delete com.apple.finder RecentMoveAndCopyDestinations 2>/dev/null || true
    /usr/bin/defaults delete com.apple.finder SGTRecentFileSearches 2>/dev/null || true

    # Icon view best-effort preferences.
    /usr/bin/defaults write com.apple.finder FXArrangeGroupViewBy -string "Name"
    /usr/bin/defaults write com.apple.finder FXPreferredGroupBy -string "Name"

    /usr/bin/killall Finder 2>/dev/null || true
  '';
}
