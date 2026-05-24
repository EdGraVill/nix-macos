{ ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    includes = [
      "~/.orbstack/ssh/config"
    ];

    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      "orb" = {
        HostName = "orb";
        User = "edgravill@ubuntu";
      };

      "github.com" = {
        HostName = "github.com";
        IdentityFile = "~/.ssh/ghp";
        IdentitiesOnly = true;
      };

      "hf.co" = {
        HostName = "hf.co";
        IdentityFile = "~/.ssh/hf";
        IdentitiesOnly = true;
      };
    };
  };
}
