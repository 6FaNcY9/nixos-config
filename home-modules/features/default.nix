# Home Manager feature modules
# Imports: shell, editor (nixvim), terminal, desktop (i3, polybar, rofi), ai (hermes)
{
  imports = [
    ./shell
    ./editor
    ./terminal
    ./desktop
    ./ai
  ];
}
