# Git configuration with delta integration
# User identity and signing are set in home-configurations/vino/default.nix
_: {
  programs = {
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        light = false;
        line-numbers = true;
      };
    };

    git = {
      enable = true;

      settings = {
        init.defaultBranch = "main";
        pull.ff = "only";
        push.autoSetupRemote = true;

        core.editor = "nvim";
        diff.colorMoved = "default";
        merge.conflictstyle = "zdiff3";
        fetch.prune = true;
        rebase.autoStash = true;
      };
    };
  };
}
