# Laptop role - bluetooth, power management
{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.roles.laptop {
    services.power-profiles-daemon.enable = lib.mkDefault true;

    hardware.bluetooth = {
      enable = lib.mkDefault true;
      powerOnBoot = lib.mkDefault false;
    };

    # GUI manager for Bluetooth (only meaningful on desktop role)
    services.blueman.enable = lib.mkDefault config.roles.desktop;
  };
}
