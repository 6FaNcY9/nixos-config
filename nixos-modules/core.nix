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
    gcc
    sops
    age
    ssh-to-age
    nix-tree # Visualize nix dependencies
    nix-diff # Compare nix derivations
    nix-output-monitor # Better nix build output
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
    };

    # Use nh's cleaner to avoid double GC scheduling.
    gc.automatic = lib.mkDefault false;

    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  # Pin nixpkgs for legacy commands and for `nix run nixpkgs#...`
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # Allow unfree and wire overlays (keeps pkgs.unstable available everywhere).
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
      pinentryPackage = pkgs.pinentry-curses;
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
    sudo.wheelNeedsPassword = true;
  };

  # ------------------------------------------------------------
  # Packages
  # ------------------------------------------------------------
  environment.systemPackages = systemPackages;

  # ------------------------------------------------------------
  # Fonts
  # ------------------------------------------------------------
  fonts.fontconfig.useEmbeddedBitmaps = true;

  system.stateVersion = "25.11";
}
