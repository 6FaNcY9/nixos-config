# Development role - enables development tools and virtualization
{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf config.roles.development {
    # Virtualization
    virtualisation = {
      docker = {
        enable = lib.mkDefault true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      # Podman as alternative (opt-in)
      podman = {
        enable = lib.mkDefault false;
        dockerCompat = lib.mkDefault false; # Don't conflict with docker
      };
    };

    # Development-focused system packages
    environment.systemPackages = with pkgs; [
      # Build essentials
      gnumake
      cmake
      pkg-config
      gcc
      binutils

      # Debug tools
      gdb
      strace
      ltrace

      # Documentation
      man-pages
      man-pages-posix
    ];

    # Allow unfree packages (common for dev tools)
    nixpkgs.config.allowUnfree = lib.mkDefault true;

    # Development-friendly kernel parameters
    boot.kernel.sysctl = {
      # Allow more file watchers (for large projects)
      "fs.inotify.max_user_watches" = lib.mkDefault 524288;
      "fs.inotify.max_user_instances" = lib.mkDefault 1024;
    };

    # Enable direnv system-wide
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
