{ lib, ... }:

{
  # NixOS-only Stylix knobs:
  # - GRUB theme target
  # - HM integration (auto-import + follow system theme)
  stylix = {
    targets.grub.enable = lib.mkDefault true;

    homeManagerIntegration = {
      autoImport = lib.mkForce false;
      followSystem = lib.mkDefault true;
    };
  };
}

