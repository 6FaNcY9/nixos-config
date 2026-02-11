{
  self,
  primaryHost,
  username,
  ...
}: {
  perSystem = {
    ...
  }: {
    # Maintenance: static checks + eval targets
    checks = {
      nixos-bandit = self.nixosConfigurations.${primaryHost}.config.system.build.toplevel;
      home-vino = self.homeConfigurations."${username}@${primaryHost}".activationPackage;
    };
  };
}
