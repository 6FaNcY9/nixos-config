{lib, ...}: {
  # NixOS-only Stylix knobs:
  # - GRUB theme target
  # - HM integration (auto-import + follow system theme)
  stylix = {
    targets.grub.enable = lib.mkDefault true;

    targets.lightdm.enable = true;

    homeManagerIntegration = {
      autoImport = lib.mkDefault true;
      followSystem = lib.mkDefault true;
    };
  };
}
