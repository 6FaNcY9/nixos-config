# Feature: Secrets Management
# Provides: sops-nix integration for encrypted secrets
# Dependencies: None
{
  config,
  lib,
  inputs,
  username,
  cfgLib,
  ...
}:
let
  cfg = config.features.security.secrets;
  userHome = config.users.users.${username}.home;

  # Secret file paths
  githubSecretFile = "${inputs.self}/secrets/github.yaml";
  cloudflareSecretFile = "${inputs.self}/secrets/cloudflare.yaml";

  secretValidation = cfgLib.mkSecretValidation {
    secrets = [
      githubSecretFile
    ]
    ++ lib.optionals config.features.services.cloudflared.enable [
      cloudflareSecretFile
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
        sshKeyPaths = [ ]; # Explicit empty: do not derive age key from SSH host key (avoids coupling secret decryption to host key rotation)
        generateKey = lib.mkDefault true; # Auto-generate age key if missing
      };

      secrets."github_ssh_key" = {
        sopsFile = githubSecretFile;
        owner = username;
        mode = "0600";
        path = "${userHome}/.ssh/github";
      };

      secrets."cloudflare_tunnel_token" = lib.mkIf config.features.services.cloudflared.enable {
        sopsFile = cloudflareSecretFile;
        owner = "cloudflared";
        group = "cloudflared";
        mode = "0400";
      };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/sops-nix 0700 root root -"
      "d ${userHome}/.ssh 0700 ${username} users -"
    ];
  };
}
