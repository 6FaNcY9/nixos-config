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
in
{
  options.features.hardware.laptop = {
    enable = lib.mkEnableOption "laptop hardware support and optimizations";

    powerManagement = {
      enablePowerProfilesDaemon = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable power-profiles-daemon for power management";
      };

      enableGeneralPowerManagement = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable general power management features";
      };
    };

    bluetooth = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Bluetooth support";
      };

      powerOnBoot = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Power on Bluetooth adapter on boot";
      };

      enableBlueman = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Blueman GUI (requires desktop environment)";
      };
    };

    fingerprint = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable fingerprint reader support (fprintd)";
      };
    };

    thunderbolt = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Thunderbolt/USB-C dock support";
      };
    };

    firmwareUpdates = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable firmware updates via fwupd";
      };
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

      enableMicrocodeUpdates = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable CPU microcode updates";
      };
    };

    sensors = {
      disableIIO = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Disable IIO sensors (light, accelerometer) to save battery";
      };
    };

    wireless = {
      enableRegulatoryDatabase = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable wireless regulatory database for WiFi compliance";
      };
    };

    zram = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable zram compressed swap in RAM";
      };

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
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Framework laptop-specific tools and optimizations";
      };

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
      inherit (cfg.zram) algorithm memoryPercent;
    };

    # Framework-specific configuration
    environment.systemPackages = lib.mkIf cfg.framework.enable (
      let
        p = pkgs;
      in
      [
        p.framework-tool
        p.fw-ectool
      ]
    );

    # Framework 13 AMD specific optimizations
    services.udev.extraRules =
      lib.mkIf (cfg.framework.enable && cfg.framework.model == "framework-13-amd")
        ''
          # Framework USB-C - prevent suspend issues
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="32ac", ATTR{power/autosuspend}="-1"
        '';

    boot.kernelParams = lib.mkIf (cfg.framework.enable && cfg.framework.model == "framework-13-amd") [
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
