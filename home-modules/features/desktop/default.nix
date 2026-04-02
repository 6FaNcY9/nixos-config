# Desktop feature module - Aggregates all desktop-related configuration
# Imports: services, clipboard, screen lock, qutebrowser, Firefox, XFCE session, i3, polybar, rofi, FileZilla, Bitwarden

{
  imports = [
    ./services.nix
    ./clipboard.nix
    ./lock
    ./qutebrowser.nix
    ./firefox.nix
    ./xfce-session.nix
    ./i3
    ./polybar
    ./rofi
    ./vibe
    ./filezilla.nix
    ./bitwarden.nix
  ];
}
