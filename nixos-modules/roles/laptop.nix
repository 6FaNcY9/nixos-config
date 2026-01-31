# Laptop role - bluetooth, power management
{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.roles.laptop {
    services = {
      # Power management: auto-cpufreq for battery optimization (from gkapfham)
      # Automatically switches between performance/powersave based on AC power
      auto-cpufreq = {
        enable = true;
        settings = {
          charger = {
            governor = "performance";
            turbo = "auto";
          };
          battery = {
            governor = "powersave";
            scaling_min_freq = lib.mkDefault 400000;
            scaling_max_freq = lib.mkDefault 1700000;
            turbo = "auto";
          };
        };
      };

      # Disable power-profiles-daemon when using auto-cpufreq (they conflict)
      # Use mkForce because nixos-hardware enables it by default for Framework
      power-profiles-daemon.enable = lib.mkForce false;

      # Fingerprint authentication (from gkapfham - Framework 13 AMD has fingerprint reader)
      # Note: PAM integration syntax changed in unstable - service enables fingerprint auth
      fprintd.enable = true;

      # GUI manager for Bluetooth (only meaningful on desktop role)
      blueman.enable = lib.mkDefault config.roles.desktop;

      # Enable Thunderbolt support for USB-C docks
      hardware.bolt.enable = true;

      # Enable firmware updates via fwupd (Framework releases BIOS updates)
      fwupd.enable = true;

      # Disable USB autosuspend for Framework USB-C controllers
      udev.extraRules = ''
        # Framework USB-C - prevent suspend issues
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="32ac", ATTR{power/autosuspend}="-1"
      '';
    };

    hardware = {
      bluetooth = {
        enable = lib.mkDefault true;
        powerOnBoot = lib.mkDefault false;
      };

      # AMD microcode updates (from gkapfham - critical for Framework 13 AMD)
      cpu.amd.updateMicrocode = lib.mkDefault true;

      # Disable IIO sensors (light sensors, accelerometers) - not used, saves battery
      sensor.iio.enable = false;

      # Wireless regulatory database for better WiFi compliance
      wirelessRegulatoryDatabase = true;
    };

    # Fingerprint authentication PAM integration will be configured when needed
    # (API changed in unstable, service.fprintd.enable is sufficient for basic auth)

    # Memory optimization with zram (compressed swap in RAM)
    # Reduced to 25% to free more physical RAM for applications
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 25;
    };

    # Framework 13 AMD kernel parameters
    boot.kernelParams = [
      # MediaTek WiFi suspend/resume fix (critical for stable WiFi)
      "rtw89_pci.disable_aspm_l1=1"
      "rtw89_pci.disable_aspm_l1ss=1"
      # Sleep/suspend optimization for AMD (s2idle is best for Ryzen 7040)
      "mem_sleep_default=s2idle"
      # AMD GPU stability fix (prevents display corruption)
      "amdgpu.dcdebugmask=0x10"
      # Dock suspend compatibility - critical for USB-C docks
      "pcie_aspm=off"
    ];

    # Power management for Framework 13 AMD (Ryzen 7040)
    # Note: Ryzen 7040 uses amd-pstate-epp driver managed by power-profiles-daemon
    # Do NOT set cpuFreqGovernor - it conflicts with power-profiles-daemon
    powerManagement.enable = true;
  };
}
