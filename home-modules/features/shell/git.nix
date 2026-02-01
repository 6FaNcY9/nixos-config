# Git configuration with delta integration
{lib, ...}: {
  options.gitConfig = {
    userName = lib.mkOption {
      type = lib.types.str;
      description = "Git user name";
    };
    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Git user email";
    };
    signingKey = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "GPG signing key ID";
    };
  };

  config = {
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
          user = {
            name = lib.mkDefault "";
            email = lib.mkDefault "";
            signingkey = lib.mkDefault "";
          };

          commit.gpgsign = lib.mkDefault false;

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
  };
}
