# Rofi configuration — palette-driven, all rasi content generated inline via Nix strings.
{
  config,
  lib,
  palette,
  c,
  stylixFonts ? {
    monospace.name = "Monospace";
  },
  ...
}:
let
  cfg = config.features.desktop.rofi;
  font = stylixFonts.monospace.name;

  # surface: slightly darker than bgAlt, used as card background.
  # Hardcoded for Gruvbox Dark Pale (#3a3a3a darkened 15%).
  surface = "#313131";

  # Gruvbox colors not in the palette — kept as named constants for clarity.
  yellowAlt = "#fabd2f"; # Gruvbox bright yellow — prompt background & highlights
  redAlt = "#fb4934"; # Gruvbox bright red — danger/warning accent
  elementBg = "#1b1b1b"; # Darker card background for alternating list rows

  themeRasi = import ./theme.rasi.nix {
    inherit
      palette
      c
      yellowAlt
      redAlt
      elementBg
      surface
      ;
  };

  configRasi = import ./config.rasi.nix { inherit font; };

  powermenuThemeRasi = import ./powermenu-theme.rasi.nix { inherit font; };

  audioSwitcherThemeRasi = import ./audio-switcher-theme.rasi.nix {
    inherit font palette;
  };

  dropdownThemeRasi = import ./dropdown-theme.rasi.nix {
    inherit font palette;
  };
in
{
  imports = [ ./scripts.nix ];

  options.features.desktop.rofi = {
    enable = lib.mkEnableOption "Rofi application launcher with custom themes";
  };

  config = lib.mkIf cfg.enable {
    # Disable Stylix theming for rofi; we manage it via palette-driven rasi strings.
    stylix.targets.rofi.enable = lib.mkDefault false;

    xdg.configFile = {
      "rofi/theme.rasi".text = themeRasi;
      "rofi/config.rasi".text = configRasi;
      "rofi/powermenu-theme.rasi".text = powermenuThemeRasi;
      "rofi/audio-switcher-theme.rasi".text = audioSwitcherThemeRasi;
      "rofi/dropdown-theme.rasi".text = dropdownThemeRasi;
    };
  };
}
