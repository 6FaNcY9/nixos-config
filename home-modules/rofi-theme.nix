# Custom Rofi theme matching gruvbox aesthetic
{
  config,
  lib,
  palette,
  ...
}: {
  config = lib.mkIf config.profiles.desktop (let
    inherit (config.lib.formats.rasi) mkLiteral;
    theme = {
      "*" = {
        bg = mkLiteral palette.bg;
        bg-alt = mkLiteral palette.bgAlt;
        fg = mkLiteral palette.text;
        fg-alt = mkLiteral palette.muted;
        accent = mkLiteral palette.accent2;
        accent2 = mkLiteral palette.accent;
        urgent = mkLiteral palette.danger;

        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
        font = "JetBrainsMono Nerd Font 11";
      };

      window = {
        transparency = "real";
        background-color = mkLiteral "@bg";
        border = mkLiteral "2px";
        border-color = mkLiteral "@accent";
        border-radius = mkLiteral "8px";
        width = mkLiteral "600px";
        padding = mkLiteral "20px";
      };

      mainbox = {
        background-color = mkLiteral "transparent";
        children = map mkLiteral ["inputbar" "message" "listview"];
        spacing = mkLiteral "15px";
      };

      inputbar = {
        background-color = mkLiteral "@bg-alt";
        text-color = mkLiteral "@fg";
        border = mkLiteral "0px 0px 2px 0px";
        border-color = mkLiteral "@accent";
        border-radius = mkLiteral "4px";
        padding = mkLiteral "12px 16px";
        spacing = mkLiteral "10px";
        children = map mkLiteral ["prompt" "entry"];
      };

      prompt = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@accent";
        font = "JetBrainsMono Nerd Font Bold 11";
      };

      entry = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
        placeholder = "Search...";
        placeholder-color = mkLiteral "@fg-alt";
        cursor = mkLiteral "text";
      };

      message = {
        background-color = mkLiteral "@bg-alt";
        border = mkLiteral "2px";
        border-color = mkLiteral "@accent2";
        border-radius = mkLiteral "4px";
        padding = mkLiteral "10px";
      };

      textbox = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
      };

      listview = {
        background-color = mkLiteral "transparent";
        columns = 1;
        lines = 8;
        spacing = mkLiteral "5px";
        cycle = true;
        dynamic = true;
        layout = mkLiteral "vertical";
      };

      element = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
        orientation = mkLiteral "horizontal";
        border-radius = mkLiteral "4px";
        padding = mkLiteral "8px 12px";
      };

      "element selected" = {
        background-color = mkLiteral "@bg-alt";
        text-color = mkLiteral "@accent";
        border = mkLiteral "0px 0px 0px 3px";
        border-color = mkLiteral "@accent";
      };

      "element-icon" = {
        background-color = mkLiteral "transparent";
        size = mkLiteral "24px";
        margin = mkLiteral "0px 10px 0px 0px";
      };

      "element-text" = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "inherit";
        vertical-align = mkLiteral "0.5";
      };

      "element-text selected" = {
        text-color = mkLiteral "@accent";
      };
    };
  in {
    stylix.targets.rofi.enable = lib.mkForce false;
    programs.rofi.theme = lib.mkForce theme;
  });
}
