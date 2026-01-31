# Shared color palette - derives semantic colors from Stylix base16 scheme
# This provides a consistent theming interface across all modules
{
  lib,
  config,
  ...
}: let
  # Get Stylix colors with fallback (Gruvbox dark hard)
  c =
    lib.attrByPath ["lib" "stylix" "colors" "withHashtag"] {
      base00 = "#1d2021"; # ---- (dark background)
      base01 = "#3c3836"; # --- (dark alt background)
      base02 = "#504945"; # -- (selection background)
      base03 = "#665c54"; # - (comments, invisibles)
      base04 = "#bdae93"; # + (dark foreground)
      base05 = "#d5c4a1"; # ++ (default foreground)
      base06 = "#ebdbb2"; # +++ (light foreground)
      base07 = "#fbf1c7"; # ++++ (light background)
      base08 = "#fb4934"; # red
      base09 = "#fe8019"; # orange
      base0A = "#fabd2f"; # yellow
      base0B = "#b8bb26"; # green
      base0C = "#8ec07c"; # aqua/cyan
      base0D = "#83a598"; # blue
      base0E = "#d3869b"; # purple
      base0F = "#d65d0e"; # brown
    }
    config;
in {
  options.theme = {
    colors = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      default = c;
      description = "Raw base16 colors from Stylix (with fallback).";
    };

    palette = lib.mkOption {
      type = lib.types.submodule {
        options = {
          bg = lib.mkOption {
            type = lib.types.str;
            default = c.base00;
            description = "Primary background color.";
          };
          bgAlt = lib.mkOption {
            type = lib.types.str;
            default = c.base01;
            description = "Alternative/secondary background color.";
          };
          text = lib.mkOption {
            type = lib.types.str;
            default = c.base05;
            description = "Primary text color.";
          };
          accent = lib.mkOption {
            type = lib.types.str;
            default = c.base0B;
            description = "Primary accent color (green).";
          };
          accent2 = lib.mkOption {
            type = lib.types.str;
            default = c.base0D;
            description = "Secondary accent color (blue).";
          };
          warn = lib.mkOption {
            type = lib.types.str;
            default = c.base0A;
            description = "Warning color (yellow).";
          };
          danger = lib.mkOption {
            type = lib.types.str;
            default = c.base08;
            description = "Danger/error color (red).";
          };
          muted = lib.mkOption {
            type = lib.types.str;
            default = c.base03;
            description = "Muted/disabled text color.";
          };
        };
      };
      default = {};
      description = "Semantic color palette derived from base16 scheme.";
    };
  };
}
