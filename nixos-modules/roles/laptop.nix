# Laptop role - bluetooth, power management
{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.roles.laptop {
    services = {
      power-profiles-daemon.enable = lib.mkDefault true;
      # GUI manager for Bluetooth (only meaningful on desktop role)
      blueman.enable = lib.mkDefault config.roles.desktop;
    };

    hardware.bluetooth = {
      enable = lib.mkDefault true;
      powerOnBoot = lib.mkDefault false;
    };

    # Memory optimization with zram (compressed swap in RAM)
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 50;
    };

    # Framework-specific: Fix MediaTek WiFi suspend/resume issues
    boot.kernelParams = [
      "rtw89_pci.disable_aspm_l1=1"
      "rtw89_pci.disable_aspm_l1ss=1"
    ];

    # Basic power management (PPD handles profiles)
    powerManagement.enable = true;

    # Disable USB autosuspend for Framework USB-C controllers
    services.udev.extraRules = ''
      # Framework USB-C - prevent suspend issues
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="32ac", ATTR{power/autosuspend}="-1"
    '';
  };
}
