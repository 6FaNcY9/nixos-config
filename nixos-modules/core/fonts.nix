# Core: Font configuration
# Always enabled (no option)
{ pkgs, ... }:
{
  fonts = {
    fontconfig.useEmbeddedBitmaps = true;
    packages =
      let
        p = pkgs;
      in
      [
        p.nerd-fonts.symbols-only # Symbols Nerd Font Mono — monospaced icons for polybar
        p.iosevka-bin # Plain Iosevka Term for polybar text
      ];
  };
}
