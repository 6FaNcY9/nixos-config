# flake.nix (keep on SSD at: nixos-config/flake.nix)
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

    mission-control.url = "github:Platonic-Systems/mission-control";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-root.url = "github:srid/flake-root";

    # Wallpaper
    gruvbox-wallpaper = {
      url = "github:AngelJumbo/gruvbox-wallpapers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}: let
    system = "x86_64-linux";
    primaryHost = "bandit";
    username = "vino";
    repoRoot = "/home/${username}/src/nixos-config";

    overlays = import ./overlays {inherit inputs;};

    pkgsFor = system:
      import inputs.nixpkgs {
        inherit system;
        overlays = [overlays.default];
        config.allowUnfree = true;
      };
  in
    flake-parts.lib.mkFlake {inherit inputs;} ({...}: {
      systems = [system];

      # Enable flake-parts debug mode for development (adds allSystems/currentSystem outputs)
      # Keep false in normal builds to avoid "unknown flake output" warnings.
      debug = false;

      _module.args = {
        inherit primaryHost username repoRoot pkgsFor;
      };

      imports = [
        inputs.ez-configs.flakeModule
        inputs.pre-commit-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.mission-control.flakeModule
        inputs.devshell.flakeModule
        inputs.flake-root.flakeModule
        ./flake-modules
      ];

      ezConfigs = {
        root = ./.;
        globalArgs = {
          inherit inputs username repoRoot;
        };

        nixos.hosts.${primaryHost}.userHomeModules = ["vino"];
      };

      flake = {
        inherit overlays;
      };
    });
}
