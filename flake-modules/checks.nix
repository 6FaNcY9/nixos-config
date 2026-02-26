# Build checks — verify NixOS and Home Manager configurations build correctly.
#
# Checks:
#   nixos-bandit — NixOS system.build.toplevel (full system configuration)
#   home-vino    — Home Manager activationPackage (user environment)
#
# Run with: nix flake check

{
  self,
  primaryHost,
  username,
  ...
}:
{
  perSystem = _: {
    # Static checks + evaluation targets
    # These ensure configurations can be built without actually deploying
    checks = {
      nixos-bandit = self.nixosConfigurations.${primaryHost}.config.system.build.toplevel;
      home-vino = self.homeConfigurations."${username}@${primaryHost}".activationPackage;
    };
  };
}
