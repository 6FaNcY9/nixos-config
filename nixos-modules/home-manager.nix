{
  inputs,
  username ? "vino",
  repoRoot ? "/home/${username}/src/nixos-config-ez",
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = {
      inherit inputs username repoRoot;
    };
  };
}
