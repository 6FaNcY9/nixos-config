# Custom packages exported via flake outputs.
#
# Packages:
#   gruvboxWallpaperOutPath — Path to Gruvbox wallpaper from input
#   update                  — Update flake inputs script
#   clean                   — Remove result symlinks script
#   qa                      — Format, lint, and run checks script
#   commit-tool             — Interactive commit helper with QA
#   generate-age-key        — Generate age key for sops-nix encryption
#   sysinfo                 — System diagnostics and configuration status
#   cachix-push             — Push build results to Cachix binary cache
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
        # Path to Gruvbox wallpaper from flake input
        gruvboxWallpaperOutPath = pkgs.writeText "gruvbox-wallpaper-path" (
          toString inputs'.gruvbox-wallpaper.packages.default
        );

        # Update flake inputs
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

        # Clean build artifacts and result symlinks
        clean = pkgs.writeShellApplication {
          name = "clean";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.git
          ];
          meta.description = "Remove result symlinks";
          text = builtins.readFile ./scripts/clean.sh;
        };

        # Quality assurance (format, lint, flake checks)
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

        # Interactive commit helper with QA checks
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

        # Generate age encryption key pair for sops-nix
        generate-age-key = pkgs.writeShellApplication {
          name = "generate-age-key";
          runtimeInputs = [
            pkgs.age
            pkgs.coreutils
          ];
          meta.description = "Generate Age key for sops-nix encryption";
          text = builtins.readFile ./scripts/generate-age-key.sh;
        };

        # System diagnostics and configuration status
        sysinfo = pkgs.writeShellApplication {
          name = "sysinfo";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.findutils
            pkgs.gawk
            pkgs.git
            pkgs.gnugrep
            pkgs.gnupg
            pkgs.nix
          ];
          meta.description = "System diagnostics and configuration status";
          text = builtins.readFile ./scripts/sysinfo.sh;
        };

        # Push current system build to Cachix binary cache
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
