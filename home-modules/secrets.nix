{
  config,
  lib,
  inputs,
  ...
}: {
  # sops-nix Home Manager defaults (kept minimal)
  sops.age.keyFile = lib.mkDefault "${config.xdg.configHome}/sops/age/keys.txt";

  sops.secrets.github_mcp_pat = {
    sopsFile = "${inputs.self}/secrets/github-mcp.yaml";
    format = "yaml";
  };
}
