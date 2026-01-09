{
  pkgs,
  username ? "vino",
  ...
}: let
  swapFile = "/swap/swapfile";
  btrfsFileSystems = ["/" "/home"];

  # Keep these in sync with the actual swap device/offset so hibernate works.
  resume = {
    device = "/dev/disk/by-uuid/0629aaee-1698-49d1-b3e1-e7bb6b957cda";
    offset = 1959063;
  };

  snapperUsers = [username];
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
in {
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

    # This config can stay true i think it didnt was the case for boot/efi storage overflow
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxPackages_latest;

    # For hibernation (kept near swap settings above)
    resumeDevice = resume.device;
    kernelParams = ["resume_offset=${toString resume.offset}"];
  };

  # SwapFile
  swapDevices = [{device = swapFile;}];

  services = {
    # SSD maintenance
    fstrim.enable = true;
    fwupd.enable = true;

    # Filesystems + snapshots
    snapper.configs = {
      root = snapperTimeline // {SUBVOLUME = "/";};
      home =
        snapperTimeline
        // {
          SUBVOLUME = "/home";
          NUMBER_LIMIT = "50";
        };
    };
    #snapper.cleanupOnBoot = true;

    btrfs.autoScrub = {
      enable = true;
      fileSystems = btrfsFileSystems;
      interval = "monthly";
      #randomizedDelaySec = "8h";
    };
  };
}
