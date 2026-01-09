{
  config,
  lib,
  ...
}: {
  # sops-nix Home Manager defaults (kept minimal)
  sops.age.keyFile = lib.mkDefault "${config.xdg.configHome}/sops/age/keys.txt";
}
