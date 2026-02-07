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
  cachixSecretFile = "${inputs.self}/secrets/cachix.yaml";

  # Validate secrets at build time
  validateAllSecrets =
    cfgLib.validateSecretExists githubMcpSecretFile
    && cfgLib.validateSecretEncrypted githubMcpSecretFile
    && cfgLib.validateSecretExists gpgSigningKeyFile
    && cfgLib.validateSecretEncrypted gpgSigningKeyFile
    && cfgLib.validateSecretExists cachixSecretFile
    && cfgLib.validateSecretEncrypted cachixSecretFile;
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

    secrets = {
      github_mcp_pat = {
        sopsFile = githubMcpSecretFile;
        format = "yaml";
      };

      gpg_signing_key = {
        sopsFile = gpgSigningKeyFile;
        key = "gpg_private_key";
        format = "yaml";
      };

      cachix_auth_token = {
        sopsFile = cachixSecretFile;
        key = "cachix_auth_token";
        format = "yaml";
      };
    };
  };

  # Import GPG key after sops-nix has decrypted secrets
  # Non-fatal: only imports if the secret exists
  home.activation.importGpgKey = lib.hm.dag.entryAfter ["writeBoundary" "reloadSystemd"] ''
    SECRET_PATH="${config.sops.secrets.gpg_signing_key.path}"
    if [ -f "$SECRET_PATH" ]; then
      echo "Importing GPG signing key..."
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "$SECRET_PATH" 2>/dev/null || echo "GPG key already imported or import failed (non-fatal)"
    else
      echo "GPG signing key secret not yet available, skipping import"
    fi
  '';
}
