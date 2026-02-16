# Core system configuration - Base settings for all NixOS hosts
#
# This module provides fundamental system configuration including:
#   - User account and groups
#   - Networking and hostname
#   - Nix settings (flakes, auto-gc, optimization)
#   - System packages (essential CLI tools)
#   - Default shell and environment
#
# This module is automatically imported for all hosts via ez-configs
{
  lib,
  pkgs,
  inputs,
  username,
  repoRoot,
  ...
}:
let
  userGroups = [
    "wheel"
    "networkmanager"
    "audio"
    "video"
  ];

  systemPackages = with pkgs; [
    btrfs-progs
    cachix # Binary cache management
    curl
    efibootmgr
    git
    snapper
    vim
    wget
    gnupg
    sops
    age
    ssh-to-age
    # Framework-specific tools (only on Framework laptops)
    framework-tool # Framework hardware control utility
    fw-ectool # Embedded controller interface
    auto-cpufreq # CPU frequency scaling for battery optimization
    fprintd # Fingerprint authentication daemon
  ];
in
{
  # ------------------------------------------------------------
  # Host + locale
  # ------------------------------------------------------------
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de-latin1-nodeadkeys";

  # ------------------------------------------------------------
  # Nix + registry
  # ------------------------------------------------------------
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = false; # Disabled: runs inline on every build (adds latency). Run manually: sudo nix-store --optimise
      warn-dirty = true;
      # Optimize builds
      max-jobs = "auto";
      cores = 0;

      # Binary caches for faster builds (community pattern)
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://vino-nixos-config.cachix.org" # Personal binary cache
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "vino-nixos-config.cachix.org-1:8LFVkzmO/+crLWO0Q3bqWOOamVjScT3v1/PCHPiTiUU=" # Personal cache key
      ];
    };

    # Use nh's cleaner to avoid double GC scheduling.
    gc.automatic = lib.mkDefault false;

    # Store optimisation disabled (run manually: sudo nix-store --optimise)
    optimise.automatic = false;
  };

  # Pin nixpkgs for legacy commands and for `nix run nixpkgs#...`
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # Allow unfree, catch deprecated aliases, wire overlays (keeps pkgs.stable available as fallback).
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowAliases = false;
    };
    overlays = [ (import ../overlays { inherit inputs; }).default ];
  };

  # ------------------------------------------------------------
  # Shell + users + containers + gnupg
  # ------------------------------------------------------------
  programs = {
    fish = {
      enable = true;

      # Keep vendor completions/functions, but disable vendor config snippets
      vendor = {
        completions.enable = true;
        functions.enable = true;
        config.enable = false; # fzf.fish provides bindings; avoids vendor fzf_key_bindings noise
      };
    };

    gnupg.agent = {
      enable = true;
      # Use GTK2 pinentry for GUI popup (works with i3 + XFCE)
      # pinentry-curses doesn't work in SSH/OpenCode terminal
      # Alternative options: pinentry-gnome3, pinentry-qt, pinentry-rofi
      pinentryPackage = pkgs.pinentry-gtk2;
      enableSSHSupport = true;
    };

    # nh: friendly NixOS rebuild wrapper; `flake` tells it where to find this config
    # so `nh os switch` works without an explicit --flake path.
    nh = {
      enable = true;
      flake = repoRoot;
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };
    };

    # Command-not-found with nix-index (better than default)
    command-not-found.enable = false;
    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };

    # Allow running non‑Nix dynamic binaries (bunx/AppImage/vendor CLIs)
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Default/core libs (NixOS wiki baseline)
        zlib
        zstd
        stdenv.cc.cc
        curl
        openssl
        attr
        libssh
        bzip2
        libxml2
        acl
        libsodium
        util-linux
        xz
        systemd

        # Common desktop/runtime additions
        glib
        gtk3
        libGL
        libva
        pipewire
        libx11
        libxext
        libxrandr
        libxrender
        libxcb
      ];
    };
  };

  users = {
    defaultUserShell = pkgs.fish;

    users.${username} = {
      isNormalUser = true;
      description = username;
      extraGroups = userGroups;
    };
  };

  # Docker moved to roles/development.nix

  security = {
    sudo.wheelNeedsPassword = true;
  };

  # ------------------------------------------------------------
  # Packages
  # ------------------------------------------------------------
  environment.systemPackages = systemPackages;

  # Many third-party scripts use #!/bin/bash shebangs (e.g. Claude Code plugins).
  # NixOS doesn't provide /bin/bash by default — only /bin/sh.
  environment.shells = [ pkgs.bash ];
  system.activationScripts.binbash = lib.stringAfter [ "stdio" ] ''
    ln -sfn ${pkgs.bash}/bin/bash /bin/bash
  '';

  # ------------------------------------------------------------
  # Fonts
  # ------------------------------------------------------------
  fonts = {
    fontconfig.useEmbeddedBitmaps = true;
    packages = with pkgs; [
      nerd-fonts.symbols-only # Symbols Nerd Font Mono — monospaced icons for polybar
      iosevka-bin # Plain Iosevka Term for polybar text
    ];
  };

  system.stateVersion = "25.11";
}
