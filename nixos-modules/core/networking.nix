# Core: Basic networking and locale
# Always enabled (no option)
{ lib, ... }:
{
  # Networking
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Locale and timezone
  time.timeZone = lib.mkDefault "Europe/Vienna";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  console.keyMap = lib.mkDefault "de-latin1-nodeadkeys";
}
