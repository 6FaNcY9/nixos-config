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
  inherit (pkgs.stdenv.hostPlatform) system;
  hostName = if osConfig != null then osConfig.networking.hostName else hostname; # Fallback when using standalone home-manager
  hostModulePath = ./hosts/${hostName}.nix;
  hostModules = lib.optionals (builtins.pathExists hostModulePath) [ hostModulePath ];

  # Stylix fonts (with fallback)
  stylixFonts = lib.attrByPath [ "stylix" "fonts" ] {
    sansSerif = {
      name = "Sans";
    };
    monospace = {
      name = "Monospace";
    };
  } config;

  codexPkg = inputs.codex-cli-nix.packages.${system}.default;
  opencodePkg = pkgs.opencode;

  i3Pkg = pkgs.i3;
in
{
  imports = [ ../../home-modules/default.nix ] ++ hostModules;

  # Inject shared arguments available to ALL home-modules via function args.
  #
  # Available args and their sources:
  #   palette   — semantic colors (bg, text, accent, ...) from shared-modules/palette.nix
  #   c         — raw base16 colors (base00..base0F) from config.theme.colors
  #   workspaces — i3 workspace definitions [{number, icon}] from shared-modules/workspaces.nix
  #   stylixFonts — {sansSerif, monospace} from Stylix config (with fallback)
  #   i3Pkg     — the i3 package (pkgs.i3)
  #   codexPkg  — codex CLI from flake input
  #   opencodePkg — opencode from overlay
  #   hostname  — current host name (from NixOS or ez-configs)
  #   cfgLib    — helper library from lib/ (mkShellScript, mkColorReplacer, etc.)
  #
  # Usage: add the arg name to any home-module's function args, e.g.
  #   {pkgs, palette, cfgLib, ...}:
  _module.args = {
    inherit (config.theme) palette;
    inherit (config) workspaces;
    c = config.theme.colors;
    inherit
      stylixFonts
      i3Pkg
      codexPkg
      opencodePkg
      ;
    hostname = hostName;
    cfgLib = import ../../lib { inherit lib; };
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
        flatpakSupport.enable = true;
      };

      alacritty.enable = true;
      btop.enable = true;
      fzf.enable = true;
      dunst.enable = true;
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

      firefox = {
        enable = false; # Disabled - manual dark mode config in firefox.nix
      };

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
      signingkey = "FC8B68693AF4E0D9DC84A4D3B872E229ADE55151";
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
