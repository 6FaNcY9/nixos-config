{
  lib,
  pkgs,
  config,
  inputs,
  username ? "vino",
  hostname ? "bandit",
  ...
}:

let
  swapFile = "/swap/swapfile";
  btrfsFileSystems = [ "/" "/home" ];

  # Keep these in sync with the actual swap device/offset so hibernate works.
  resume = {
    device = "/dev/disk/by-uuid/0629aaee-1698-49d1-b3e1-e7bb6b957cda";
    offset = 1959063;
  };

  snapperUsers = [ username ];
  snapperTimeline = {
    FSTYPE = "btrfs";
    TIMELINE_CREATE = true;
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = "10";
    TIMELINE_LIMIT_DAILY = "7";
    TIMELINE_LIMIT_WEEKLY = "0";
    TIMELINE_LIMIT_MONTHLY = "0";
    TIMELINE_LIMIT_YEARLY = "0";
    NUMBER_CLEANUP = true;
    ALLOW_USERS = snapperUsers;
  };

  userGroups = [ "wheel" "networkmanager" "audio" "video" "docker" ];

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
  ];

  fontMain = "JetBrains Mono";
  fontMono = "JetBrainsMono Nerd Font Mono";
  fontEmoji = "Noto Color Emoji";
in
{
  # ------------------------------------------------------------
  # Host + locale
  # ------------------------------------------------------------
  networking.hostName = hostname;
  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de-latin1-nodeadkeys";

  # ------------------------------------------------------------
  # Nix + registry
  # ------------------------------------------------------------
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      warn-dirty = false;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  # Pin nixpkgs for legacy commands and for `nix run nixpkgs#...`
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # Allow unfree (redundant with flake import allowUnfree, but keeps modules safe)
  nixpkgs.config.allowUnfree = true;

  # ------------------------------------------------------------
  # Boot + power + storage
  # ------------------------------------------------------------
  boot = {
    loader.grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = false;
    };

    # IMPORTANT: keep this false if your efivarfs is filling up or firmware is weird
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;

    # For hibernation (kept near swap settings above)
    resumeDevice = resume.device;
    kernelParams = [ "resume_offset=${toString resume.offset}" ];
  };

  # SwapFile
  swapDevices = [ { device = swapFile; } ];

  # SSD maintenance
  services.fstrim.enable = true;
  services.fwupd.enable = true;

  # ------------------------------------------------------------
  # Networking
  # ------------------------------------------------------------
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # services.fail2ban = {
  #   enable = true;
  #   bantime = "1h";
  #   maxretry = 5;
  #   jails = {
  #     sshd = ''
  #       enabled = true
  #       mode = aggressive
  #     '';
  #   };
  # };

  # services.ssh-agent.enable = false;
  services.openssh = {
    enable = lib.mkDefault false;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };
  services.trezord.enable = true;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    RuntimeMaxUse=200M
    MaxRetentionSec=30day
  '';

  # ------------------------------------------------------------
  # Desktop + session
  # ------------------------------------------------------------
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  services.xserver = {
    enable = true;
    xkb.layout = "at";

    displayManager.lightdm.enable = true;
    displayManager.lightdm.greeters.gtk.enable = true;
    displayManager.lightdm.greeters.gtk.indicators = [ 
      "~session" "~power" "~language" "~layout" "~a11y" "~clock" "~host"
    ];

    desktopManager = {
      xfce.enable = true;
      xterm.enable = false;
    };

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3;
    };
  };

  services.displayManager.defaultSession = "xfce+i3";

  programs.dconf.enable = true;
  security.polkit.enable = true;
  
  programs.i3lock.enable = true;
  security.pam.services.i3lock.enable = true; 

  # ------------------------------------------------------------
  # Audio
  # ------------------------------------------------------------
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = false;
  };

  # ------------------------------------------------------------
  # Shell + users + sudo + containers + gnupg
  # ------------------------------------------------------------
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  # Keep vendor completions/functions, but disable vendor config snippets
  programs.fish.vendor = {
    completions.enable = true;
    functions.enable = true;
    config.enable = false; # fzf.fish provides bindings; avoids vendor fzf_key_bindings noise
  };
  
  programs.gnupg.agent = {
    enable = true;
    
    #pintentryPackage = pkgs.pinentry-gtk2;
    pinentryPackage = pkgs.pinentry-curses;  
    # terminal pinentry
    enableSSHSupport = true;
  };
    
  # User
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = userGroups;
    shell = pkgs.fish;
  };

  # Docker (optional)
  virtualisation.docker.enable = true;

  # Sudo
  security.sudo.wheelNeedsPassword = true;

  # ------------------------------------------------------------
  # Filesystems + snapshots
  # ------------------------------------------------------------
  # Services you had around Snapper/Btrfs (keep as-is)
  services.snapper.configs = {
    root = snapperTimeline // { SUBVOLUME = "/"; };
    home = snapperTimeline // {
      SUBVOLUME = "/home";
      NUMBER_LIMIT = "50";
    };
  };
  #services.snapper.cleanupOnBoot = true;

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = btrfsFileSystems;
    interval = "monthly";
    #randomizedDelaySec = "8h";
  };

  # ------------------------------------------------------------
  # Packages
  # ------------------------------------------------------------
  # Starter packages (system-wide basics + btrfs/snapper tools)
  environment.systemPackages = systemPackages;

  # ------------------------------------------------------------
  # Fonts
  # ------------------------------------------------------------
  # Fonts / Fontconfig (so `fc-match monospace` prefers JetBrainsMono Nerd Font)
  fonts.fontconfig.useEmbeddedBitmaps = true;

  # fonts.packages = with pkgs; [
  #   nerd-fonts.symbols-only 
  #   font-awesome
  # ];
  # fonts = {
  #   packages = with pkgs; [
  #     nerd-fonts.jetbrains-mono
  #     nerd-fonts.symbols-only
  #     font-awesome
  #     noto-fonts
  #     noto-fonts-color-emoji
  #   ];
  #
  #   fontconfig = {
  #     enable = true;
  #     defaultFonts = {
  #       # Keep JetBrainsMono for text, and add a Symbols Nerd Font fallback for icon glyphs.
  #       monospace = lib.mkForce [
  #         fontMain
  #         fontMono
  #         "Symbols Nerd Font Mono"
  #       ];
  #       sansSerif = lib.mkForce [ fontMain ];
  #       serif     = lib.mkForce [ fontMain ];
  #       emoji     = lib.mkForce [ fontEmoji ];
  #     };
  #   };
  # };

  system.stateVersion = "25.11";
}
