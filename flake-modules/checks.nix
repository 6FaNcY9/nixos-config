# Build checks — verify NixOS and Home Manager configurations build correctly.
#
# Derived automatically from self.nixosConfigurations and self.homeConfigurations
# so new hosts/users are exercised by `nix flake check` without manual edits here.
#
# Run with: nix flake check

{
  self,
  lib,
  ...
}:
{
  perSystem = _: {
    # Static checks + evaluation targets
    # These ensure configurations can be built without actually deploying
    checks =
      lib.mapAttrs' (
        name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel
      ) self.nixosConfigurations
      // lib.mapAttrs' (
        name: cfg: lib.nameValuePair "home-${lib.replaceStrings [ "@" ] [ "-" ] name}" cfg.activationPackage
      ) self.homeConfigurations;
  };
}
