{ fullName, email, ... }:

{
  programs.git = {
    enable = true;

    userName = fullName;
    userEmail = email;

    lfs.enable = true;

    extraConfig = {
      commit.gpgsign = true;
      rerere.enabled = true;
      core.ignorecase = false;
      core.excludesfile = "~/.gitignore_global";
      pull.rebase = true;

      # Later, when you know the restored GPG signing key:
      # user.signingkey = "KEY_ID_HERE";

      # Later, for work-specific identities:
      # includeIf."hasconfig:remote.*.url:git@github-parsable:*".path =
      #   "~/.config/git/includes/parsable.gitconfig";
    };
  };
}
