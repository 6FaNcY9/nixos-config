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

  opencodeSrc = inputs.opencode;
  # Use newer bun for the opencode build; stable nixpkgs is behind.
  opencodeBun = pkgs.unstable.bun;
  opencodeNodeModulesHashes =
    (builtins.fromJSON (builtins.readFile "${opencodeSrc}/nix/hashes.json")).nodeModules;
  # WORKAROUND: Override x86_64-linux hash until upstream updates hashes.json for dev branch
  # The dev branch node_modules dependencies have changed but hashes.json hasn't been updated yet
  # This hash was computed manually via: nix-prefetch-url --unpack <node_modules_tarball>
  # TODO: Remove this override once https://github.com/anomalyco/opencode/pull/XXX is merged
  # Last checked: 2026-01-30
  opencodeNodeModulesHash =
    if system == "x86_64-linux"
    then "sha256-gUWzUsk81miIrjg0fZQmsIQG4pZYmEHgzN6BaXI+lfc="
    else opencodeNodeModulesHashes.${system};
  opencodeNodeModules = pkgs.callPackage "${opencodeSrc}/nix/node_modules.nix" {
    rev = opencodeSrc.shortRev or opencodeSrc.rev or "dirty";
    hash = opencodeNodeModulesHash;
  };
  opencodePkg = pkgs.callPackage "${opencodeSrc}/nix/opencode.nix" {
    node_modules = opencodeNodeModules;
    bun = opencodeBun;
  };
  i3Pkg = pkgs.i3;
in {
  imports = [../../home-modules/default.nix] ++ hostModules;

  # Inject shared arguments to all home-modules
  # Colors and palette come from shared-modules/palette.nix
  _module.args = {
    inherit (config.theme) palette;
    inherit (config) workspaces;
    c = config.theme.colors;
    inherit stylixFonts i3Pkg codexPkg opencodePkg;
    hostname = hostName;
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
    # IMPORTANT: Ensure GPG key FC8B68693AF4E0D9DC84A4D3B872E229ADE55151 is imported
    # Verify with: gpg --list-secret-keys FC8B68693AF4E0D9DC84A4D3B872E229ADE55151
    # Import if missing: gpg --import /path/to/private-key.asc
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
        modi = "run,drun,window";
        drun-display-format = "{icon} {name}";
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
