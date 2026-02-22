# Feature: Laptop Hardware Support
# Provides: Laptop-specific hardware configuration (power, bluetooth, etc)
# Dependencies: None (but optimized for Framework 13 AMD)
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.features.hardware.laptop;
  mkBoolOpt =
    default: desc:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      description = desc;
    };
  isFramework13Amd = cfg.framework.enable && cfg.framework.model == "framework-13-amd";
in
{
  options.features.hardware.laptop = {
    enable = lib.mkEnableOption "laptop hardware support and optimizations";

    powerManagement = {
      enablePowerProfilesDaemon = mkBoolOpt true "Enable power-profiles-daemon for power management";

      enableGeneralPowerManagement = mkBoolOpt true "Enable general power management features";
    };

    bluetooth = {
      enable = mkBoolOpt true "Enable Bluetooth support";

      powerOnBoot = mkBoolOpt false "Power on Bluetooth adapter on boot";

      enableBlueman = mkBoolOpt true "Enable Blueman GUI (requires desktop environment)";
    };

    fingerprint = {
      enable = mkBoolOpt true "Enable fingerprint reader support (fprintd)";
    };

    thunderbolt = {
      enable = mkBoolOpt true "Enable Thunderbolt/USB-C dock support";
    };

    firmwareUpdates = {
      enable = mkBoolOpt true "Enable firmware updates via fwupd";
    };

    cpu = {
      vendor = lib.mkOption {
        type = lib.types.enum [
          "amd"
          "intel"
        ];
        default = "amd";
        description = "CPU vendor for microcode updates";
      };

      enableMicrocodeUpdates = mkBoolOpt true "Enable CPU microcode updates";
    };

    sensors = {
      disableIIO = mkBoolOpt true "Disable IIO sensors (light, accelerometer) to save battery";
    };

    wireless = {
      enableRegulatoryDatabase = mkBoolOpt true "Enable wireless regulatory database for WiFi compliance";
    };

    zram = {
      enable = mkBoolOpt true "Enable zram compressed swap in RAM";

      algorithm = lib.mkOption {
        type = lib.types.str;
        default = "zstd";
        description = "Compression algorithm for zram";
      };

      memoryPercent = lib.mkOption {
        type = lib.types.int;
        default = 25;
        description = "Percentage of RAM to use for zram swap";
      };
    };

    framework = {
      enable = mkBoolOpt false "Enable Framework laptop-specific tools and optimizations";

      model = lib.mkOption {
        type = lib.types.enum [
          "framework-13-amd"
          "framework-13-intel"
          "framework-16-amd"
        ];
        default = "framework-13-amd";
        description = "Framework laptop model";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Power management
    powerManagement.enable = cfg.powerManagement.enableGeneralPowerManagement;

    # Services configuration
    services = {
      power-profiles-daemon.enable = cfg.powerManagement.enablePowerProfilesDaemon;
      fprintd.enable = cfg.fingerprint.enable;
      blueman.enable = cfg.bluetooth.enableBlueman;
      hardware.bolt.enable = cfg.thunderbolt.enable;
      fwupd.enable = cfg.firmwareUpdates.enable;
    };

    # Hardware configuration
    hardware = {
      bluetooth = {
        enable = lib.mkDefault cfg.bluetooth.enable;
        powerOnBoot = lib.mkDefault cfg.bluetooth.powerOnBoot;
      };

      # CPU microcode
      cpu.amd.updateMicrocode = lib.mkIf (cfg.cpu.vendor == "amd" && cfg.cpu.enableMicrocodeUpdates) (
        lib.mkDefault true
      );
      cpu.intel.updateMicrocode = lib.mkIf (cfg.cpu.vendor == "intel" && cfg.cpu.enableMicrocodeUpdates) (
        lib.mkDefault true
      );

      # Sensors
      sensor.iio.enable = !cfg.sensors.disableIIO;

      # Wireless regulatory database
      wirelessRegulatoryDatabase = cfg.wireless.enableRegulatoryDatabase;
    };

    # zram compressed swap
    zramSwap = lib.mkIf cfg.zram.enable {
      enable = true;
      priority = 100; # Higher priority - use zram first before disk swap
      inherit (cfg.zram) algorithm memoryPercent;
    };

    # Framework-specific configuration
    environment.systemPackages = lib.mkIf cfg.framework.enable [
      pkgs.framework-tool
      pkgs.fw-ectool
    ];

    # Framework 13 AMD specific optimizations
    services.udev.extraRules = lib.mkIf isFramework13Amd ''
      # Framework USB-C - prevent suspend issues
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="32ac", ATTR{power/autosuspend}="-1"
    '';

    boot.kernelParams = lib.mkIf isFramework13Amd [
      # MediaTek WiFi suspend/resume fix
      "rtw89_pci.disable_aspm_l1=1"
      "rtw89_pci.disable_aspm_l1ss=1"
      # Sleep/suspend optimization for AMD
      "mem_sleep_default=s2idle"
      # AMD GPU stability fix
      "amdgpu.dcdebugmask=0x10"
      # Dock suspend compatibility
      "pcie_aspm=off"
    ];
  };
}
