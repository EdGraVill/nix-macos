{ fullName, email, ... }:

{
  programs.git = {
    enable = true;

    lfs.enable = true;

    settings = {
      user = {
        name = fullName;
        email = email;

        # Later, when you know the restored GPG signing key:
        # signingkey = "KEY_ID_HERE";
      };

      commit.gpgsign = true;
      rerere.enabled = true;
      core.ignorecase = false;
      core.excludesfile = "~/.gitignore_global";
      pull.rebase = true;

      # Later, for work-specific identities:
      # includeIf."hasconfig:remote.*.url:git@github-parsable:*".path =
      #   "~/.config/git/includes/parsable.gitconfig";
    };
  };
}
