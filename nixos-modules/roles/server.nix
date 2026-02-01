# Server role - headless defaults + optional hardening
{
  lib,
  config,
  ...
}: {
  options.server = {
    hardening = lib.mkEnableOption "baseline server hardening (fail2ban, sysctl, nftables)";

    ssh.allowUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Restrict SSH login to these users (empty = allow all).";
    };

    fail2ban.ignoreIP = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["127.0.0.1/8" "::1"];
      description = "IP ranges to ignore for fail2ban.";
    };
  };

  config = lib.mkMerge [
    # Base server role
    (lib.mkIf config.roles.server {
      # Server role defaults: prefer headless unless explicitly overridden
      roles.desktop = lib.mkDefault false;

      services.openssh.enable = lib.mkDefault true;
    })

    # Server hardening (opt-in)
    (lib.mkIf config.server.hardening {
      services.fail2ban = {
        enable = true;
        inherit (config.server.fail2ban) ignoreIP;
        jails.sshd = ''
          enabled = true
          mode = aggressive
        '';
      };

      services.openssh.settings.AllowUsers =
        lib.mkIf (config.server.ssh.allowUsers != []) config.server.ssh.allowUsers;

      # Network security hardening via centralized sysctl module
      security.hardenedSysctl = {
        enable = true;
        networkHardening = true;
      };

      # Use nftables instead of legacy iptables
      networking.nftables.enable = true;
    })
  ];
}
