{lib, ...}: {
  options = {
    roles = {
      desktop = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the desktop/GUI role for this host.";
      };

      laptop = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable laptop-specific behavior for this host.";
      };

      server = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable server-oriented defaults for this host.";
      };
    };

    desktop.variant = lib.mkOption {
      type = lib.types.enum ["i3-xfce"];
      default = "i3-xfce";
      description = "Desktop stack variant to use when roles.desktop = true.";
    };
  };
}
