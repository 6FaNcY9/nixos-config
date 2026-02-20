# Feature: Development Environment
# Provides: Development tools, virtualization, and build essentials
# Dependencies: None
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.features.development.base;
in
{
  options.features.development.base = {
    enable = lib.mkEnableOption "development environment and tools";

    virtualization = {
      docker = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Docker container runtime";
        };

        autoPrune = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable automatic Docker resource cleanup";
          };

          dates = lib.mkOption {
            type = lib.types.str;
            default = "weekly";
            description = "How often to prune Docker resources";
          };
        };
      };

      podman = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Podman container runtime";
        };

        dockerCompat = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Docker CLI compatibility for Podman";
        };
      };
    };

    buildEssentials = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install build essentials (make, cmake, gcc, etc)";
      };
    };

    debugTools = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Install debugging tools (gdb, strace, ltrace)";
      };
    };

    direnv = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable direnv for automatic environment loading";
      };

      enableNixDirenv = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable nix-direnv integration";
      };
    };

    fileWatchers = {
      maxUserWatches = lib.mkOption {
        type = lib.types.int;
        default = 524288;
        description = "Maximum number of inotify file watchers (for large projects)";
      };

      maxUserInstances = lib.mkOption {
        type = lib.types.int;
        default = 1024;
        description = "Maximum number of inotify instances";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Virtualization
    virtualisation = {
      docker = lib.mkIf cfg.virtualization.docker.enable {
        enable = true;
        autoPrune = {
          inherit (cfg.virtualization.docker.autoPrune) enable dates;
        };
      };

      podman = lib.mkIf cfg.virtualization.podman.enable {
        enable = true;
        inherit (cfg.virtualization.podman) dockerCompat;
      };
    };

    # Build essentials
    environment.systemPackages =
      let
        p = pkgs;
        buildPkgs = lib.optionals cfg.buildEssentials.enable [
          p.gnumake
          p.cmake
          p.pkg-config
          p.gcc
          p.binutils
        ];
        debugPkgs = lib.optionals cfg.debugTools.enable [
          p.gdb
          p.strace
          p.ltrace
        ];
      in
      buildPkgs ++ debugPkgs;

    # File watcher limits for large projects
    boot.kernel.sysctl = {
      "fs.inotify.max_user_watches" = lib.mkForce cfg.fileWatchers.maxUserWatches;
      "fs.inotify.max_user_instances" = lib.mkForce cfg.fileWatchers.maxUserInstances;
    };

    # direnv integration
    programs.direnv = lib.mkIf cfg.direnv.enable {
      enable = true;
      nix-direnv.enable = cfg.direnv.enableNixDirenv;
    };

    # Warnings
    warnings =
      lib.optional (cfg.virtualization.docker.enable && cfg.virtualization.podman.enable)
        "features.development.base: Both Docker and Podman are enabled. Consider using only one to avoid conflicts.";
  };
}
