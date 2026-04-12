{
  palette,
  ...
}:
{
  services.polybar.settings."colors" = {
    # Base (from shared palette)
    background = palette.bg;
    background-alt = palette.bgAlt;
    foreground = palette.text;
    dark = palette.bg;
    black = "#000000";
    transparent = "#00000000";

    # Semantic (from shared palette)
    inherit (palette)
      accent
      accent2
      warn
      danger
      muted
      cream
      ;

    # Gruvbox two-tone module pairs (icon-bg / label-bg).
    # Dark variants are hardcoded 30–47% darkened shades of Gruvbox Dark Pale base16 slots.
    # If the theme changes, update these to match the new palette.
    # Convention: <color> = dark icon bg, <color>-alt = bright label bg.
    green = "#7b7b00"; # base0B (#afaf00) darkened 30%
    green-alt = palette.accent;
    yellow = "#b37b00"; # base0A (#ffaf00) darkened 30%
    yellow-alt = palette.warn;
    orange = "#874800"; # base09 (#ff8700) darkened 47%
    orange-alt = palette.orange;
    blue = "#5c7979"; # base0D (#83adad) darkened 30%
    blue-alt = palette.accent2;
    aqua = "#5d795d"; # base0C (#85ad85) darkened 30%
    aqua-alt = palette.aqua;
    purple = "#945d79"; # base0E (#d485ad) darkened 30%
    purple-alt = palette.purple;
    red = "#974343"; # base08 (#d75f5f) darkened 30%
    red-alt = palette.danger;
  };
}
