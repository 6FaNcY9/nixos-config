# Home Manager configuration for user: vino
# Most configuration is in home-modules/*. This file contains:
# - User-specific settings (git identity, stylix targets)
# - Module arguments injection
{
  lib,
  pkgs,
  config,
  inputs,
  osConfig ? null,
  username,
  hostname,
  repoRoot,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  hostName = osConfig.networking.hostName or hostname;
  hostModulePath = ./hosts/${hostName}.nix;
  hostModules = lib.optionals (builtins.pathExists hostModulePath) [hostModulePath];

  # Stylix fonts (with fallback)
  stylixFonts =
    lib.attrByPath ["stylix" "fonts"] {
      sansSerif = {name = "Sans";};
      monospace = {name = "Monospace";};
    }
    config;

  codexPkg = inputs.codex-cli-nix.packages.${system}.default;
  i3Pkg = pkgs.i3;
in {
  imports = [../../home-modules/default.nix] ++ hostModules;

  # Inject shared arguments to all home-modules
  # Colors and palette come from shared-modules/palette.nix
  _module.args = {
    c = config.theme.colors;
    palette = config.theme.palette;
    inherit stylixFonts i3Pkg codexPkg;
    hostname = hostName;
    workspaces = config.workspaces;
  };

  # ============================================================
  # Home settings
  # ============================================================
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.11";
  };

  home.sessionVariables = {
    NH_NOM = "1";
  };

  news.display = "silent";

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # ============================================================
  # Stylix targets
  # ============================================================
  stylix = {
    enable = true;
    autoEnable = false;

    targets = {
      qt.enable = true;
      gtk = {
        enable = true;
        flatpakSupport.enable = true;
      };

      alacritty.enable = true;
      btop.enable = true;
      fzf.enable = true;
      dunst.enable = true;
      xfce.enable = true;
      rofi.enable = true;

      starship = {
        enable = true;
        colors.enable = true;
      };

      nixvim = {
        enable = true;
        plugin = "mini.base16";
        transparentBackground = {
          main = false;
          signColumn = true;
        };
      };

      firefox = {
        enable = lib.mkDefault true;
        profileNames = [username];
      };
    };
  };

  # ============================================================
  # User-specific program settings
  # ============================================================
  programs = {
    home-manager.enable = true;

    # Git identity (user-specific)
    git.settings.user = {
      name = "6FaNcY9";
      email = "29282675+6FaNcY9@users.noreply.github.com";
      signingkey = "FC8B68693AF4E0D9DC84A4D3B872E229ADE55151";
    };
    git.settings.commit.gpgsign = true;

    # Rofi (user-specific icon theme)
    rofi = {
      enable = true;
      terminal = "${pkgs.alacritty}/bin/alacritty";
      extraConfig = {
        show-icons = true;
        icon-theme = "Papirus-Dark";
        modi = "drun,run,window";
        drun-display-format = "{name}";
        font = "${stylixFonts.sansSerif.name} 12";
      };
    };

    # btop (small config)
    btop = {
      enable = true;
      settings = {
        vim_keys = true;
        update_ms = 1000;
        proc_sorting = "cpu lazy";
      };
    };
  };
}
