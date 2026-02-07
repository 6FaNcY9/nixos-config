{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  cfgLib = import ../lib {inherit lib;};

  # Secret file paths
  githubMcpSecretFile = "${inputs.self}/secrets/github-mcp.yaml";
  gpgSigningKeyFile = "${inputs.self}/secrets/gpg-signing-key.yaml";

  # Validate secrets at build time
  validateAllSecrets =
    cfgLib.validateSecretExists githubMcpSecretFile
    && cfgLib.validateSecretEncrypted githubMcpSecretFile
    && cfgLib.validateSecretExists gpgSigningKeyFile
    && cfgLib.validateSecretEncrypted gpgSigningKeyFile;
in {
  # Trigger validation
  assertions = [
    {
      assertion = validateAllSecrets;
      message = "Secret validation passed";
    }
  ];

  # sops-nix Home Manager defaults (kept minimal)
  sops = {
    age.keyFile = lib.mkDefault "${config.xdg.configHome}/sops/age/keys.txt";

    secrets.github_mcp_pat = {
      sopsFile = githubMcpSecretFile;
      format = "yaml";
    };

    secrets.gpg_signing_key = {
      sopsFile = gpgSigningKeyFile;
      key = "gpg_private_key";
      format = "yaml";
    };
  };

  home.activation.importGpgKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import ${config.sops.secrets.gpg_signing_key.path}
  '';
}
