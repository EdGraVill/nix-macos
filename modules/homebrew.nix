{ ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    brews = [
      "bat"
      "coreutils"
      "defaultbrowser"
      "dockutil"
      "ffmpeg"
      "git-lfs"
      "hexyl"
      "htmlq"
      "imagemagick"
      "jq"
      "lazygit"
      "p7zip"
      "qpdf"
      "rsync"
      "telnet"
      "wget"
      "xq"
      "yq"
    ];

    casks = [
      "brave-browser"
      "dbeaver-community"
      "gpg-suite"
      "iterm2"
      "orbstack"
      "slack"
      "visual-studio-code"
      "whatsapp"
      "zulu@17"
    ];
  };
}
