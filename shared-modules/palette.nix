# Shared color palette - derives semantic colors from Stylix base16 scheme.
#
# Two color systems are exposed via _module.args:
#
#   c (config.theme.colors)   — raw base16 slots (base00..base0F).
#     Use when you need a specific base16 hue by slot number, e.g. c.base0D
#     for "blue".  These are positional and theme-dependent.
#
#   palette (config.theme.palette) — semantic names (bg, text, accent, warn, ...).
#     Prefer this for most UI code.  Meaning stays stable across themes.
#
# Rule of thumb: reach for `palette` first; use `c` only when the semantic
# name doesn't exist (e.g. c.base07 for "cream", c.base0F for "orange").
{
  lib,
  config,
  ...
}: let
  # Get Stylix colors with fallback (Gruvbox dark pale)
  c =
    lib.attrByPath ["lib" "stylix" "colors" "withHashtag"] {
      base00 = "#262626";
      base01 = "#3a3a3a";
      base02 = "#4e4e4e";
      base03 = "#8a8a8a";
      base04 = "#949494";
      base05 = "#dab997";
      base06 = "#d5c4a1";
      base07 = "#ebdbb2";
      base08 = "#d75f5f";
      base09 = "#ff8700";
      base0A = "#ffaf00";
      base0B = "#afaf00";
      base0C = "#85ad85";
      base0D = "#83adad";
      base0E = "#d485ad";
      base0F = "#d65d0e";
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
