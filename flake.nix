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
        customPackages = import ./pkgs {};
        missionControlWrapper = config.mission-control.wrapper;
        maintenancePackages = [pkgs.pre-commit pkgs.nix missionControlWrapper] ++ config.pre-commit.settings.enabledPackages;

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

        devshells = {
          maintenance = {
            packages = maintenancePackages;
            devshell.motd = "{202}🔨 Welcome to devshell{reset}\nRun ',' for mission-control commands.";
          };
          default = {
            packages = maintenancePackages;
            devshell.motd = "{202}🔨 Welcome to devshell{reset}\nRun ',' for mission-control commands.";
          };
          flask = {
            packages = with pkgs; [
              missionControlWrapper
              python3
              python3Packages.flask
              python3Packages.virtualenv
            ];
            devshell.motd = "{202}🔨 Welcome to devshell{reset}\nRun ',' for mission-control commands.";
          };
          pentest = {
            packages =
              (with pkgs; [
                missionControlWrapper
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
            devshell.motd = "{202}🔨 Welcome to devshell{reset}\nRun ',' for mission-control commands.";
          };
        };
      };

      flake = {
        inherit overlays;
      };
    });
}
