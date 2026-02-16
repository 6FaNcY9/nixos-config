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
        alias = {
          co = "checkout";
          br = "branch";
          ci = "commit";
          st = "status";
          lg = "log --oneline --graph --decorate --all";
          unstage = "reset HEAD --";
          last = "log -1 HEAD";
          amend = "commit --amend --no-edit";
          wip = "commit -am 'WIP'";
        };
        init.defaultBranch = "main";
        pull.ff = "only";
        push.autoSetupRemote = true;

        core.editor = "nvim";
        diff = {
          colorMoved = "default";
          algorithm = "histogram"; # Better diff output than default myers
        };
        merge.conflictstyle = "zdiff3";
        fetch.prune = true;
        fetch.pruneTags = true;
        rebase = {
          autoStash = true;
          autoSquash = true; # Auto-fixup commits marked with fixup!/squash!
        };
        credential.helper = "libsecret";
        rerere.enabled = true;
        column.ui = "auto";
        branch.sort = "-committerdate"; # Most recent branches first
        tag.sort = "-version:refname"; # Semantic version sorting for tags
      };
    };
  };
}
