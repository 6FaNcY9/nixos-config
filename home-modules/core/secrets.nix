# sops-nix Home Manager secret management
# Manages encrypted secrets for: GitHub MCP PAT, GPG signing key, Cachix auth, Exa API, Context7 API, Mistral API
# GPG signing key is auto-imported via home.activation hook after decryption
#
{
  config,
  lib,
  inputs,
  pkgs,
  cfgLib,
  ...
}:
let
  # Secret file paths
  githubMcpSecretFile = "${inputs.self}/secrets/github-mcp.yaml";
  gpgSigningKeyFile = "${inputs.self}/secrets/gpg-signing-key.yaml";
  cachixSecretFile = "${inputs.self}/secrets/cachix.yaml";
  exaApiSecretFile = "${inputs.self}/secrets/exa-api.yaml";
  context7SecretFile = "${inputs.self}/secrets/context7-api.yaml";
  mistralSecretFile = "${inputs.self}/secrets/mistral.yaml";

  secretValidation = cfgLib.mkSecretValidation {
    secrets = [
      githubMcpSecretFile
      gpgSigningKeyFile
      cachixSecretFile
      exaApiSecretFile
      context7SecretFile
      mistralSecretFile
    ];
    label = "Home";
  };
in
{
  inherit (secretValidation) assertions;

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

      exa_api_key = {
        sopsFile = exaApiSecretFile;
        format = "yaml";
      };

      context7_api_key = {
        sopsFile = context7SecretFile;
        format = "yaml";
      };

      mistral_api_key = {
        sopsFile = mistralSecretFile;
        format = "yaml";
      };
    };
  };

  # Import GPG key after sops-nix has decrypted secrets
  # Non-fatal: only imports if the secret exists
  home.activation.importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" "reloadSystemd" ] ''
    SECRET_PATH="${config.sops.secrets.gpg_signing_key.path}"
    if [ -f "$SECRET_PATH" ]; then
      echo "Importing GPG signing key..."
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "$SECRET_PATH" 2>/dev/null || echo "GPG key already imported or import failed (non-fatal)"
    else
      echo "GPG signing key secret not yet available, skipping import"
    fi
  '';
}
