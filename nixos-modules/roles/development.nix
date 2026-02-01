# Development role - enables development tools and virtualization
{
  lib,
  config,
  pkgs,
  ...
}: {
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

    # Development-friendly kernel parameters via centralized sysctl module
    development.sysctlTweaks.enable = true;

    # Enable direnv system-wide
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
