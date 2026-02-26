# NixOS configuration for Framework 13 AMD.
#
# Features: NixOS unstable + i3 + XFCE services + Home Manager + Stylix Gruvbox theming.
#
# Layout:
#   nixos-configurations/  - NixOS host configs (auto-discovered by ez-configs)
#   home-configurations/   - Home Manager user configs (auto-discovered by ez-configs)
#   nixos-modules/         - Shared NixOS modules (core/ and features/)
#   home-modules/          - Shared Home Manager modules
#   shared-modules/        - Modules used by both NixOS and HM (Stylix, palette, workspaces)
#   flake-modules/         - perSystem devshells, apps, services, checks
#   overlays/              - Nixpkgs overlays (custom packages)
#   lib/                   - Pure helper functions (color, workspace, validation)
{
  description = "Framework 13 AMD: NixOS unstable + i3 + XFCE services + Home Manager + Stylix Gruvbox";

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
  };

  inputs = {
    # Primary: Unstable (latest packages, recommended for most users)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Fallback: Stable 25.11 (when unstable breaks)
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Codex CLI (always up-to-date)
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenCode (upstream tracking; update via `nix flake update opencode`)
    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware quirks for Framework laptops
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
    # Home Manager (follows unstable for consistency)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim (Home Manager module) - follows unstable for latest features
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix theming - follows unstable
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Prebuilt nix-index database (prevents 12GB evaluation)
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management (sops)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pre-commit tooling
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake composition framework
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    ez-configs = {
      url = "github:ehllie/ez-configs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development services (PostgreSQL, Redis, etc.)
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";

    # Wallpaper
    gruvbox-wallpaper = {
      url = "github:AngelJumbo/gruvbox-wallpapers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      system = "x86_64-linux";
      primaryHost = "bandit";
      # Auto-derive username from single directory under home-configurations/
      homeUsers = builtins.attrNames (builtins.readDir ./home-configurations);
      username =
        if builtins.length homeUsers == 1 then
          builtins.elemAt homeUsers 0
        else
          throw "Expected exactly 1 user directory under home-configurations/, found ${toString (builtins.length homeUsers)}";

      # repoRoot: Absolute path to this repository on disk.
      # Must be a string (not a Nix path) because:
      #   - NixOS systemd units need the literal runtime path
      #   - nh needs the literal path for flake operations
      #   - builtins.getEnv "HOME" is empty during pure evaluation
      # Override per-host via: environment.variables.NIXOS_CONFIG_ROOT = "/custom/path";
      repoRoot = inputs.nixpkgs.lib.mkDefault "/home/${username}/src/nixos-config";

      # nixpkgsConfig: Shared configuration for all nixpkgs instances.
      # allowAliases=false reduces deprecation noise and enforces use of canonical package names.
      nixpkgsConfig = {
        allowUnfree = true;
        allowAliases = false;
      };

      overlays = import ./overlays { inherit inputs; };

      pkgsFor =
        system:
        import inputs.nixpkgs {
          inherit system;
          overlays = [ overlays.default ];
          config = nixpkgsConfig;
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      {
        systems = [ system ];

        # Enable flake-parts debug mode for development (adds allSystems/currentSystem outputs)
        # Keep false in normal builds to avoid "unknown flake output" warnings.
        debug = false;

        # globalArgs: Available to all perSystem flake-modules (e.g. _common.nix, apps.nix).
        # Contains: primaryHost, username, repoRoot, pkgsFor, nixpkgsConfig
        _module.args = {
          inherit
            primaryHost
            username
            repoRoot
            pkgsFor
            nixpkgsConfig
            ;
        };

        imports = [
          inputs.ez-configs.flakeModule
          inputs.pre-commit-hooks.flakeModule
          inputs.treefmt-nix.flakeModule
          inputs.devshell.flakeModule
          inputs.process-compose-flake.flakeModule
          ./flake-modules
        ];

        # ez-configs: Auto-discovers {nixos,home}-configurations/ and wires them.
        # globalArgs become available in every NixOS and Home Manager module.
        ezConfigs = {
          root = ./.;
          globalArgs = {
            inherit
              inputs
              username
              repoRoot
              nixpkgsConfig
              ;
          };

          nixos.hosts.${primaryHost}.userHomeModules = [ username ];
        };

        flake = {
          inherit overlays;
        };
      }
    );
}
