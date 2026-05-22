{ ... }:

{
  programs.ssh = {
    enable = true;

    includes = [
      "~/.orbstack/ssh/config"
    ];

    matchBlocks = {
      "orb" = {
        hostname = "orb";
        user = "edgravill@ubuntu";
      };

      "github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/ghp";
        identitiesOnly = true;
      };

      "hf.co" = {
        hostname = "hf.co";
        identityFile = "~/.ssh/hf";
        identitiesOnly = true;
      };

      "hra" = {
        hostname = "github.com";
        identityFile = "~/.ssh/hra";
        identitiesOnly = true;
      };
    };
  };
}
