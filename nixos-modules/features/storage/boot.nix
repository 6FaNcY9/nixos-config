# Feature: Boot Configuration
# Provides: GRUB bootloader with EFI support
# Dependencies: None
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.features.storage.boot;
in
{
  options.features.storage.boot = {
    enable = lib.mkEnableOption "GRUB bootloader configuration";

    bootloader = lib.mkOption {
      type = lib.types.enum [
        "grub"
        "systemd-boot"
      ];
      default = "grub";
      description = "Bootloader to use";
    };

    efiSupport = lib.mkEnableOption "EFI support" // {
      default = true;
    };

    useOSProber = lib.mkEnableOption "OS prober for dual-boot detection";

    canTouchEfiVariables = lib.mkEnableOption "EFI variable modification by bootloader" // {
      default = true;
    };

    kernelPackage = lib.mkOption {
      type = lib.types.enum [
        "stable"
        "latest"
      ];
      default = "latest";
      description = "Linux kernel package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    boot = {
      # Bootloader configuration
      loader = {
        # GRUB configuration
        grub = lib.mkIf (cfg.bootloader == "grub") {
          enable = true;
          inherit (cfg) efiSupport useOSProber;
          device = if cfg.efiSupport then "nodev" else "/dev/sda"; # EFI uses nodev
        };

        # systemd-boot configuration
        systemd-boot.enable = cfg.bootloader == "systemd-boot";

        # EFI variables
        efi.canTouchEfiVariables = cfg.canTouchEfiVariables;
      };

      # Kernel selection - latest provides newest features, stable provides better tested releases
      kernelPackages =
        if cfg.kernelPackage == "latest" then pkgs.linuxPackages_latest else pkgs.linuxPackages;
    };
  };
}
