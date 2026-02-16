# Bridge NixOS-level args into Home Manager modules.
# `extraSpecialArgs` makes these available as top-level args in every file
# under home-modules/ (e.g. `{ repoRoot, username, inputs, ... }:`).
{
  inputs,
  username,
  repoRoot,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = {
      inherit inputs username repoRoot;
    };
  };
}
