{ ... }:

{
  nix = {
    enable = true;

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [
        "@admin"
      ];
    };

    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 3;
        Minute = 15;
      };
      options = "--delete-older-than 14d";
    };

    optimise.automatic = true;
  };

  nixpkgs.config.allowUnfree = true;
}
