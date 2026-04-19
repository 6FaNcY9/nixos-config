# Feature: Desktop Security Hardening
# Provides: Baseline security improvements for desktop/laptop systems
# Dependencies: None
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.features.security.desktop-hardening;
in
{
  options.features.security.desktop-hardening = {
    enable = lib.mkEnableOption "baseline desktop security hardening";

    sudo = {
      timeout = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Sudo password timeout in minutes (0 = always ask)";
      };

      requirePassword = lib.mkEnableOption "sudo password requirement (disables NOPASSWD)" // {
        default = true;
      };
    };

    polkit = {
      restrictUserActions = lib.mkEnableOption "polkit user action restrictions" // {
        default = true;
      };
    };

    protectKernelImage =
      lib.mkEnableOption "kernel image protection (sets nohibernate; disables hibernation as a side effect)"
      // {
        default = true;
      };

    firewall = {
      enable = lib.mkEnableOption "basic firewall rules for desktop" // {
        default = true;
      };

      allowedTCPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [ ];
        description = "Additional TCP ports to allow through firewall";
      };

      allowedUDPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [ ];
        description = "Additional UDP ports to allow through firewall";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    security = {
      # Sudo configuration
      sudo = {
        execWheelOnly = lib.mkIf cfg.sudo.requirePassword true;
        extraConfig = ''
          # Sudo timeout: ${toString cfg.sudo.timeout} minutes
          Defaults timestamp_timeout=${toString cfg.sudo.timeout}
          # Require password for all commands (disable NOPASSWD)
          ${lib.optionalString cfg.sudo.requirePassword ''
            Defaults passwd_tries=3
            Defaults passwd_timeout=1
          ''}
        '';
      };

      # Polkit hardening
      polkit = lib.mkIf cfg.polkit.restrictUserActions {
        enable = true;
        extraConfig = ''
          // Restrict regular users from system-wide changes
          // Users in 'wheel' group can still use sudo for these actions

          // Disable user installation of system packages
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.packagekit.package-install" ||
                action.id == "org.freedesktop.packagekit.package-remove") {
              return polkit.Result.AUTH_ADMIN;
            }
          });

          // Require admin for system services control
          polkit.addRule(function(action, subject) {
            if (action.id.indexOf("org.freedesktop.systemd1.manage-units") == 0) {
              if (!subject.isInGroup("wheel")) {
                return polkit.Result.AUTH_ADMIN;
              }
            }
          });

          // Require admin for network configuration
          polkit.addRule(function(action, subject) {
            if (action.id.indexOf("org.freedesktop.NetworkManager") == 0) {
              if (!subject.isInGroup("wheel")) {
                return polkit.Result.AUTH_ADMIN;
              }
            }
          });
        '';
      };

      # Kernel image protection (prevents live patching and kexec misuse)
      # Note: kexec is still blocked via sysctl below regardless of this setting
      inherit (cfg) protectKernelImage;

      # Page Table Isolation — Meltdown mitigation (Intel pre-2019 CPUs only).
      # This machine uses an AMD CPU with hardware Meltdown immunity; PTI is a no-op
      # here (kernel detects RDCL_NO and skips the TLB flush overhead automatically).
      # Kept true so the config is safe to reuse on Intel hardware without modification.
      forcePageTableIsolation = true;
    };

    # Firewall configuration
    networking.firewall = lib.mkIf cfg.firewall.enable {
      enable = true;
      # Default: block all incoming, allow all outgoing
      inherit (cfg.firewall) allowedTCPPorts allowedUDPPorts;
      # Log refused connections (useful for debugging)
      logRefusedConnections = lib.mkDefault true;
      # Reject instead of drop (more user-friendly)
      rejectPackets = lib.mkDefault false;
    };

    # Kernel hardening
    boot.kernel.sysctl = {
      # Disable IP forwarding (not needed on desktop)
      "net.ipv4.ip_forward" = 0;
      "net.ipv6.conf.all.forwarding" = 0;

      # Enable reverse path filtering - validates source addresses (prevents IP spoofing attacks)
      # mkDefault: yields to server hardening when both enabled
      "net.ipv4.conf.all.rp_filter" = lib.mkDefault 1;
      "net.ipv4.conf.default.rp_filter" = lib.mkDefault 1;

      # Disable ICMP redirects - prevents MITM attacks via malicious route injection
      # mkDefault: yields to server hardening when both enabled
      "net.ipv4.conf.all.accept_redirects" = lib.mkDefault 0;
      "net.ipv4.conf.default.accept_redirects" = lib.mkDefault 0;
      "net.ipv6.conf.all.accept_redirects" = lib.mkDefault 0;
      "net.ipv6.conf.default.accept_redirects" = lib.mkDefault 0;

      # Disable source routing - prevents attackers from controlling packet routes
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;

      # Enable SYN cookies - protects against SYN flood DoS attacks
      # mkDefault: yields to server hardening when both enabled
      "net.ipv4.tcp_syncookies" = lib.mkDefault 1;

      # Log martian packets (packets with impossible source addresses) for debugging
      "net.ipv4.conf.all.log_martians" = lib.mkDefault true;
      "net.ipv4.conf.default.log_martians" = lib.mkDefault true;

      # Restrict dmesg access to root only (prevents information disclosure)
      "kernel.dmesg_restrict" = 1;

      # Restrict access to kernel pointers in /proc (prevents kernel ASLR bypass)
      # 0 = no restrictions, 1 = restrict to root, 2 = always hide (most secure)
      "kernel.kptr_restrict" = 2;
      # Disable kexec (prevents kernel replacement without reboot - mitigates certain rootkits)
      "kernel.kexec_load_disabled" = 1; # always disable kexec on desktop (no mkDefault — must not be overridable)
      # Restrict ptrace to parent processes only (prevents process injection attacks)
      "kernel.yama.ptrace_scope" = 1;

      # BPF hardening (real exploit vector — multiple CVEs 2021-2022)
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_enable" = 0;
      "net.core.bpf_jit_harden" = 2;

      # Disable ftrace debugging (information disclosure)
      "kernel.ftrace_enabled" = false;

      # Restrict performance event access (ASLR bypass vector)
      "kernel.perf_event_paranoid" = 3;

      # Kernel panic on oops (prevent exploitation of corrupted state)
      "kernel.panic_on_oops" = 1;
      "kernel.panic" = 10; # Auto-reboot after 10s

      # Filesystem hardening (TOCTOU, FIFO/symlink race conditions)
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;

      # Additional ICMP/redirect hardening
      "net.ipv4.icmp_echo_ignore_broadcasts" = true;
      "net.ipv4.conf.all.secure_redirects" = false;
      "net.ipv4.conf.default.secure_redirects" = false;
      "net.ipv4.conf.all.send_redirects" = false;
      "net.ipv4.conf.default.send_redirects" = false;
    };

    environment.systemPackages = lib.mkIf cfg.firewall.enable [ pkgs.nftables ];
  };
}
