# flake.nix (keep on SSD at: nixos-config/flake.nix)
{
  description = "Framework 13 AMD: NixOS 25.11 + i3 + XFCE services + Home Manager + Stylix Gruvbox";

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
  };

  inputs = {
    # Stable 25.11
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

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

    # Wallpaper
    gruvbox-wallpaper.url = "github:AngelJumbo/gruvbox-wallpapers";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    home-manager,
    nixvim,
    stylix,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    hostname = "bandit";
    username = "vino";
    commonSpecialArgs = {inherit inputs username hostname;};
    # Shared HM modules used inside the NixOS system build (Stylix is on the NixOS side)
    hmSharedModules = [
      inputs.nixvim.homeModules.nixvim
    ];

    # Standalone Home Manager output includes Stylix modules
    hmSharedModulesHM =
      hmSharedModules
      ++ [
        inputs.stylix.homeModules.stylix
        ./modules/stylix-common.nix
      ];

    hmUserModules = hmSharedModules ++ [./home.nix];

    # IMPORTANT:
    # - This pkgs is used by 'homeConfigurations' and 'devShells'.
    # - Your home.nix includes 'pkgs.vscode'(unfree) so allowUnfree must be enabled here.
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    maintenanceShell = pkgs.mkShell {
      packages = with pkgs; [
        alejandra
        deadnix
        statix
        nix
      ];
    };
  in {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      inherit system;

      # Make `inputs`, `username`, `hostname` available to modules that want them.
      specialArgs = commonSpecialArgs;

      modules = [
        {nixpkgs.config.allowUnfree = true;}

        # Framework hardware module (adjust if you switch models)
        nixos-hardware.nixosModules.framework-13-7040-amd
        # nixos-hardware.nixosModules.framework-amd-ai-300-series
        ./hosts/${hostname}

        stylix.nixosModules.stylix

        # Centralized Stylix config:
        ./modules/stylix-common.nix
        ./modules/stylix-nixos.nix

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.backupFileExtension = "hm-bak";

          # Pass the same extra args into Home Manager modules.
          home-manager.extraSpecialArgs = commonSpecialArgs;

          # Provide nixvim's Home Manager module to all HM users.
          home-manager.sharedModules = hmSharedModules;

          home-manager.users.${username} = import ./home.nix;
        }
      ];
    };

    # Useful: run `home-manager switch --flake /etc/nixos#vino` without rebuilding the whole OS
    homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = commonSpecialArgs;

      modules = hmSharedModulesHM ++ [./home.nix];
    };

    # Optional: `nix fmt`
    formatter.${system} = pkgs.alejandra;

    nixosModules = {
      stylix-common = ./modules/stylix-common.nix;
      stylix-nixos = ./modules/stylix-nixos.nix;
      profiles-base = ./profiles/base.nix;
    };

    homeManagerModules = {
      firefox = ./home/firefox.nix;
      i3 = ./home/i3.nix;
      i3blocks = ./home/i3blocks.nix;
      nixvim = ./home/nixvim.nix;
      polybar = ./home/polybar.nix;
    };

    # Maintenance: static checks + eval targets
    checks.${system} = {
      nixos-bandit = self.nixosConfigurations.${hostname}.config.system.build.toplevel;
      home-vino = self.homeConfigurations.${username}.activationPackage;
    };

    # nix eval fix (wrap outPath as a derivation)
    packages.${system}.gruvboxWallpaperOutPath = pkgs.writeText "gruvbox-wallpaper-outPath" inputs.gruvbox-wallpaper.outPath;

    # Optional: Flask dev shell (use later with: nix develop .#flask)
    devShells.${system} = {
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

        #shell prompt
        # shellHook = ''
        #   export STARSHIP_CONFIG="${TMPDIR:-/tmp}/starship-pentest.toml"
        #   mkdir -p "$(dirname "$STARSHIP_CONFIG")"
        #   cat >"$STARSHIP_CONFIG" <<'EOF'
        #   format = """$username$hostname$directory$git_branch$git_status$custom_ip$nix_shell$cmd_duration$character"""
        #
        #   [username]
        #   format = "[$user](bold green)@"
        #   show_always = true
        #
        #   [hostname]
        #   ssh_only = false
        #   format = "[$hostname](bold red) "
        #
        #   [directory]
        #   style = "bold cyan"
        #   truncation_length = 3
        #
        #   [git_branch]
        #   format = " $branch "
        #   style = "bold purple"
        #
        #   [git_status]
        #   format = "[$all_status$ahead_behind]($style) "
        #   style = "yellow"
        #
        #   [nix_shell]
        #   format = "[$state](bold blue) "
        #   disabled = false
        #
        #   [cmd_duration]
        #   min_time = 500
        #   format = "[⏱ $duration](bold yellow) "
        #
        #   [custom.ip]
        #   command = "ip -4 -o addr show scope global | awk '{split($4,a,\"/\"); print a[1]; exit}'"
        #   when = "ip -4 -o addr show scope global >/dev/null 2>&1"
        #   style = "bold yellow"
        #   format = "[$output](bold yellow) "
        #   EOF
        # '';
      };
    };
  };
}
