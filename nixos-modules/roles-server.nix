{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.roles.server {
    # Server role defaults: prefer headless unless explicitly overridden.
    roles.desktop = lib.mkDefault false;

    services = {
      openssh.enable = lib.mkDefault true;
    };
  };
}
