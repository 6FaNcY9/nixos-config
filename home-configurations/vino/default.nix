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
  ...
}:
let
  cfgLib = import ../../lib { inherit lib; };
  hostName = if osConfig != null then osConfig.networking.hostName else hostname; # Fallback when using standalone home-manager
  hostModulePath = ./hosts/${hostName}.nix;
  hostModules = lib.optionals (builtins.pathExists hostModulePath) [ hostModulePath ];
in
{
  imports = [ ../../home-modules/default.nix ] ++ hostModules;

  # Inject shared arguments into all home-modules via _module.args.
  # See lib/default.nix:mkUserModuleArgs for the full list of injected args.
  _module.args = cfgLib.mkUserModuleArgs {
    inherit
      config
      pkgs
      inputs
      hostName
      ;
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
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
  };
  news.display = "silent";

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Validation warnings
  warnings = lib.optionals (config.programs.git.settings.commit.gpgsign or false) [
    ''
      Git commit signing is enabled. Ensure GPG key is imported:
        gpg --list-secret-keys ${config.programs.git.settings.user.signingkey or ""}
      If missing, import with:
        gpg --import /path/to/private-key.asc
    ''
  ];

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
        colors.enable = true;
        flatpakSupport.enable = true;
      };

      alacritty.enable = true;
      btop.enable = true;
      bat.enable = true;
      fzf.enable = true;

      dunst.enable = true;
      qutebrowser.enable = true;
      xfce.enable = true;

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

      firefox.enable = false;

      tmux = {
        enable = true;
        colors.enable = true;
      };
    };
  };

  # ============================================================
  # User-specific program settings
  # ============================================================
  programs = {
    home-manager.enable = true;

    # Git identity (user-specific)
    # IMPORTANT: Ensure GPG key FC8B68693AF4E0D9DC84A4D3B872E229ADE55151 is imported
    # Verify with: gpg --list-secret-keys FC8B68693AF4E0D9DC84A4D3B872E229ADE55151
    # Import if missing: gpg --import /path/to/private-key.asc
    git.settings.user = {
      name = "6FaNcY9";
      email = "29282675+6FaNcY9@users.noreply.github.com";
      signingkey = "4D8770567A65FE1369E2BCC1611871842A8C1619";
    };
    git.settings.commit.gpgsign = true;

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
