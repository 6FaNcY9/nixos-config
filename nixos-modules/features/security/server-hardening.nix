# Feature: Server Hardening
# Provides: Baseline server security (fail2ban, sysctl, nftables)
# Dependencies: features.services.openssh (for SSH hardening)
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.security.server-hardening;
in
{
  options.features.security.server-hardening = {
    enable = lib.mkEnableOption "baseline server hardening (fail2ban, sysctl, nftables)";

    ssh.allowUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Restrict SSH login to these users (empty = allow all).";
    };

    fail2ban.ignoreIP = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "127.0.0.1/8"
        "::1"
      ];
      description = "IP ranges to ignore for fail2ban.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Fail2ban for brute force protection
    services.fail2ban = {
      enable = true;
      inherit (cfg.fail2ban) ignoreIP;
      jails.sshd = ''
        enabled = true
        mode = aggressive
      '';
    };

    # SSH user restrictions (if specified)
    services.openssh.settings.AllowUsers = lib.mkIf (cfg.ssh.allowUsers != [ ]) cfg.ssh.allowUsers;

    # Kernel hardening via sysctl
    boot.kernel.sysctl = {
      # Enable reverse path filtering - validates source addresses (prevents IP spoofing attacks)
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;

      # Enable SYN cookies - protects against SYN flood DoS attacks
      "net.ipv4.tcp_syncookies" = 1;

      # Disable ICMP redirects - prevents MITM attacks via malicious route injection
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;

      # Disable sending ICMP redirects (server should not suggest alternate routes)
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
    };

    # Use nftables instead of iptables
    networking.nftables.enable = true;
  };
}
