{
  pkgs,
  username ? "vino",
  ...
}:
let
  swapFile = "/swap/swapfile";
  btrfsFileSystems = [
    "/"
    "/home"
  ];

  snapperUsers = [ username ];
  snapperTimeline = {
    FSTYPE = "btrfs";
    # TIMELINE_CREATE is ignored by NixOS snapper module; timer disabled below
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_HOURLY = "10";
    TIMELINE_LIMIT_DAILY = "7";
    TIMELINE_LIMIT_WEEKLY = "0";
    TIMELINE_LIMIT_MONTHLY = "0";
    TIMELINE_LIMIT_YEARLY = "0";
    NUMBER_CLEANUP = true;
    ALLOW_USERS = snapperUsers;
  };
in
{
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

    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # SwapFile
  swapDevices = [ { device = swapFile; } ];

  services = {
    # SSD maintenance (fwupd is enabled in roles/laptop.nix)
    fstrim.enable = true;

    # Filesystems + snapshots
    snapper.configs = {
      root = snapperTimeline // {
        SUBVOLUME = "/";
      };
      home = snapperTimeline // {
        SUBVOLUME = "/home";
        NUMBER_LIMIT = "50";
      };
    };

    btrfs.autoScrub = {
      enable = true;
      fileSystems = btrfsFileSystems;
      interval = "monthly";
    };
  };

  # Disable snapper timeline timer (hourly snapshots)
  # Daily restic backups are sufficient, this reduces I/O
  # Note: TIMELINE_CREATE attribute doesn't work in NixOS snapper module,
  # so we disable the timer directly
  systemd.timers.snapper-timeline.enable = false;
}
