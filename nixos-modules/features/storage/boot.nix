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

    efiSupport = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable EFI support";
    };

    useOSProber = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable OS prober for dual-boot detection";
    };

    canTouchEfiVariables = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Allow bootloader to modify EFI variables";
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
          device = if cfg.efiSupport then "nodev" else "/dev/sda";
        };

        # systemd-boot configuration
        systemd-boot.enable = lib.mkIf (cfg.bootloader == "systemd-boot") true;

        # EFI variables
        efi.canTouchEfiVariables = cfg.canTouchEfiVariables;
      };

      # Kernel selection
      kernelPackages =
        if cfg.kernelPackage == "latest" then pkgs.linuxPackages_latest else pkgs.linuxPackages;
    };
  };
}
