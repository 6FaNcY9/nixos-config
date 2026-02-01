{
  lib,
  inputs,
  username,
  ...
}: let
  cfgLib = import ../lib {inherit lib;};

  # Secret file paths
  githubSecretFile = "${inputs.self}/secrets/github.yaml";
  resticSecretFile = "${inputs.self}/secrets/restic.yaml";

  # Validate secrets at build time
  validateAllSecrets =
    cfgLib.validateSecretExists githubSecretFile
    && cfgLib.validateSecretEncrypted githubSecretFile
    && cfgLib.validateSecretExists resticSecretFile
    && cfgLib.validateSecretEncrypted resticSecretFile;
in {
  # Trigger validation
  assertions = [
    {
      assertion = validateAllSecrets;
      message = "Secret validation passed";
    }
  ];

  # sops-nix system defaults (safe even without secrets defined)
  sops = {
    age = {
      keyFile = lib.mkDefault "/var/lib/sops-nix/key.txt";
      sshKeyPaths = lib.mkDefault ["/etc/ssh/ssh_host_ed25519_key"];
      generateKey = lib.mkDefault true;
    };

    secrets."github_ssh_key" = {
      sopsFile = githubSecretFile;
      owner = username;
      mode = "0600";
      path = "/home/${username}/.ssh/github";
    };

    secrets."restic_password" = {
      sopsFile = resticSecretFile;
      key = "password";
      owner = "root";
      mode = "0600";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/sops-nix 0700 root root -"
    "d /home/${username}/.ssh 0700 ${username} users -"
  ];
}
