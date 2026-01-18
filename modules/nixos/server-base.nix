{
  lib,
  config,
  ...
}: {
  options.server = {
    base.enable = lib.mkEnableOption "baseline server hardening";

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

  config = lib.mkIf config.server.base.enable {
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

    boot.kernel.sysctl = {
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
    };

    networking.nftables.enable = true;
  };
}
