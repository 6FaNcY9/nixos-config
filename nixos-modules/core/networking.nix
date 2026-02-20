# Core: Basic networking and locale
# Always enabled (no option)
_: {
  # Networking
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Locale and timezone
  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "de-latin1-nodeadkeys";
}
