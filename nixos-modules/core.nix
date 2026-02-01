{
  lib,
  pkgs,
  inputs,
  username,
  repoRoot,
  ...
}: let
  userGroups = ["wheel" "networkmanager" "audio" "video"];

  systemPackages = with pkgs; [
    btrfs-progs
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
    openssh-askpass # GUI sudo password prompt for OpenCode/SSH environments
    # Framework-specific tools (only on Framework laptops)
    framework-tool # Framework hardware control utility
    fw-ectool # Embedded controller interface
    auto-cpufreq # CPU frequency scaling for battery optimization
    fprintd # Fingerprint authentication daemon
  ];
in {
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
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      warn-dirty = true;
      # Optimize builds
      max-jobs = "auto";
      cores = 0;

      # Binary caches for faster builds (community pattern)
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # Use nh's cleaner to avoid double GC scheduling.
    gc.automatic = lib.mkDefault false;

    # Disable automatic store optimisation (reduces background I/O)
    # Run manually when needed: sudo nix-store --optimise
    optimise = {
      automatic = false;
      dates = ["weekly"];
    };
  };

  # Pin nixpkgs for legacy commands and for `nix run nixpkgs#...`
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # Allow unfree and wire overlays (keeps pkgs.stable available as fallback).
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [(import ../overlays {inherit inputs;}).default];
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
    nix-ld.enable = true;
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
    # Hybrid sudo approach: NOPASSWD for safe system management commands
    # See: docs/SUDO-OPENCODE-WORKAROUND.md
    sudo = {
      wheelNeedsPassword = true; # Default: require password for dangerous commands

      # NOPASSWD rules for safe, common system management commands
      # This enables smooth nixos-rebuild in OpenCode/SSH environments
      extraRules = [
        {
          users = [username];
          commands = [
            {
              command = "/run/current-system/sw/bin/nixos-rebuild";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/home-manager";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/systemctl";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/nix-store";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/nh";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    };
  };

  # ------------------------------------------------------------
  # Packages
  # ------------------------------------------------------------
  environment.systemPackages = systemPackages;

  # ------------------------------------------------------------
  # Environment Variables
  # ------------------------------------------------------------
  environment.variables = {
    # Sudo askpass helper for OpenCode/SSH environments (GUI password prompt)
    SUDO_ASKPASS = "${pkgs.openssh-askpass}/libexec/ssh-askpass";
  };

  # ------------------------------------------------------------
  # Fonts
  # ------------------------------------------------------------
  fonts = {
    fontconfig.useEmbeddedBitmaps = true;
    packages = with pkgs; [
      font-awesome_6 # Required for polybar icons
    ];
  };

  system.stateVersion = "25.11";
}
