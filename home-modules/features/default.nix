# Home Manager feature modules
# Imports: shell (fish, git, starship, vibe), editor (nixvim), terminal (alacritty), desktop (i3, polybar, rofi)
#
{
  imports = [
    ./shell
    ./editor
    ./terminal
    ./desktop
  ];
}
