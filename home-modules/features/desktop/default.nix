# Desktop feature module - Aggregates all desktop-related configuration
# Imports: services, clipboard, screen lock, Firefox, XFCE session, i3, polybar, rofi

{
  imports = [
    ./services.nix
    ./clipboard.nix
    ./lock
    ./firefox.nix
    ./xfce-session.nix
    ./i3
    ./polybar
    ./rofi
  ];
}
