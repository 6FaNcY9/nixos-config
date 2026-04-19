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
  mkBool =
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
      enablePowerProfilesDaemon = mkBool true "Enable power-profiles-daemon for power management";

      useAutoFreq = mkBool false "Use auto-cpufreq v3 instead of power-profiles-daemon (better turbo + governor control on AMD laptops)";
      enableGeneralPowerManagement = mkBool true "Enable general power management features";
      enableHibernation = mkBool false "Enable hibernation via systemd sleep configuration (requires resume device and offset to be set in boot config)";
    };

    bluetooth = {
      enable = mkBool true "Enable Bluetooth support";

      powerOnBoot = mkBool false "Power on Bluetooth adapter on boot";

      enableBlueman = mkBool true "Enable Blueman GUI (requires desktop environment)";
    };

    fingerprint = {
      enable = mkBool true "Enable fingerprint reader support (fprintd)";
    };

    thunderbolt = {
      enable = mkBool true "Enable Thunderbolt/USB-C dock support";
    };

    firmwareUpdates = {
      enable = mkBool true "Enable firmware updates via fwupd";
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

      enableMicrocodeUpdates = mkBool true "Enable CPU microcode updates";
    };

    sensors = {
      disableIIO = mkBool true "Disable IIO sensors (light, accelerometer) to save battery";
    };

    wireless = {
      enableRegulatoryDatabase = mkBool true "Enable wireless regulatory database for WiFi compliance";
    };

    zram = {
      enable = mkBool true "Enable zram compressed swap in RAM";

      algorithm = lib.mkOption {
        type = lib.types.enum [
          "lzo"
          "lzo-rle"
          "lz4"
          "zstd"
        ];
        default = "zstd";
        description = "Compression algorithm for zram (zstd recommended: best ratio + speed)";
      };

      memoryPercent = lib.mkOption {
        type = lib.types.ints.between 1 100;
        default = 25;
        description = "Percentage of RAM to allocate for zram swap (1-100)";
      };
    };

    framework = {
      enable = mkBool false "Enable Framework laptop-specific tools and optimizations";

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
    systemd.sleep.settings = lib.mkIf cfg.powerManagement.enableHibernation {
      Sleep.AllowHibernation = "yes";
    };

    # Services configuration
    services = {
      power-profiles-daemon.enable =
        cfg.powerManagement.enablePowerProfilesDaemon && !cfg.powerManagement.useAutoFreq;
      fprintd.enable = cfg.fingerprint.enable;
      blueman.enable = cfg.bluetooth.enableBlueman;
      hardware.bolt.enable = cfg.thunderbolt.enable;
      fwupd.enable = cfg.firmwareUpdates.enable;
    };

    # auto-cpufreq v3: Advanced frequency + turbo control (AMD/Intel)
    # Replaces power-profiles-daemon when useAutoFreq = true (must not coexist)
    services.auto-cpufreq = lib.mkIf cfg.powerManagement.useAutoFreq {
      enable = true;
      settings = {
        charger = {
          governor = "performance";
          turbo = "auto";
        };
        battery = {
          governor = "powersave";
          turbo = "never";
        };
      };
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

    # zram compressed swap - compresses memory in RAM for better performance than disk swap
    zramSwap = lib.mkIf cfg.zram.enable {
      enable = true;
      priority = 100; # Higher priority than disk swap - use zram first for faster access
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
      # Framework 13 AMD specific kernel parameters for optimal hardware compatibility

      # MediaTek WiFi suspend/resume fix - disables ASPM L1/L1SS power states
      # Prevents WiFi disconnections and instability after suspend on RTL8852AE chips
      "rtw89_pci.disable_aspm_l1=1"
      "rtw89_pci.disable_aspm_l1ss=1"

      # Sleep/suspend optimization for AMD - uses s2idle (modern standby)
      # Better battery life and compatibility than S3 suspend on Ryzen mobile
      "mem_sleep_default=s2idle"

      # Disable ABM (Adaptive Backlight Modulation / Vari-Bright)
      # Prevents display from appearing grayed-out/washed-out on battery.
      # Confirmed fix for Framework 13 AMD: https://community.frame.work/t/56535
      "amdgpu.abmlevel=0"

      # Enable automatic GPU reset instead of hanging on GPU faults
      # Prevents indefinite session freezes when amdgpu has ring/VM errors
      "amdgpu.gpu_recovery=1"
      # pcie_aspm=off removed: was too broad (killed ASPM for all PCIe devices, hurting battery).
      # WiFi ASPM is already fixed by rtw89_pci.disable_aspm_l1/l1ss above.
      # Dock issues: use targeted udev rules for the specific device if they recur.
    ];
  };
}
