# flake.nix (keep on SSD at: nixos-config/flake.nix)
{
  description = "Framework 13 AMD: NixOS 25.11 + i3 + XFCE services + Home Manager + Stylix Gruvbox";

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
  };

  inputs = {
    # Stable 25.11
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Unstable (for newer packages like codex)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Codex (always up-to-date flake)
    codex-cli-nix.url = "github:sadjow/codex-cli-nix";

    # Hardware quirks for Framework
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
    # Match Home Manager to NixOS release branch
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim (Home Manager module)
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix theming
    stylix = {
      url = "github:nix-community/stylix/release-25.11";
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
    flake-parts.url = "github:hercules-ci/flake-parts";
    ez-configs.url = "github:ehllie/ez-configs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    mission-control.url = "github:Platonic-Systems/mission-control";
    devshell.url = "github:numtide/devshell";
    flake-root.url = "github:srid/flake-root";

    # Development services (replaces docker-compose)
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";

    # Wallpaper
    gruvbox-wallpaper.url = "github:AngelJumbo/gruvbox-wallpapers";
  };

  outputs = inputs @ {flake-parts, ...}: let
    system = "x86_64-linux";
    primaryHost = "bandit";
    username = "vino";
    repoRoot = "/home/${username}/src/nixos-config-ez";

    overlays = import ./overlays {inherit inputs;};

    pkgsFor = system:
      import inputs.nixpkgs {
        inherit system;
        overlays = [overlays.default];
        config.allowUnfree = true;
      };
  in
    flake-parts.lib.mkFlake {inherit inputs;} ({self, ...}: {
      systems = [system];

      debug = true;

      imports = [
        inputs.ez-configs.flakeModule
        inputs.pre-commit-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.mission-control.flakeModule
        inputs.devshell.flakeModule
        inputs.flake-root.flakeModule
        inputs.flake-parts.flakeModules.modules
        inputs.process-compose-flake.flakeModule
      ];

      ezConfigs = {
        root = ./.;
        globalArgs = {
          inherit inputs username repoRoot;
        };

        nixos.hosts.${primaryHost}.userHomeModules = ["vino"];
      };

      perSystem = {
        system,
        config,
        ...
      }: let
        pkgs = pkgsFor system;
        customPackages =
          if builtins.pathExists ./pkgs/default.nix
          then import ./pkgs {}
          else {};
        missionControlWrapper = config.mission-control.wrapper;
        maintenancePackages = [pkgs.pre-commit pkgs.nix missionControlWrapper] ++ config.pre-commit.settings.enabledPackages;

        # Common utilities for project devShells (CLI tools only, no flake management)
        commonDevPackages = with pkgs; [
          git
          gh # GitHub CLI
          jq
          yq-go
          curl
          wget
          htop
          btop
          ripgrep
          fd
          fzf
          eza
          bat
          tree
        ];

        # Maintenance packages include mission-control for flake management
        maintenanceDevPackages = maintenancePackages ++ commonDevPackages;

        repoRootCmd = ''repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"'';

        mkApp = name: runtimeInputs: description: text: {
          type = "app";
          program = "${pkgs.writeShellApplication {inherit name runtimeInputs text;}}/bin/${name}";
          meta = {inherit description;};
        };
      in {
        treefmt = {
          projectRootFile = "flake.nix";
          programs.alejandra.enable = true;
          flakeCheck = true;
        };

        formatter = config.treefmt.build.wrapper;

        mission-control = {
          scripts = {
            fmt = {
              description = "Format Nix files";
              exec = config.treefmt.build.wrapper;
              category = "Dev Tools";
            };
            qa = {
              description = "Format, lint, and flake check";
              exec = "nix run .#qa";
              category = "Dev Tools";
            };
            update = {
              description = "Update flake inputs";
              exec = "nix run .#update";
              category = "Dev Tools";
            };
            clean = {
              description = "Remove result symlinks";
              exec = "nix run .#clean";
              category = "Dev Tools";
            };
            services = {
              description = "Start local services (postgres, redis)";
              exec = "nix run .#services";
              category = "Services";
            };
            tree = {
              description = "Visualize nix dependencies";
              exec = "nix-tree";
              category = "Analysis";
            };
            web = {
              description = "Enter web development shell";
              exec = "nix develop .#web";
              category = "Dev Shells";
            };
            rust = {
              description = "Enter Rust development shell";
              exec = "nix develop .#rust";
              category = "Dev Shells";
            };
          };
        };

        # nix eval fix (wrap outPath as a derivation)
        packages =
          customPackages
          // {
            gruvboxWallpaperOutPath = pkgs.writeText "gruvbox-wallpaper-outPath" inputs.gruvbox-wallpaper.outPath;
          };

        pre-commit = {
          check.enable = true;
          settings.hooks = {
            treefmt = {
              enable = true;
              package = config.treefmt.build.wrapper;
            };
            statix.enable = true;
            deadnix.enable = true;
          };
        };

        apps = {
          update = mkApp "update" [pkgs.coreutils pkgs.git pkgs.nix] "Update flake inputs" ''
            set -euo pipefail
            ${repoRootCmd}
            cd "$repo_root"
            nix flake update
          '';

          clean = mkApp "clean" [pkgs.coreutils pkgs.git] "Remove result symlinks" ''
            set -euo pipefail
            ${repoRootCmd}
            cd "$repo_root"
            rm -f result result-*
          '';

          qa =
            mkApp "qa" [
              pkgs.alejandra
              pkgs.coreutils
              pkgs.deadnix
              pkgs.git
              pkgs.nix
              pkgs.pre-commit
              pkgs.statix
              config.treefmt.build.wrapper
            ] "Format, lint, and run flake checks" ''
              set -euo pipefail
              ${repoRootCmd}
              cd "$repo_root"
              treefmt --no-cache
              statix check .
              deadnix -f .
              pre-commit run --all-files --config ${config.pre-commit.settings.configFile}
              nix flake check --option warn-dirty false
            '';

          commit =
            mkApp "commit" [
              pkgs.alejandra
              pkgs.coreutils
              pkgs.deadnix
              pkgs.git
              pkgs.nix
              pkgs.pre-commit
              pkgs.statix
              config.treefmt.build.wrapper
            ] "Run QA, stage, and commit with a prompt" ''
              set -euo pipefail
              ${repoRootCmd}
              cd "$repo_root"
              treefmt --no-cache
              statix check .
              deadnix -f .
              pre-commit run --all-files --config ${config.pre-commit.settings.configFile}
              nix flake check --option warn-dirty false

              git add -A

              printf "Commit message: "
              read -r msg
              if [ -z "$msg" ]; then
                echo "Commit message required." >&2
                exit 1
              fi
              git commit --no-verify -m "$msg"
              rm -f result result-*
            '';
        };

        # Maintenance: static checks + eval targets
        checks = {
          nixos-bandit = self.nixosConfigurations.${primaryHost}.config.system.build.toplevel;
          home-vino = self.homeConfigurations."${username}@${primaryHost}".activationPackage;
        };

        # Process-compose services for local development
        process-compose."services" = {
          imports = [inputs.services-flake.processComposeModules.default];

          services.postgres."pg1" = {
            enable = false; # Enable manually when needed
            initialDatabases = [{name = "dev";}];
            port = 5432;
          };

          services.redis."redis1" = {
            enable = false; # Enable manually when needed
            port = 6379;
          };

          settings.processes = {
            # Example custom process
            # my-app.command = "echo 'Add your app command here'";
          };
        };

        devshells = {
          maintenance = {
            packages = maintenanceDevPackages;
            devshell.motd = ''
              {202}🔨 Maintenance Shell{reset}
              Run ',' for mission-control commands
              Available: fmt, qa, update, clean
            '';
          };

          default = {
            packages = maintenanceDevPackages;
            devshell.motd = ''
              {202}🔨 Development Shell{reset}
              Run ',' for mission-control commands
              Services: nix run .#services (postgres, redis)
            '';
          };

          flask = {
            packages =
              commonDevPackages
              ++ (with pkgs; [
                python3
                python3Packages.flask
                python3Packages.requests
                python3Packages.virtualenv
                python3Packages.pip
                poetry
              ]);
            devshell.motd = ''
              {202}🐍 Flask Development Shell{reset}
              Python: ${pkgs.python3.version}
            '';
          };

          web = {
            packages =
              commonDevPackages
              ++ (with pkgs; [
                nodejs # Includes npm by default
                pnpm # Standalone, no nodejs conflict
                yarn # Standalone, no nodejs conflict
                nodePackages.typescript
                nodePackages.typescript-language-server
              ]);
            devshell.motd = ''
              {202}🌐 Web Development Shell{reset}
              Node: ${pkgs.nodejs.version}
              npm, pnpm, yarn, TypeScript available
            '';
          };

          rust = {
            packages =
              commonDevPackages
              ++ (with pkgs; [
                rustc
                cargo
                rustfmt
                clippy
                rust-analyzer
                cargo-watch
                cargo-edit
              ]);
            devshell.motd = ''
              {202}🦀 Rust Development Shell{reset}
              Rustc: ${pkgs.rustc.version}
            '';
          };
        };
      };

      flake = {
        inherit overlays;
        modules = {
          nixos.default = ./nixos-modules;
          home.default = ./home-modules;
        };
      };
    });
}
