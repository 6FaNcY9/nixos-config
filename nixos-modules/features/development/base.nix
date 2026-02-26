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
  cfgLib = import ../../../lib { inherit lib; };
  inherit (cfgLib) mkBoolOpt;
in
{
  options.features.development.base = {
    enable = lib.mkEnableOption "development environment and tools";

    virtualization = {
      docker = {
        enable = mkBoolOpt false "Enable Docker container runtime";

        autoPrune = {
          enable = mkBoolOpt true "Enable automatic Docker resource cleanup";

          dates = lib.mkOption {
            type = lib.types.str;
            default = "weekly";
            description = "How often to prune Docker resources";
          };
        };
      };

      podman = {
        enable = mkBoolOpt false "Enable Podman container runtime";

        dockerCompat = mkBoolOpt false "Enable Docker CLI compatibility for Podman";
      };
    };

    buildEssentials = {
      enable = mkBoolOpt true "Install build essentials (make, cmake, gcc, etc)";
    };

    debugTools = {
      enable = mkBoolOpt true "Install debugging tools (gdb, strace, ltrace)";
    };

    direnv = {
      enable = mkBoolOpt true "Enable direnv for automatic environment loading";

      enableNixDirenv = mkBoolOpt true "Enable nix-direnv integration";
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
      lib.optionals cfg.buildEssentials.enable [
        pkgs.gnumake
        pkgs.cmake
        pkgs.pkg-config
        pkgs.gcc
        pkgs.binutils
      ]
      ++ lib.optionals cfg.debugTools.enable [
        pkgs.gdb
        pkgs.strace
        pkgs.ltrace
      ];

    # File watcher limits - required for large projects (VSCode, webpack, etc.)
    boot.kernel.sysctl = {
      # Default is 8192 - increase to 524288 for large monorepos and node_modules
      "fs.inotify.max_user_watches" = lib.mkForce cfg.fileWatchers.maxUserWatches;
      # Default is 128 - increase to 1024 for multiple concurrent dev environments
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
