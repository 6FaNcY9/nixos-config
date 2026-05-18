# Desktop feature module - Aggregates all desktop-related configuration
# Imports: services, screen lock, qutebrowser, Firefox, i3, polybar, rofi, vibe, FileZilla, notepad

{
  imports = [
    ./services.nix
    ./lock
    ./qutebrowser.nix
    ./firefox.nix
    ./i3
    ./polybar
    ./rofi
    ./vibe
    ./filezilla.nix
    ./notepad.nix
  ];
}
