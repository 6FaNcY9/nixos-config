# Feature: Development Environment
# Provides: Development tools, virtualization, and build essentials
# Dependencies: None
{
  lib,
  config,
  pkgs,
  username,
  ...
}:
let
  cfg = config.features.development.base;
  mkBool =
    default: desc:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      description = desc;
    };
in
{
  options.features.development.base = {
    enable = lib.mkEnableOption "development environment and tools";

    virtualization = {
      docker = {
        enable = mkBool false "Enable Docker container runtime (rootful)";

        rootless = {
          enable = mkBool false "Enable rootless Docker (runs as user, no docker group needed)";
          setSocketVariable = mkBool true "Set DOCKER_HOST env var so docker CLI works without extra config";
        };

        autoPrune = {
          enable = mkBool true "Enable automatic Docker resource cleanup";

          dates = lib.mkOption {
            type = lib.types.str;
            default = "weekly";
            description = "How often to prune Docker resources";
          };
        };
      };

      podman = {
        enable = mkBool false "Enable Podman container runtime";

        dockerCompat = mkBool false "Enable Docker CLI compatibility for Podman";
      };
    };

    buildEssentials = {
      enable = mkBool true "Install build essentials (make, cmake, gcc, etc)";
    };

    debugTools = {
      enable = mkBool true "Install debugging tools (gdb, strace, ltrace)";
    };

    direnv = {
      enable = mkBool true "Enable direnv for automatic environment loading";

      enableNixDirenv = mkBool true "Enable nix-direnv integration";
    };

    nixLd = {
      enable = mkBool true "Enable nix-ld for running unpatched ELF binaries (Node downloads, Python wheels, VSCode extensions, etc.)";
    };

    wireshark = {
      enable = mkBool false "Enable Wireshark network analyzer (Qt) with packet capture group";
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
      docker = {
        enable = lib.mkIf cfg.virtualization.docker.enable true;
        autoPrune = lib.mkIf cfg.virtualization.docker.enable {
          inherit (cfg.virtualization.docker.autoPrune) enable dates;
        };
        rootless = lib.mkIf cfg.virtualization.docker.rootless.enable {
          enable = true;
          inherit (cfg.virtualization.docker.rootless) setSocketVariable;
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
      "fs.inotify.max_user_watches" = cfg.fileWatchers.maxUserWatches;
      # Default is 128 - increase to 1024 for multiple concurrent dev environments
      "fs.inotify.max_user_instances" = cfg.fileWatchers.maxUserInstances;
    };

    programs = {
      direnv = lib.mkIf cfg.direnv.enable {
        enable = true;
        nix-direnv.enable = cfg.direnv.enableNixDirenv;
      };

      # nix-ld: shim layer so downloaded unpatched binaries can find glibc/libs.
      # Full library list covers both core system needs and common desktop/runtime deps.
      nix-ld = lib.mkIf cfg.nixLd.enable {
        enable = true;
        libraries =
          let
            p = pkgs;
          in
          [
            # Core/system libs (NixOS wiki baseline)
            p.zlib
            p.zstd
            p.stdenv.cc.cc
            p.curl
            p.openssl
            p.attr
            p.libssh
            p.bzip2
            p.libxml2
            p.acl
            p.libsodium
            p.util-linux
            p.xz
            p.systemd

            # Common desktop/runtime additions
            p.glib
            p.gtk3
            p.libGL
            p.libva
            p.pipewire
            p.libx11
            p.libxext
            p.libxrandr
            p.libxrender
            p.libxcb
          ];
      };

      wireshark = lib.mkIf cfg.wireshark.enable {
        enable = true;
        package = pkgs.wireshark;
      };
    };

    users.users.${username}.extraGroups = lib.optionals cfg.wireshark.enable [ "wireshark" ];

    # Warnings
    warnings =
      lib.optional (cfg.virtualization.docker.enable && cfg.virtualization.podman.enable)
        "features.development.base: Both Docker and Podman are enabled. Consider using only one to avoid conflicts."
      ++ lib.optional (
        cfg.virtualization.docker.enable && cfg.virtualization.docker.rootless.enable
      ) "features.development.base: Both rootful and rootless Docker are enabled. Use one or the other.";
  };
}
