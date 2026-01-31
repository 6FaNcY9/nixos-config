{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
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
    # - Use regular JetBrains Mono (better glyph metrics).
    # - Install Symbols Nerd Font (symbols-only) separately (nixos-modules/core.nix) so icons come via fallback.
    fonts = {
      sizes = {
        applications = 10;
        terminal = 8;
        desktop = 10;
        popups = 10;
      };

      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };

      sansSerif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };

      serif = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}
