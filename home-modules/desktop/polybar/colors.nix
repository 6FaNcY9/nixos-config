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
    # a brighter label block.  The dark variant is ~30% darker than the base16
    # slot to create a visible shadow effect; the bright "-alt" variant uses a
    # hardcoded Gruvbox hex for the label background.
    #
    # If switching themes, update both the dark and -alt hex values to match
    # the new palette (e.g. darken base by 30%, brighten alt by 15%).
    green = "#7a7a00";
    green-alt = "#b8bb26";
    yellow = "#b37a00";
    yellow-alt = "#fabd2f";
    orange = "#96410a";
    orange-alt = c.base09;
    blue = "#5c7979";
    blue-alt = "#83a598";
    aqua = "#5d795d";
    aqua-alt = "#8ec07c";
    purple = "#945d79";
    purple-alt = c.base0E;
    red = "#964242";
    red-alt = "#fb4934";
  };
}
