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
    # Standard Gruvbox dark/bright pairs for the colored block design
    green = "#98971a";
    green-alt = "#b8bb26";
    yellow = "#d79921";
    yellow-alt = "#fabd2f";
    orange = c.base0F;
    orange-alt = c.base09;
    blue = "#458588";
    blue-alt = "#83a598";
    aqua = "#689d6a";
    aqua-alt = "#8ec07c";
    purple = "#b16286";
    purple-alt = c.base0E;
    red = palette.danger;
    red-alt = "#fb4934";
  };
}
