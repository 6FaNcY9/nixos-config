# sops-nix Home Manager secret management
# sops-nix Home Manager secret management
# Manages encrypted secrets for: GitHub MCP PAT, GPG signing key, Cachix auth, Exa API, Context7 API, Mistral API, Hermes env
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
  heliconeSecretFile = "${inputs.self}/secrets/helicone.yaml";
  mistralClaudeSecretFile = "${inputs.self}/secrets/mistral-claude.yaml";
  hermesSecretFile = "${inputs.self}/secrets/hermes.yaml";

  secretValidation = cfgLib.mkSecretValidation {
    secrets = builtins.filter builtins.pathExists [
      gpgSigningKeyFile
      cachixSecretFile

      githubMcpSecretFile
      exaApiSecretFile
      context7SecretFile
      mistralSecretFile
      mistralClaudeSecretFile

      heliconeSecretFile
      hermesSecretFile
    ];
    label = "Home";
  };
in
{
  inherit (secretValidation) assertions;

  # sops-nix Home Manager defaults (kept minimal)
  sops = {
    age.keyFile = lib.mkDefault "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = lib.mkMerge (
      lib.optional (builtins.pathExists githubMcpSecretFile) {
        github_mcp_pat = {
          sopsFile = githubMcpSecretFile;
          format = "yaml";
          mode = "0400"; # read-only for owner; loaded into env via fish interactiveShellInit
        };
      }
      ++ lib.optional (builtins.pathExists gpgSigningKeyFile) {
        gpg_signing_key = {
          sopsFile = gpgSigningKeyFile;
          key = "gpg_private_key";
          format = "yaml";
          mode = "0400"; # read-only for owner; imported once by home.activation.importGpgKey
        };
      }
      ++ lib.optional (builtins.pathExists cachixSecretFile) {
        cachix_auth_token = {
          sopsFile = cachixSecretFile;
          key = "cachix_auth_token";
          format = "yaml";
          mode = "0400"; # read-only for owner; used by cachix CLI and pre-commit hook
        };
      }
      ++ lib.optional (builtins.pathExists exaApiSecretFile) {
        exa_api_key = {
          sopsFile = exaApiSecretFile;
          format = "yaml";
          mode = "0400"; # read-only for owner; loaded into env via fish interactiveShellInit
        };
      }
      ++ lib.optional (builtins.pathExists context7SecretFile) {
        context7_api_key = {
          sopsFile = context7SecretFile;
          format = "yaml";
          mode = "0400"; # read-only for owner; loaded into env via fish interactiveShellInit
        };
      }
      ++ lib.optional (builtins.pathExists mistralSecretFile) {
        mistral_api_key = {
          sopsFile = mistralSecretFile;
          format = "yaml";
          mode = "0400"; # read-only for owner; loaded into env by consumers
        };
      }
      ++ lib.optional (builtins.pathExists mistralClaudeSecretFile) {
        mistral_claude_api_key = {
          sopsFile = mistralClaudeSecretFile;
          format = "yaml";
          mode = "0400"; # read-only for owner; loaded into env by consumers
        };
      }
      ++ lib.optional (builtins.pathExists heliconeSecretFile) {
        helicone_api_key = {
          sopsFile = heliconeSecretFile;
          format = "yaml";
          mode = "0400"; # read-only for owner; loaded into env via fish interactiveShellInit
        };
      }
      ++ lib.optional (builtins.pathExists hermesSecretFile) {
        hermes_env = {
          sopsFile = hermesSecretFile;
          # key defaults to "hermes_env" matching the yaml top-level key
          format = "yaml";
          mode = "0400"; # read-only; copied to ~/.hermes/.env by hermes activation
        };
      }
    );
  };

  # Import GPG key after sops-nix has decrypted secrets
  # Only declared when gpg secret file exists on this host
  home.activation = lib.mkIf (builtins.pathExists gpgSigningKeyFile) {
    importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" "reloadSystemd" ] ''
      SECRET_PATH="${config.sops.secrets.gpg_signing_key.path}"
      if [ -f "$SECRET_PATH" ]; then
        echo "Importing GPG signing key..."
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "$SECRET_PATH" 2>/dev/null || echo "GPG key already imported or import failed (non-fatal)"
      else
        echo "GPG signing key secret not yet available, skipping import"
      fi
    '';
  };
}
