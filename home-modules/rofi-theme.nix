# Rofi theme inspired by Frost-Phoenix, adapted to our palette
{
  config,
  lib,
  palette,
  pkgs,
  stylixFonts ? {monospace.name = "JetBrainsMono Nerd Font";},
  ...
}: {
  config = lib.mkIf config.profiles.desktop (let
    themeName = "frost-gruvbox";
    themeText = ''
      * {
        bg-col: ${palette.bg};
        bg-col-light: ${palette.bgAlt};
        border-col: ${palette.muted};
        selected-col: ${palette.bgAlt};
        green: ${palette.accent};
        fg-col: ${palette.text};
        fg-col2: ${palette.text};
        grey: ${palette.muted};
        highlight: @green;
        element-bg: ${palette.bg};
        element-alternate-bg: ${palette.bgAlt};
      }

      element-text, element-icon, mode-switcher {
        background-color: inherit;
        text-color: inherit;
      }

      window {
        height: 539px;
        width: 400px;
        border: 2px;
        border-color: @border-col;
        background-color: @bg-col;
      }

      mainbox {
        background-color: @bg-col;
      }

      inputbar {
        children: [ prompt, entry ];
        background-color: @bg-col-light;
        padding: 0px;
      }

      prompt {
        background-color: @green;
        padding: 4px;
        text-color: @bg-col-light;
        margin: 10px 0px 10px 10px;
      }

      textbox-prompt-colon {
        expand: false;
        str: ":";
      }

      entry {
        padding: 6px;
        margin: 10px 10px 10px 5px;
        text-color: @fg-col;
        background-color: @bg-col;
      }

      listview {
        border: 0px 0px 0px;
        padding: 0px;
        margin: 0px;
        columns: 1;
        background-color: @bg-col;
        cycle: true;
      }

      element {
        padding: 8px 8px 8px 8px;
        margin: 0px;
        background-color: @element-bg;
        text-color: @fg-col;
      }

      element-icon {
        size: 28px;
      }

      element selected {
        background-color: @selected-col;
        text-color: @fg-col2;
      }

      element alternate.normal {
        background-color: @element-alternate-bg;
        text-color: @fg-col;
      }

      mode-switcher {
        spacing: 0;
      }

      button {
        padding: 10px;
        background-color: @bg-col-light;
        text-color: @grey;
        vertical-align: 0.5;
        horizontal-align: 0.5;
      }

      button selected {
        background-color: @bg-col;
        text-color: @green;
      }
    '';
    themeFile = builtins.toString (pkgs.writeText "${themeName}.rasi" themeText);
    powermenuText = ''
      @theme "${themeName}"

      configuration {
        show-icons: false;
        font: "${stylixFonts.monospace.name} 22";
      }

      window {
        width: 500px;
        location: center;
        anchor: center;

        margin: 0px;
        padding: 0px;

        border: 2px solid;
        border-radius: 0px;
        border-color: @border-col;

        background-color: @bg-col;
      }

      mainbox {
        enabled: true;
        border: 0px solid;
        border-radius: 0px;
        border-color: @selected-col;
        background-color: inherit;
        children: [ "listview" ];
      }

      listview {
        enabled: true;
        lines: 1;
        columns: 5;
        cycle: true;
        dynamic: true;
        scrollbar: false;
        layout: vertical;
        reverse: false;
        fixed-height: true;
        fixed-columns: true;
        spacing: 0px;
        border: inherit;
        border-radius: inherit;
        border-color: inherit;
        text-color: @fg-col;
        background-color: transparent;
      }

      element {
        enabled: true;
        spacing: 0px;
        padding: 28px 0px;
        border: inherit;
        border-radius: inherit;
        border-color: inherit;
        background-color: inherit;
        text-color: @fg-col;
        cursor: pointer;
      }

      element-text {
        vertical-align: 0.5;
        horizontal-align: 0.5;
        font: inherit;
        text-color: inherit;
        background-color: transparent;
        cursor: inherit;
      }

      element selected.normal {
        background-color: @selected-col;
      }
    '';
  in {
    stylix.targets.rofi.enable = lib.mkForce false;

    programs.rofi = {
      theme = lib.mkForce themeFile;
      extraConfig = lib.mkOptionDefault {
        modi = "run,drun,window";
        lines = 5;
        cycle = false;
        show-icons = true;
        icon-theme = "Papirus-Dark";
        drun-display-format = "{icon} {name}";
        location = 0;
        disable-history = true;
        hide-scrollbar = true;
        display-drun = " Apps ";
        display-run = " Run ";
        display-window = " Window ";
        sidebar-mode = true;
        sorting-method = "fzf";
      };
    };

    xdg.dataFile."rofi/themes/powermenu.rasi".text = powermenuText;
  });
}
