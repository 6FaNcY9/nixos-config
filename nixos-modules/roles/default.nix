# Role system - defines opt-in roles for different host types
# Roles: desktop, laptop, server, development
{ lib, ... }:
{
  imports = [
    ./laptop.nix
    ./server.nix
    ./development.nix
    ./desktop-hardening.nix
  ];

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
        description = "Enable laptop-specific behavior (bluetooth, power management).";
      };

      server = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable server-oriented defaults for this host.";
      };

      development = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable development tools (docker, direnv, build tools).";
      };
    };

    desktop.variant = lib.mkOption {
      type = lib.types.enum [ "i3-xfce" ]; # sway removed - not implemented
      default = "i3-xfce";
      description = "Desktop stack variant to use when roles.desktop = true.";
    };
  };
}
