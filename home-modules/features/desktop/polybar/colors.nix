{
  cfgLib,
  palette,
  c,
  ...
}:
let
  darken = cfgLib.darkenColor;
in
{
  services.polybar.settings."colors" = {
    # Base (from shared palette)
    background = palette.bg;
    background-alt = palette.bgAlt;
    foreground = palette.text;
    dark = palette.bg;
    black = "#000000";
    transparent = "#00000000";
    module-bg = "#2d2d2d"; # uniform segment background — all modules use this

    # Semantic (from shared palette)
    inherit (palette)
      accent
      accent2
      warn
      danger
      muted
      ;
    cream = c.base07;

    # Gruvbox accent color pairs (text/icon foreground)
    #
    # Each polybar module uses a uniform dark background (module-bg) with colored
    # foreground text and icons.  The "-alt" variant (the base16 color itself) is
    # used as the foreground accent; the plain variant (darkened) is kept for
    # potential future use or overrides.
    green = darken 0.30 c.base0B;
    green-alt = c.base0B;
    yellow = darken 0.30 c.base0A;
    yellow-alt = c.base0A;
    orange = darken 0.47 c.base09;
    orange-alt = c.base09;
    blue = darken 0.30 c.base0D;
    blue-alt = c.base0D;
    aqua = darken 0.30 c.base0C;
    aqua-alt = c.base0C;
    purple = darken 0.30 c.base0E;
    purple-alt = c.base0E;
    red = darken 0.30 c.base08;
    red-alt = c.base08;
  };
}
