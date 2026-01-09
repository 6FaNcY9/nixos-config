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
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake composition
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Wallpaper
    gruvbox-wallpaper.url = "github:AngelJumbo/gruvbox-wallpapers";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    nixos-hardware,
    home-manager,
    stylix,
    sops-nix,
    ...
  }: let
    system = "x86_64-linux";
    hostname = "bandit";
    username = "vino";

    commonSpecialArgs = {
      inherit inputs username hostname;
      repoRoot = "/home/${username}/src/nixos-config";
    };

    overlays = import ./overlays {inherit inputs;};

    pkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = [overlays.default];
        config.allowUnfree = true;
      };

    # Shared HM modules used inside the NixOS system build (Stylix is on the NixOS side)
    hmSharedModules = [
      inputs.nixvim.homeModules.nixvim
      inputs.sops-nix.homeManagerModules.sops
    ];

    # Standalone Home Manager output includes Stylix modules
    hmSharedModulesHM =
      hmSharedModules
      ++ [
        inputs.stylix.homeModules.stylix
        ./modules/shared/stylix-common.nix
      ];
  in
    flake-parts.lib.mkFlake {inherit inputs;} ({self, ...}: {
      systems = [system];

      imports = [
        inputs.home-manager.flakeModules.home-manager
      ];

      perSystem = {system, ...}: let
        pkgs = pkgsFor system;
        customPackages = import ./pkgs {};

        preCommit = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            treefmt = {
              enable = true;
              settings.formatters = [pkgs.alejandra];
            };
            statix.enable = true;
            deadnix.enable = true;
          };
        };

        maintenanceShell = pkgs.mkShell {
          packages = with pkgs; [
            alejandra
            deadnix
            statix
            treefmt
            pre-commit
            nix
          ];
          inherit (preCommit) shellHook;
        };

        repoRootCmd = ''repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"'';

        mkApp = name: runtimeInputs: description: text: {
          type = "app";
          program = "${pkgs.writeShellApplication {inherit name runtimeInputs text;}}/bin/${name}";
          meta = {inherit description;};
        };
      in {
        formatter = pkgs.alejandra;

        # nix eval fix (wrap outPath as a derivation)
        packages =
          customPackages
          // {
            gruvboxWallpaperOutPath = pkgs.writeText "gruvbox-wallpaper-outPath" inputs.gruvbox-wallpaper.outPath;
          };

        apps = {
          rebuild = mkApp "rebuild" [pkgs.coreutils pkgs.git pkgs.nix pkgs.sudo] "Rebuild and switch NixOS for bandit" ''
            set -euo pipefail
            ${repoRootCmd}
            cd "$repo_root"
            /run/current-system/sw/bin/nixos-rebuild switch --flake "$repo_root#${hostname}"
          '';

          home = mkApp "home" [pkgs.coreutils pkgs.git pkgs.nix] "Switch Home Manager for vino@bandit" ''
            set -euo pipefail
            ${repoRootCmd}
            cd "$repo_root"
            ${inputs.home-manager.packages.${system}.home-manager}/bin/home-manager switch --flake "$repo_root#${username}@${hostname}"
          '';

          update = mkApp "update" [pkgs.coreutils pkgs.git pkgs.nix] "Update flake inputs" ''
            set -euo pipefail
            ${repoRootCmd}
            cd "$repo_root"
            nix flake update
          '';

          fmt = mkApp "fmt" [pkgs.coreutils pkgs.git pkgs.treefmt] "Format repo with treefmt" ''
            set -euo pipefail
            ${repoRootCmd}
            cd "$repo_root"
            treefmt
          '';

          check = mkApp "check" [pkgs.coreutils pkgs.git pkgs.nix] "Run flake checks" ''
            set -euo pipefail
            ${repoRootCmd}
            cd "$repo_root"
            nix flake check
          '';

          clean = mkApp "clean" [pkgs.coreutils pkgs.git] "Remove result symlinks and pre-commit artifacts" ''
            set -euo pipefail
            ${repoRootCmd}
            cd "$repo_root"
            rm -f result result-* .pre-commit-config.yaml
          '';
        };

        # Maintenance: static checks + eval targets
        checks = {
          pre-commit = preCommit;
          nixos-bandit = self.nixosConfigurations.${hostname}.config.system.build.toplevel;
          home-vino = self.homeConfigurations."${username}@${hostname}".activationPackage;
        };

        # Optional: Flask dev shell (use later with: nix develop .#flask)
        devShells = {
          maintenance = maintenanceShell;
          default = maintenanceShell;

          flask = pkgs.mkShell {
            packages = with pkgs; [
              python3
              python3Packages.flask
              python3Packages.virtualenv
            ];
          };

          pentest = pkgs.mkShell rec {
            stickyKeysSlayer = pkgs.stdenvNoCC.mkDerivation {
              pname = "sticky-keys-slayer";
              version = "git-2025-01-06";
              src = pkgs.fetchFromGitHub {
                owner = "linuz";
                repo = "Sticky-Keys-Slayer";
                rev = "0b431ac9909a3f7f47a31c02d8602a52d3a7006d";
                sha256 = "sha256-rzdZArHwv8gAEvOGE4RdPnRXQ6hDGggG6eryM+if2cE=";
              };
              buildInputs = [pkgs.makeWrapper];
              installPhase = ''
                mkdir -p $out/bin
                install -m755 stickyKeysSlayer.sh $out/bin/sticky-keys-slayer
                wrapProgram $out/bin/sticky-keys-slayer --prefix PATH : ${
                  pkgs.lib.makeBinPath [
                    pkgs.imagemagick
                    pkgs.xdotool
                    pkgs.parallel
                    pkgs.bc
                    pkgs.rdesktop
                  ]
                }
              '';
            };
            packages =
              (with pkgs; [
                # Recon / scanning
                nmap
                masscan
                rustscan
                amass
                subfinder
                httpx
                feroxbuster
                gobuster
                whatweb
                nikto
                # Web app / exploit
                sqlmap
                commix
                metasploit
                exploitdb
                zap
                ffuf
                wfuzz
                wpscan
                # Creds / crypto
                hashcat
                john
                hydra
                medusa
                hashcat-utils
                hashpump
                # Network tooling
                mitmproxy
                tcpdump
                wireshark
                socat
                netcat-openbsd
                # Reversing / binaries
                radare2
                cutter
                gdb
                binwalk
                capstone
                ghidra
                # Wireless
                aircrack-ng
                kismet
                hcxdumptool
                hcxtools
                # Wordlists
                seclists
              ])
              ++ [stickyKeysSlayer];
          };
        };
      };

      flake = {
        nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
          inherit system;

          # Make `inputs`, `username`, `hostname` available to modules that want them.
          specialArgs = commonSpecialArgs;

          modules = [
            {
              nixpkgs = {
                config.allowUnfree = true;
                overlays = [overlays.default];
              };
            }

            # Framework hardware module (adjust if you switch models)
            nixos-hardware.nixosModules.framework-13-7040-amd
            # nixos-hardware.nixosModules.framework-amd-ai-300-series
            ./nixos/hosts/${hostname}

            stylix.nixosModules.stylix
            sops-nix.nixosModules.sops

            # Centralized Stylix config (imported via nixos/configuration.nix)

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-bak";

                # Pass the same extra args into Home Manager modules.
                extraSpecialArgs = commonSpecialArgs;

                # Provide nixvim's Home Manager module to all HM users.
                sharedModules = hmSharedModules;

                users.${username} = import ./home-manager/home.nix;
              };
            }
          ];
        };

        # Useful: run `home-manager switch --flake .#vino@bandit` without rebuilding the whole OS
        homeConfigurations."${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;

          extraSpecialArgs = commonSpecialArgs;

          modules = hmSharedModulesHM ++ [./home-manager/home.nix];
        };

        nixosModules = {
          stylix-common = ./modules/shared/stylix-common.nix;
          stylix-nixos = ./modules/nixos/stylix-nixos.nix;
        };

        homeModules = {
          firefox = ./modules/home-manager/firefox.nix;
          i3 = ./modules/home-manager/i3.nix;
          i3blocks = ./modules/home-manager/i3blocks.nix;
          lnav = ./modules/home-manager/lnav.nix;
          nixvim = ./modules/home-manager/nixvim.nix;
          polybar = ./modules/home-manager/polybar.nix;
        };

        inherit overlays;
      };
    });
}
