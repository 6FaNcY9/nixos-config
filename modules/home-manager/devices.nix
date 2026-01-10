{lib, ...}: {
  options.devices = {
    battery = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Battery device name for status widgets.";
    };

    backlight = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Backlight device name for status widgets.";
    };
  };
}
