# Feature: Secrets Management
# Provides: sops-nix integration for encrypted secrets
# Dependencies: None
{
  config,
  lib,
  inputs,
  username,
  ...
}:
let
  cfg = config.features.security.secrets;
  userHome = config.users.users.${username}.home;
  cfgLib = import ../../../lib { inherit lib; };

  # Secret file paths
  githubSecretFile = "${inputs.self}/secrets/github.yaml";
  resticSecretFile = "${inputs.self}/secrets/restic.yaml";

  secretValidation = cfgLib.mkSecretValidation {
    secrets = [
      githubSecretFile
      resticSecretFile
    ];
    label = "System";
  };
in
{
  options.features.security.secrets = {
    enable = lib.mkEnableOption "sops-nix secrets management";
  };

  config = lib.mkIf cfg.enable {
    inherit (secretValidation) assertions;

    # sops-nix system defaults - configures age-based encryption for secrets
    sops = {
      age = {
        keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt"; # age encryption key location
        sshKeyPaths = lib.mkDefault [ "/etc/ssh/ssh_host_ed25519_key" ]; # Fallback SSH key
        generateKey = lib.mkDefault true; # Auto-generate age key if missing
      };

      secrets."github_ssh_key" = {
        sopsFile = githubSecretFile;
        owner = username;
        mode = "0600";
        path = "${userHome}/.ssh/github";
      };

      secrets."restic_password" = {
        sopsFile = resticSecretFile;
        key = "password";
        owner = "root";
        mode = "0400";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/sops-nix 0700 root root -"
      "d ${userHome}/.ssh 0700 ${username} users -"
    ];
  };
}
