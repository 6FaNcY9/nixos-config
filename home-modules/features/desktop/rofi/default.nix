# Rofi configuration (Frost-Phoenix structure, palette-driven colors)
{
  config,
  lib,
  palette,
  c,
  cfgLib,
  stylixFonts ? {
    monospace.name = "Monospace";
  },
  ...
}:
let
  cfg = config.features.desktop.rofi;
  fontBase = stylixFonts.monospace.name;

  replace = cfgLib.mkColorReplacer {
    colors = {
      "bg-col" = palette.bg; # #262626
      "bg-col-light" = palette.bgAlt; # #3a3a3a
      "border-col" = palette.muted; # Gruvbox gray — subtle frame
      "selected-col" = c.base0F; # Gruvbox orange — bold selection
      "orange" = c.base0F;
      "orange-alt" = c.base09;
      "yellow" = palette.warn;
      "yellow-alt" = "#fabd2f"; # bright variant — no base16 equiv
      "fg-col" = palette.text; # Gruvbox cream
      "fg-col2" = c.base06;
      "grey" = palette.muted; # Gruvbox gray
      "cream" = c.base07;
      "red-alt" = "#fb4934"; # bright variant — no base16 equiv
      "element-bg" = "#1b1b1b"; # design choice — keep
      "element-alternate-bg" = palette.bg; # Alternating rows
      "font-base" = fontBase;
      "icon-theme" = "Papirus-Dark";
      "terminal" = "alacritty";
      # Extended palette for specialized menus
      "accent-green" = palette.accent; # clipboard accent
      "accent-blue" = palette.accent2; # network accent
      "purple" = c.base0E; # hibernate highlight
      "surface" = cfgLib.darkenColor 0.15 palette.bgAlt; # card bg between bg and bgAlt
      "green" = c.base0C; # connected indicator
    };
  };
in
{
  imports = [ ./scripts.nix ];

  options.features.desktop.rofi = {
    enable = lib.mkEnableOption "Rofi application launcher with custom themes";
  };

  config = lib.mkIf cfg.enable {
    # Disable Stylix theming for rofi; we manage it via palette-driven Rasi files.
    stylix.targets.rofi.enable = lib.mkDefault false;

    xdg.configFile = builtins.listToAttrs (
      map
        (name: {
          name = "rofi/${name}.rasi";
          value.text = replace (builtins.readFile ./${name}.rasi);
        })
        [
          "theme"
          "config"
          "powermenu-theme"
          "network-theme"
          "clipboard-theme"
          "audio-switcher-theme"
          "dropdown-theme"
        ]
    );
  };
}
