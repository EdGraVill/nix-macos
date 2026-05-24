{ ... }:

{
  programs.zsh = {
    enable = true;
    autocd = false;
    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "gitfast"
        "docker"
        "macos"
      ];
    };

    initContent = ''
      # Personal scripts restored from secrets/home-files by scripts/restore-home-files.sh
      [ -f "$HOME/.gitutils" ] && source "$HOME/.gitutils"
      [ -f "$HOME/utils/video.sh" ] && source "$HOME/utils/video.sh"
      [ -f "$HOME/utils/archiver.sh" ] && source "$HOME/utils/archiver.sh"
      [ -f "$HOME/utils/metaclean.sh" ] && source "$HOME/utils/metaclean.sh"

      # Android / React Native
      export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
      export ANDROID_HOME="$HOME/Library/Android/sdk"
      path+=("$ANDROID_HOME/emulator")
      path+=("$ANDROID_HOME/platform-tools")

      unset PREFIX
    '';
  };
}
