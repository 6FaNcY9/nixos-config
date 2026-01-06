# flake.nix (keep on SSD at: nixos-config/flake.nix)
{
  description = "Framework 13 AMD: NixOS 25.11 + i3 + XFCE services + Home Manager + Stylix Gruvbox";

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

  outputs =
  {
    self,
    nixpkgs,
    nixos-hardware,
    home-manager,
    nixvim,
    stylix,
    ...
  }@inputs:
  let
    system = "x86_64-linux";
    hostname = "bandit";
    username = "vino";
    commonSpecialArgs = { inherit inputs username hostname; };
    hmSharedModules = [
      inputs.nixvim.homeModules.nixvim
      inputs.stylix.homeModules.stylix
      ./modules/stylix-common.nix
    ];
    hmUserModules = hmSharedModules ++ [ ./home.nix ];

  # IMPORTANT:
  # - This pkgs is used by 'homeConfigurations' and 'devShells'.
  # - Your home.nix includes 'pkgs.vscode'(unfree) so allowUnfree must be enabled here.
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in
  {
    nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
      inherit system;

      # Make `inputs`, `username`, `hostname` available to modules that want them.
      specialArgs = commonSpecialArgs;

      modules = [
        # Framework hardware module (adjust if you switch models)
        nixos-hardware.nixosModules.framework-13-7040-amd
        # nixos-hardware.nixosModules.framework-amd-ai-300-series
        ./hardware-configuration.nix
        ./configuration.nix

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

      modules = hmUserModules;
    };

    # Optional: `nix fmt`
    formatter.${system} = pkgs.alejandra;

    # Optional: Flask dev shell (use later with: nix develop .#flask)
    devShells.${system}.flask = pkgs.mkShell {
      packages = with pkgs; [
        python3
        python3Packages.flask
        python3Packages.virtualenv
      ];
    };
  };
}
