# Core: Font configuration
# Core fontconfig settings are always enabled; desktop font packages are gated on i3.
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
      lib.optionals config.features.desktop.i3.enable [
        p.nerd-fonts.symbols-only # Symbols Nerd Font Mono — monospaced icons for polybar
        p.iosevka-bin # Plain Iosevka Term for polybar text
      ];
  };
}
