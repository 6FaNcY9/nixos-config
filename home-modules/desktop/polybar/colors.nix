{
  cfgLib,
  palette,
  c,
  ...
}: let
  darken = cfgLib.darkenColor;
in {
  services.polybar.settings."colors" = {
    # Base (from shared palette)
    background = palette.bg;
    background-alt = palette.bgAlt;
    foreground = palette.text;
    dark = palette.bg;
    black = "#000000";
    transparent = "#00000000";

    # Semantic (from shared palette)
    inherit (palette) accent accent2 warn danger muted;
    cream = c.base07;

    # Gruvbox two-tone module pairs (icon-bg / label-bg)
    #
    # Each polybar module uses a "two-tone" design: a darker icon block and
    # a brighter label block.  The dark variant is derived via darkenColor
    # from the base16 slot; the "-alt" variant is the base16 color itself.
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
