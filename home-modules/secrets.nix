{
  config,
  lib,
  inputs,
  ...
}: let
  cfgLib = import ../lib {inherit lib;};

  # Secret file paths
  githubMcpSecretFile = "${inputs.self}/secrets/github-mcp.yaml";

  # Validate secrets at build time
  validateAllSecrets =
    cfgLib.validateSecretExists githubMcpSecretFile
    && cfgLib.validateSecretEncrypted githubMcpSecretFile;
in {
  # Trigger validation
  assertions = [
    {
      assertion = validateAllSecrets;
      message = "Secret validation passed";
    }
  ];

  # sops-nix Home Manager defaults (kept minimal)
  sops.age.keyFile = lib.mkDefault "${config.xdg.configHome}/sops/age/keys.txt";

  sops.secrets.github_mcp_pat = {
    sopsFile = githubMcpSecretFile;
    format = "yaml";
  };
}
