# Home Manager configuration for user: vino
# Most configuration is in home-modules/*. This file contains:
# - User-specific settings (git identity, stylix targets)
# - Module arguments injection
{
  lib,
  config,
  pkgs,
  osConfig ? null,
  username,
  hostname,
  ...
}:
let
  hostName = if osConfig != null then osConfig.networking.hostName else hostname; # Fallback when using standalone home-manager
  hostModulePath = ./hosts/${hostName}.nix;
  hostModules = lib.optionals (builtins.pathExists hostModulePath) [ hostModulePath ];
in
{
  imports = [ ../../home-modules/default.nix ] ++ hostModules;

  # Inject shared arguments into all home-modules via _module.args.
  _module.args =
    let
      stylixFonts = lib.attrByPath [ "stylix" "fonts" ] {
        sansSerif.name = "Sans";
        monospace.name = "Monospace";
      } config;
    in
    {
      inherit (config.theme) palette;
      inherit (config) workspaces;
      c = config.theme.colors;
      inherit stylixFonts;
      hostname = hostName;
      cfgLib = import ../../lib {
        inherit lib pkgs;
      };
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

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  news.display = "silent";

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true; # Keep legacy behavior (new default is false in 26.05+)
    };
  };

  # Keep GTK4 using the same stylix-managed theme (new HM default in 26.05+ is null).
  gtk.gtk4.theme = config.gtk.theme;

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
        flatpakSupport.enable = false;
        # Stylix maps base0D (teal) as selection bg — too bright for a dark theme.
        # Override all GTK3 + libadwaita selection color variables to base02 (dark grey).
        extraCss = ''
          @define-color accent_bg_color ${config.theme.colors.base02};
          @define-color accent_fg_color ${config.theme.palette.cream};
          @define-color theme_selected_bg_color ${config.theme.colors.base02};
          @define-color theme_selected_fg_color ${config.theme.palette.cream};
          @define-color selected_bg_color ${config.theme.colors.base02};
          @define-color selected_fg_color ${config.theme.palette.cream};
          *:selected, *:selected * {
            background-color: ${config.theme.colors.base02} !important;
            color: ${config.theme.palette.cream} !important;
          }
        '';
      };

      alacritty.enable = true;
      btop.enable = true;
      bat.enable = true;
      fzf.enable = true;

      dunst.enable = false; # Managed manually in features.desktop.services with palette colors
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
