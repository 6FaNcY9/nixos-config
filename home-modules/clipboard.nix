# Clipboard manager for desktop
{
  lib,
  config,
  ...
}: {
  options.clipboard = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.profiles.desktop;
      description = "Enable clipboard manager (auto-enabled with desktop profile).";
    };
  };

  config = lib.mkIf config.clipboard.enable {
    services.clipmenu = {
      enable = true;
      launcher = "rofi -dmenu";
    };
  };
}
