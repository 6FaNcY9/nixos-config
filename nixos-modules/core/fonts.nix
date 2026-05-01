# Core: Font configuration
# Always enabled (no option)
{
  config,
  lib,
  pkgs,
  ...
}:
{
  fonts = {
    fontconfig.useEmbeddedBitmaps = true;
    packages =
      let
        p = pkgs;
      in
      lib.optionals config.features.desktop.i3-xfce.enable [
        p.nerd-fonts.symbols-only # Symbols Nerd Font Mono — monospaced icons for polybar
        p.iosevka-bin # Plain Iosevka Term for polybar text
      ];
  };
}
