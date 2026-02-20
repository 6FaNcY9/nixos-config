# NixOS system configuration for Framework 13 AMD.
#
# Layout:
#   nixos-configurations/  NixOS host configs (auto-wired by ez-configs)
#   home-configurations/   Home Manager user configs (auto-wired by ez-configs)
#   nixos-modules/         Shared NixOS modules (imported by default.nix)
#   home-modules/          Shared Home Manager modules (imported by default.nix)
#   shared-modules/        Modules used by both NixOS and HM (e.g. Stylix)
#   flake-modules/         perSystem devshells, apps, services, checks
#   overlays/              Nixpkgs overlays (pkgs.stable, custom packages)
#   lib/                   Pure helper functions (color, workspace, profile)
{
  description = "Framework 13 AMD: NixOS unstable + i3 + XFCE services + Home Manager + Stylix Gruvbox";

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
  };

  inputs = {
    # Primary: Unstable (latest packages, community standard pattern)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Fallback: Stable 25.11 (when unstable breaks)
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Codex (always up-to-date flake)
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenCode (track upstream; update via `nix flake update opencode`)
    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware quirks for Framework
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
    # Home Manager follows unstable (community pattern)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim (Home Manager module) - use unstable for latest features
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix theming - use unstable
    stylix = {
      url = "github:nix-community/stylix";
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

    # Flake composition
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

    #OpenCode
    opencode-flake.url = "github:aodhanhayter/opencode-flake";
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
      # Absolute path to this repository on disk.  Must be a string (not a Nix
      # path) because NixOS systemd units and nh need the literal runtime path;
      # builtins.getEnv "HOME" is empty during pure evaluation.
      # Default repo location. Override per-host in nixos-configurations/<host>/default.nix:
      #   environment.variables.NIXOS_CONFIG_ROOT = "/custom/path";
      repoRoot = inputs.nixpkgs.lib.mkDefault "/home/${username}/src/nixos-config-refactor";

      # Single source of truth for nixpkgs configuration
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

        # Available to all perSystem flake-modules (e.g. _common.nix, apps.nix).
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

        # ez-configs auto-discovers {nixos,home}-configurations/ and wires them.
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
