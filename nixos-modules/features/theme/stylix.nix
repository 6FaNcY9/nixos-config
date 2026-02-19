# Feature: Stylix Theme Integration
# Provides: System-wide theme management via stylix
# Dependencies: stylix nixosModule (imported in nixos-modules/default.nix)
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.theme.stylix;
in
{
  options.features.theme.stylix = {
    enable = lib.mkEnableOption "stylix system-wide theme management";

    targets = {
      grub = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Apply stylix theme to GRUB bootloader";
        };
      };

      lightdm = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Apply stylix theme to LightDM display manager";
        };
      };
    };

    homeManagerIntegration = {
      autoImport = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Automatically import stylix into home-manager";
      };

      followSystem = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Make home-manager follow system theme settings";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Stylix NixOS-specific configuration
    stylix = {
      # Bootloader theming
      targets.grub.enable = lib.mkDefault cfg.targets.grub.enable;

      # Display manager theming
      targets.lightdm.enable = cfg.targets.lightdm.enable;

      # Home Manager integration
      homeManagerIntegration = {
        autoImport = lib.mkDefault cfg.homeManagerIntegration.autoImport;
        followSystem = lib.mkDefault cfg.homeManagerIntegration.followSystem;
      };
    };
  };
}
