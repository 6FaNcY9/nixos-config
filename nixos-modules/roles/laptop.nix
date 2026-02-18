# Laptop role - bluetooth, power management
{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.roles.laptop {
    services = {
      # Power management: power-profiles-daemon with native AMD amd-pstate-epp driver
      # Framework 13 AMD (Ryzen 7040) uses amd-pstate-epp for optimal power management
      # nixos-hardware enables this by default, we keep it enabled
      power-profiles-daemon.enable = true;

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

    # Framework-specific tools
    environment.systemPackages = with pkgs; [
      framework-tool # Framework hardware control utility
      fw-ectool # Embedded controller interface
    ];

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
    # Uses native amd-pstate-epp driver with power-profiles-daemon
    # Available profiles: performance, balanced, power-saver
    # Switch profiles: powerprofilesctl set <profile>
    powerManagement.enable = true;
  };
}
