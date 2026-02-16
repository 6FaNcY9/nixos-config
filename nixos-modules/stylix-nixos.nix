{ lib, ... }:
{
  # NixOS-only Stylix knobs:
  # - GRUB theme target
  # - HM integration (follow system theme; HM module is imported explicitly)
  stylix = {
    targets.grub.enable = lib.mkDefault true;

    targets.lightdm.enable = true;

    homeManagerIntegration = {
      autoImport = lib.mkDefault false;
      followSystem = lib.mkDefault true;
    };
  };
}
