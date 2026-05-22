{ username, ... }:

{
  # Remote Login / SSH.
  services.openssh.enable = true;

  system.activationScripts.fileSharing.text = ''
    # File Sharing / SMB for ~/Public only.
    mkdir -p "/Users/${username}/Public"
    chown ${username}:staff "/Users/${username}/Public" || true

    /bin/launchctl load -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null || true

    # Add Public as an SMB share. Ignore failure if already exists.
    /usr/sbin/sharing -a "/Users/${username}/Public" -S "Public" 2>/dev/null || true
  '';
}
