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

  # Shared color variable block — imported by all other rasi files via @theme "theme".
  themeRasi = ''
    * {
        bg-col:              ${palette.bg};
        bg-col-light:        ${palette.bgAlt};
        border-col:          ${palette.muted};
        selected-col:        ${c.base0F};
        orange:              ${c.base0F};
        orange-alt:          ${palette.orange};
        yellow:              ${palette.warn};
        yellow-alt:          ${yellowAlt};
        fg-col:              ${palette.text};
        fg-col2:             ${c.base06};
        grey:                ${palette.muted};
        cream:               ${palette.cream};
        red-alt:             ${redAlt};
        element-bg:          ${elementBg};
        element-alternate-bg:${palette.bg};
        highlight:           underline bold ${yellowAlt};

        accent-green:        ${palette.accent};
        accent-blue:         ${palette.accent2};
        purple:              ${palette.purple};
        surface:             ${surface};
        green:               ${palette.aqua};
    }
  '';

  configRasi = ''
    configuration {
        modi:                "drun,run,window";
        lines:               8;
        cycle:               false;
        font:                "${font} 11";
        show-icons:          true;
        icon-theme:          "Papirus-Dark";
        terminal:            "alacritty";
        drun-display-format: "{icon} {name}";
        location:            0;
        disable-history:     false;
        hide-scrollbar:      true;
        display-drun:        " Apps";
        display-run:         " Run";
        display-window:      " Window";
        sidebar-mode:        true;
        sorting-method:      "fzf";
        scroll-method:       1;
    }

    @theme "theme"

    element-text, element-icon, mode-switcher {
        background-color: inherit;
        text-color:       inherit;
    }

    window {
        width:            550px;
        location:         center;
        anchor:           center;
        padding:          0px;
        border:           2px 0px 0px 0px;
        border-radius:    6px;
        border-color:     @selected-col;
        background-color: @bg-col;
        spacing:          0;
    }

    mainbox {
        spacing:          0;
        background-color: @bg-col;
        children:         [ inputbar, listview, mode-switcher ];
    }

    inputbar {
        children:         [prompt,entry];
        background-color: @bg-col;
        padding:          4px;
        margin:           8px 8px 0px 8px;
        border:           0px;
        border-radius:    4px;
    }

    prompt {
        background-color: @yellow-alt;
        padding:          8px 14px;
        border-radius:    4px;
        text-color:       @bg-col;
        font:             "${font} Bold 11";
    }

    entry {
        padding:          8px 14px;
        text-color:       @cream;
        background-color: transparent;
        placeholder:      "Search...";
        placeholder-color:@grey;
    }

    listview {
        padding:          6px;
        margin:           4px 0px 0px 0px;
        background-color: @bg-col;
        dynamic:          false;
        lines:            8;
        columns:          1;
        cycle:            true;
        scrollbar:        false;
        fixed-height:     true;
    }

    element {
        padding:          10px 14px;
        vertical-align:   0.5;
        border:           0px;
        border-radius:    4px;
        background-color: @surface;
        text-color:       @cream;
        margin:           2px 4px;
    }

    element-icon {
        size:             28px;
        margin:           0px 12px 0px 0px;
        background-color: inherit;
    }

    element selected.normal {
        background-color: @selected-col;
        text-color:       @cream;
    }

    element normal.active {
        text-color:       @accent-green;
    }

    element alternate.normal {
        background-color: @element-bg;
    }

    element alternate.active {
        text-color:       @accent-green;
    }

    element selected.active {
        background-color: @accent-green;
        text-color:       @bg-col;
    }

    mode-switcher {
        spacing:          6px;
        padding:          6px 8px 8px 8px;
        background-color: @bg-col;
        border:           0px;
    }

    button {
        padding:          8px;
        background-color: @surface;
        text-color:       @grey;
        vertical-align:   0.5;
        horizontal-align: 0.5;
        border-radius:    4px;
    }

    button selected {
        background-color: @accent-blue;
        text-color:       @cream;
    }
  '';

  powermenuThemeRasi = ''
    @theme "theme"

    configuration {
        show-icons: false;
        font:       "${font} Bold 32";
    }

    window {
        width:            720px;
        location:         center;
        anchor:           center;
        margin:           0px;
        padding:          0px;
        border:           2px 0px 0px 0px;
        border-radius:    6px;
        border-color:     @selected-col;
        background-color: @bg-col;
        transparency:     "real";
    }

    mainbox {
        enabled:          true;
        padding:          20px;
        spacing:          12px;
        background-color: inherit;
        children:         [ "listview" ];
    }

    message {
        enabled:          true;
        background-color: transparent;
    }

    textbox {
        text-color:       @grey;
        background-color: transparent;
        font:             "${font} 14";
        horizontal-align: 0.5;
        str:              "Power";
    }

    listview {
        enabled:          true;
        lines:            1;
        columns:          6;
        cycle:            true;
        dynamic:          true;
        scrollbar:        false;
        layout:           vertical;
        reverse:          false;
        fixed-height:     true;
        fixed-columns:    true;
        spacing:          10px;
        border:           0px;
        text-color:       @cream;
        background-color: transparent;
    }

    element {
        enabled:          true;
        spacing:          0px;
        padding:          35px 10px;
        border:           0px;
        border-radius:    4px;
        background-color: @surface;
        text-color:       @cream;
        cursor:           pointer;
    }

    element-text {
        vertical-align:   0.5;
        horizontal-align: 0.5;
        font:             inherit;
        text-color:       inherit;
        background-color: transparent;
        cursor:           inherit;
    }

    element selected.normal {
        background-color: @yellow-alt;
        text-color:       @bg-col;
    }
  '';

  audioSwitcherThemeRasi = ''
    @theme "theme"

    configuration {
      show-icons: false;
      font:       "${font} 11";
    }

    window {
      width:            440px;
      location:         center;
      anchor:           center;
      border:           2px 0 0 0;
      border-radius:    6px;
      border-color:     ${palette.purple};
      background-color: @bg-col;
      transparency:     "real";
    }

    mainbox {
      spacing:          0;
      background-color: @bg-col;
      children:         [inputbar, listview];
    }

    inputbar {
      children:         [prompt,entry];
      padding:          4px;
      margin:           8px 8px 0 8px;
      background-color: @bg-col;
      border-radius:    4px;
    }

    prompt {
      background-color: ${palette.purple};
      padding:          8px 14px;
      border-radius:    4px;
      text-color:       @bg-col;
      font:             "${font} Bold 11";
    }

    entry {
      padding:          8px 14px;
      background-color: @bg-col;
      text-color:       @cream;
      placeholder:      "Filter...";
      placeholder-color:@grey;
    }

    listview {
      padding:          6px;
      margin:           4px 0 0 0;
      background-color: @bg-col;
      dynamic:          true;
      lines:            6;
      columns:          1;
      cycle:            false;
      fixed-height:     false;
    }

    element {
      padding:          10px 14px;
      border-radius:    4px;
      background-color: @surface;
      text-color:       @cream;
      margin:           2px 4px;
    }

    element-text {
      background-color: inherit;
      text-color:       inherit;
    }

    element selected.normal {
      background-color: ${palette.purple};
      text-color:       @bg-col;
    }

    element alternate.normal {
      background-color: @element-bg;
      text-color:       @cream;
    }
  '';

  dropdownThemeRasi = ''
    @theme "theme"

    configuration {
      show-icons:   false;
      font:         "${font} 11";
      hover-select: true;
    }

    window {
      width:            340px;
      location:         northwest;
      anchor:           northwest;
      x-offset:         0px;
      y-offset:         25px;
      border:           2px 0 0 0;
      border-radius:    0 0 6px 6px;
      border-color:     ${palette.orange};
      background-color: @bg-col;
      transparency:     "real";
    }

    mainbox {
      spacing:          0;
      background-color: @bg-col;
      children:         [listview];
    }

    listview {
      padding:          4px;
      background-color: @bg-col;
      dynamic:          true;
      lines:            4;
      columns:          1;
      cycle:            false;
      fixed-height:     false;
      scrollbar:        false;
    }

    element {
      padding:          10px 14px;
      border-radius:    4px;
      background-color: @surface;
      text-color:       @cream;
      margin:           2px 4px;
    }

    element-text {
      background-color: inherit;
      text-color:       inherit;
    }

    element selected.normal {
      background-color: ${palette.orange};
      text-color:       @bg-col;
    }

    element alternate.normal {
      background-color: @element-bg;
      text-color:       @cream;
    }
  '';
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
