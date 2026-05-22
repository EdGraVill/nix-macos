{ username, ... }:

{
  imports = [
    ./zsh.nix
    ./git.nix
    ./ssh.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "24.11";

  home.file.".gitignore_global".text = ''
    .DS_Store
    .idea
    .vscode/settings.json
    node_modules
    dist
    .env
    .env.*
  '';

  home.file.".config/git/includes/.keep".text = "";

  programs.home-manager.enable = true;
}
