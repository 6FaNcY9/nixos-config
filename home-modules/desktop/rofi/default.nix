# Rofi configuration (Frost-Phoenix structure, palette-driven colors)
{
  config,
  lib,
  palette,
  c,
  cfgLib,
  stylixFonts ? {monospace.name = "Monospace";},
  ...
}: let
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
      "surface" = "#2e2e2e"; # card bg between bg and bgAlt
      "green" = c.base0C; # connected indicator
    };
  };

  themeText = replace (builtins.readFile ./theme.rasi);
  configText = replace (builtins.readFile ./config.rasi);
  powermenuText = replace (builtins.readFile ./powermenu-theme.rasi);
  networkText = replace (builtins.readFile ./network-theme.rasi);
  clipboardText = replace (builtins.readFile ./clipboard-theme.rasi);
in {
  imports = [./scripts.nix];
  config = lib.mkIf config.profiles.desktop {
    # Disable Stylix theming for rofi; we manage it via palette-driven Rasi files.
    stylix.targets.rofi.enable = lib.mkDefault false;

    xdg = {
      configFile = {
        "rofi/theme.rasi".text = themeText;
        "rofi/config.rasi".text = configText;
        "rofi/powermenu-theme.rasi".text = powermenuText;
        "rofi/network-theme.rasi".text = networkText;
        "rofi/clipboard-theme.rasi".text = clipboardText;
      };
    };
  };
}
