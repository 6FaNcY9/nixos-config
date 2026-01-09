{
  pkgs,
  inputs,
  username ? "vino",
  hostname ? "bandit",
  ...
}: let
  userGroups = ["wheel" "networkmanager" "audio" "video" "docker"];

  systemPackages = with pkgs; [
    btrfs-progs
    curl
    efibootmgr
    firefox
    git
    snapper
    vim
    wget
    gnupg
    gcc
    sops
    age
    ssh-to-age
  ];
in {
  # ------------------------------------------------------------
  # Host + locale
  # ------------------------------------------------------------
  networking = {
    hostName = hostname;
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
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  # Pin nixpkgs for legacy commands and for `nix run nixpkgs#...`
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # Allow unfree (redundant with flake import allowUnfree, but keeps modules safe)
  nixpkgs.config.allowUnfree = true;

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

      #pintentryPackage = pkgs.pinentry-gtk2;
      pinentryPackage = pkgs.pinentry-curses;
      # terminal pinentry
      enableSSHSupport = true;
    };
  };

  users = {
    defaultUserShell = pkgs.fish;

    users.${username} = {
      isNormalUser = true;
      description = username;
      extraGroups = userGroups;
      shell = pkgs.fish;
    };
  };

  virtualisation.docker.enable = true;

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
