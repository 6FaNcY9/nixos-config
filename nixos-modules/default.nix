{ inputs, lib, ... }:
{
  imports = [
    # External modules
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops

    # Shared modules
    ../shared-modules/stylix-common.nix

    # ===== NEW MODULES (active) =====
    ./core # Core system modules (nix, users, networking, programs, packages, fonts)
    ./features # Optional feature modules
    # ./profiles # Removed: empty stub, will be added when bundles are created
  ];

  _module.args.cfgLib = import ../lib { inherit lib; };
}
