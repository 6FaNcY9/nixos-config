{
  pkgs,
  lib,
  inputs,
  ...
}: {
  # Shared Stylix settings (safe to import in BOTH NixOS + Home Manager).
  # Docs: https://nix-community.github.io/stylix/
  stylix = {
    enable = true;

    # Wallpaper
    #image = "/home/vino/Pictures/gruvbox-rainbow-nix.png";
    image = "${inputs.gruvbox-wallpaper}/wallpapers/brands/gruvbox-rainbow-nix.png";

    polarity = lib.mkDefault "dark";
    base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/gruvbox-dark-pale.yaml";

    # Fonts strategy:
    # - Use regular JetBrains Mono (better glyph metrics).
    # - Install Symbols Nerd Font (symbols-only) separately (nixos/configuration.nix) so icons come via fallback.
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
