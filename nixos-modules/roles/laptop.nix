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
    # Reduced to 25% to free more physical RAM for applications
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 25;
    };

    # Framework-specific: Fix MediaTek WiFi suspend/resume issues
    boot.kernelParams = [
      "rtw89_pci.disable_aspm_l1=1"
      "rtw89_pci.disable_aspm_l1ss=1"
    ];

    # Power management optimized for Framework 13 AMD (Ryzen 7040)
    # Note: Ryzen 7040 uses amd-pstate-epp driver managed by power-profiles-daemon
    # cpuFreqGovernor setting is incompatible with power-profiles-daemon
    powerManagement.enable = true;

    # Disable USB autosuspend for Framework USB-C controllers
    services.udev.extraRules = ''
      # Framework USB-C - prevent suspend issues
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="32ac", ATTR{power/autosuspend}="-1"
    '';
  };
}
