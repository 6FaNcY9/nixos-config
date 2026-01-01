{ pkgs, lib, ... }:

{
  # Shared Stylix settings (safe to import in BOTH NixOS + Home Manager).
  # Docs: https://nix-community.github.io/stylix/
  stylix = {
    enable = true;

    polarity = lib.mkDefault "dark";
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/gruvbox-dark-pale.yaml";

    # Fonts strategy:
    # - Use regular JetBrains Mono (better glyph metrics).
    # - Install Symbols Nerd Font (symbols-only) separately (configuration.nix) so icons come via fallback.
    fonts = {
      sizes = {
        applications = 12;
        terminal = 12;
        desktop = 10;
        popups = 10;
      };

      monospace = {
        package = pkgs.jetbrains-mono;
        name = "JetBrains Mono";
      };

      sansSerif = {
        package = pkgs.jetbrains-mono;
        name = "JetBrains Mono";
      };

      serif = {
        package = pkgs.jetbrains-mono;
        name = "JetBrains Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
  };
}

