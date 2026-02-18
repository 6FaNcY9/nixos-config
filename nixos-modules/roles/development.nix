# Development role - enables development tools and virtualization
{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.roles.development {
    # Virtualization (opt-in, disabled by default to save resources)
    virtualisation = {
      docker = {
        enable = lib.mkDefault false;
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
    environment.systemPackages =
      let
        p = pkgs;
      in
      [
        # Build essentials
        p.gnumake
        p.cmake
        p.pkg-config
        p.gcc
        p.binutils

        # Debug tools
        p.gdb
        p.strace
        p.ltrace
        # Note: man-pages and man-pages-posix are in home-modules/profiles.nix corePkgs
      ];

    # Development-friendly kernel parameters
    boot.kernel.sysctl = {
      # Allow more file watchers (for large projects)
      "fs.inotify.max_user_watches" = lib.mkForce 524288;
      "fs.inotify.max_user_instances" = lib.mkForce 1024;
    };

    # Enable direnv system-wide
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
