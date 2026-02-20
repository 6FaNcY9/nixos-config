# Custom packages exported via flake outputs.
{ primaryHost, username, ... }:
{
  perSystem =
    {
      pkgs,
      inputs',
      config,
      ...
    }:
    {
      packages = {
        gruvboxWallpaperOutPath = pkgs.writeText "gruvbox-wallpaper-path" (
          builtins.toString inputs'.gruvbox-wallpaper.packages.default
        );

        update = pkgs.writeShellApplication {
          name = "update";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.git
            pkgs.nix
          ];
          meta.description = "Update flake inputs";
          text = builtins.readFile ./scripts/update.sh;
        };

        clean = pkgs.writeShellApplication {
          name = "clean";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.git
          ];
          meta.description = "Remove result symlinks";
          text = builtins.readFile ./scripts/clean.sh;
        };

        qa = pkgs.writeShellApplication {
          name = "qa";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.deadnix
            pkgs.git
            pkgs.nix
            pkgs.pre-commit
            pkgs.statix
            config.treefmt.build.wrapper
          ];
          runtimeEnv.PRECOMMIT_CONFIG = config.pre-commit.settings.configFile;
          meta.description = "Format, lint, and run flake checks";
          text = builtins.readFile ./scripts/qa.sh;
        };

        commit-tool = pkgs.writeShellApplication {
          name = "commit";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.deadnix
            pkgs.git
            pkgs.nix
            pkgs.pre-commit
            pkgs.statix
            config.treefmt.build.wrapper
          ];
          runtimeEnv.PRECOMMIT_CONFIG = config.pre-commit.settings.configFile;
          meta.description = "Run QA, stage, and commit with editor";
          text = builtins.readFile ./scripts/commit.sh;
        };

        generate-age-key = pkgs.writeShellApplication {
          name = "generate-age-key";
          runtimeInputs = [
            pkgs.age
            pkgs.coreutils
          ];
          meta.description = "Generate Age key for sops-nix encryption";
          text = builtins.readFile ./scripts/generate-age-key.sh;
        };

        sysinfo = pkgs.writeShellApplication {
          name = "sysinfo";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.gawk
            pkgs.git
            pkgs.gnugrep
            pkgs.gnupg
            pkgs.nix
          ];
          meta.description = "System diagnostics and configuration status";
          text = builtins.readFile ./scripts/sysinfo.sh;
        };

        cachix-push = pkgs.writeShellApplication {
          name = "cachix-push";
          runtimeInputs = [
            pkgs.cachix
            pkgs.coreutils
            pkgs.gnugrep
            pkgs.nix
          ];
          runtimeEnv = {
            CACHE_NAME = "${username}-nixos-config";
            PRIMARY_HOST = primaryHost;
          };
          meta.description = "Push current system build to Cachix";
          text = builtins.readFile ./scripts/cachix-push.sh;
        };
      };
    };
}
