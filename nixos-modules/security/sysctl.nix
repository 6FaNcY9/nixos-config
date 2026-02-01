# Module: security/sysctl.nix
# Purpose: Centralized kernel parameter (sysctl) configuration
#
# Features:
#   - Security hardening parameters (network, memory)
#   - Development-friendly settings (inotify limits)
#   - Reusable across roles (desktop, laptop, server)
#
# Options:
#   - security.hardenedSysctl.enable: Enable security hardening
#   - security.hardenedSysctl.networkHardening: Network security params
#   - development.sysctlTweaks.enable: Development-friendly tweaks
{
  lib,
  config,
  ...
}: {
  options = {
    security.hardenedSysctl = {
      enable = lib.mkEnableOption "hardened kernel parameters";

      networkHardening = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable network security hardening:
          - Disable IP forwarding
          - Enable reverse path filtering (anti-spoofing)
          - Disable ICMP redirects
          - Enable SYN cookies (anti-DDoS)
        '';
      };
    };

    development.sysctlTweaks = {
      enable = lib.mkEnableOption "development-friendly kernel parameters";

      maxFileWatchers = lib.mkOption {
        type = lib.types.int;
        default = 524288;
        description = "Maximum file watchers for inotify (large projects, IDEs)";
      };

      maxWatcherInstances = lib.mkOption {
        type = lib.types.int;
        default = 1024;
        description = "Maximum inotify instances per user";
      };
    };
  };

  config = lib.mkMerge [
    # Security hardening sysctl settings
    (lib.mkIf config.security.hardenedSysctl.enable {
      boot.kernel.sysctl = lib.mkMerge [
        # Network hardening (enabled by default)
        (lib.mkIf config.security.hardenedSysctl.networkHardening {
          # Disable IP forwarding (not a router)
          "net.ipv4.ip_forward" = lib.mkDefault 0;
          "net.ipv6.conf.all.forwarding" = lib.mkDefault 0;

          # Enable reverse path filtering (prevent IP spoofing)
          # This validates incoming packets against routing table
          "net.ipv4.conf.all.rp_filter" = 1;
          "net.ipv4.conf.default.rp_filter" = 1;

          # Enable SYN cookies (protection against SYN flood attacks)
          "net.ipv4.tcp_syncookies" = 1;

          # Disable ICMP redirects (prevent MITM attacks)
          "net.ipv4.conf.all.accept_redirects" = 0;
          "net.ipv4.conf.default.accept_redirects" = 0;
          "net.ipv6.conf.all.accept_redirects" = 0;
          "net.ipv6.conf.default.accept_redirects" = 0;

          # Disable sending ICMP redirects (we're not a router)
          "net.ipv4.conf.all.send_redirects" = 0;
          "net.ipv4.conf.default.send_redirects" = 0;

          # Ignore ICMP ping requests (optional stealth)
          # "net.ipv4.icmp_echo_ignore_all" = 1;
        })
      ];
    })

    # Development tweaks
    (lib.mkIf config.development.sysctlTweaks.enable {
      boot.kernel.sysctl = {
        # Increase inotify limits for large projects (node_modules, etc.)
        # Default: 8192 watchers, often insufficient for modern IDEs
        "fs.inotify.max_user_watches" = config.development.sysctlTweaks.maxFileWatchers;
        "fs.inotify.max_user_instances" = config.development.sysctlTweaks.maxWatcherInstances;
      };
    })
  ];
}
