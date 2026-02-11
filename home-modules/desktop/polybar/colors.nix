{
  palette,
  c,
  ...
}: {
  services.polybar.settings."colors" = {
    # Base (from shared palette)
    background = palette.bg;
    background-alt = palette.bgAlt;
    foreground = palette.text;
    dark = palette.bg; # Match global background
    black = "#000000";
    transparent = "#00000000";

    # Semantic (from shared palette)
    inherit (palette) accent accent2 warn danger muted;
    cream = c.base07;

    # Gruvbox two-tone module pairs (icon-bg / label-bg)
    #
    # Each polybar module uses a "two-tone" design: a darker icon block and
    # a brighter label block.  The dark variant maps to a base16 slot where
    # possible; the bright "-alt" variant uses a hardcoded Gruvbox hex because
    # the base16 palette has no "bright" counterpart for most hues.
    #
    # If switching themes, update the -alt hex values to match the new palette's
    # bright variants, or derive them programmatically (e.g. lighten by 15%).
    green = c.base0B;
    green-alt = "#b8bb26";
    yellow = palette.warn;
    yellow-alt = "#fabd2f";
    orange = c.base0F;
    orange-alt = c.base09;
    blue = c.base0D;
    blue-alt = "#83a598";
    aqua = c.base0C;
    aqua-alt = "#8ec07c";
    purple = c.base0E;
    purple-alt = c.base0E; # same as dark — no bright variant needed
    red = palette.danger;
    red-alt = "#fb4934";
  };
}
