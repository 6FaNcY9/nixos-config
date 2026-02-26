# Stylix theming — shared between NixOS and Home Manager.
#
# Sets global theme configuration:
#   - Base16 scheme: Gruvbox Dark Pale (base16-schemes/gruvbox-dark-pale.yaml)
#   - Wallpaper: gruvbox-rainbow-nix.png (overridable via theme.wallpaper)
#   - Icon theme: Papirus (Dark/Light variants)
#   - Fonts: Iosevka Term Nerd Font (all styles), Noto Color Emoji
#
# This module is imported by both NixOS and Home Manager configurations to ensure consistent theming.

{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  # Wallpaper option - can be overridden per-host
  options.theme.wallpaper = lib.mkOption {
    type = lib.types.path;
    default = "${inputs.gruvbox-wallpaper}/wallpapers/brands/gruvbox-rainbow-nix.png";
    description = "Path to wallpaper image for Stylix.";
  };

  # Shared Stylix settings (safe to import in BOTH NixOS + Home Manager).
  # Docs: https://nix-community.github.io/stylix/
  config.stylix = {
    enable = true;

    # Use configurable wallpaper
    image = config.theme.wallpaper;

    polarity = lib.mkDefault "dark";
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/gruvbox-dark-pale.yaml";

    # Icon theme configuration (updated for unstable API)
    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus-Light";
    };

    # Fonts strategy:
    # - Use Iosevka Term (terminal-optimized variant with narrow symbols and ligatures).
    # - Nerd Font patched version provides icon glyph support.
    fonts = {
      sizes = {
        applications = 10;
        terminal = 8;
        desktop = 10;
        popups = 10;
      };

      monospace = {
        package = pkgs.nerd-fonts.iosevka-term;
        name = "IosevkaTerm Nerd Font";
      };

      sansSerif = {
        package = pkgs.nerd-fonts.iosevka-term;
        name = "IosevkaTerm Nerd Font";
      };

      serif = {
        package = pkgs.nerd-fonts.iosevka-term;
        name = "IosevkaTerm Nerd Font";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
