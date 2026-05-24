{ pkgs, username, ... }:

{
  imports = [
    ../modules/nix.nix
    ../modules/homebrew.nix
    ../modules/macos.nix
    ../modules/dock.nix
    ../modules/finder.nix
    ../modules/energy.nix
    ../modules/services.nix
    ../modules/fonts.nix
  ];

  system.primaryUser = username;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # Keep this fixed after first install unless nix-darwin explicitly asks for a migration.
  system.stateVersion = 5;
}
