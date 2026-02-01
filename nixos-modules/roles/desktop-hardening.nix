# Desktop security hardening (opt-in)
# Provides baseline security improvements for desktop/laptop systems
{
  lib,
  config,
  pkgs,
  ...
}: {
  options.desktop.hardening = {
    enable = lib.mkEnableOption "baseline desktop security hardening";

    sudo = {
      timeout = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Sudo password timeout in minutes (0 = always ask)";
      };

      requirePassword = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Always require password for sudo";
      };
    };

    polkit = {
      restrictUserActions = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Restrict polkit actions for regular users (requires admin for system changes)";
      };
    };

    firewall = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable basic firewall rules for desktop";
      };

      allowedTCPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [];
        description = "Additional TCP ports to allow through firewall";
      };

      allowedUDPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        default = [];
        description = "Additional UDP ports to allow through firewall";
      };
    };
  };

  config = lib.mkIf (config.desktop.hardening.enable && config.roles.desktop) {
    # Sudo configuration
    security = {
      sudo = {
        execWheelOnly = lib.mkIf config.desktop.hardening.sudo.requirePassword true;
        extraConfig = ''
          # Sudo timeout: ${toString config.desktop.hardening.sudo.timeout} minutes
          Defaults timestamp_timeout=${toString config.desktop.hardening.sudo.timeout}
        # Require password for all commands
          ${lib.optionalString config.desktop.hardening.sudo.requirePassword ''
            Defaults passwd_tries=3
            Defaults passwd_timeout=1
          ''}
        '';
      };
      polkit = lib.mkIf config.desktop.hardening.polkit.restrictUserActions {
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
    };

    # Polkit hardening
    /*
       security.polkit = lib.mkIf config.desktop.hardening.polkit.restrictUserActions {
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
    */

    # Firewall configuration
    networking.firewall = lib.mkIf config.desktop.hardening.firewall.enable {
      enable = true;
      # Default: block all incoming, allow all outgoing
      inherit (config.desktop.hardening.firewall) allowedTCPPorts allowedUDPPorts;
      # Log refused connections (useful for debugging)
      logRefusedConnections = lib.mkDefault true;
      # Reject instead of drop (more user-friendly)
      rejectPackets = lib.mkDefault true;
    };

    # Network security hardening via centralized sysctl module
    security.hardenedSysctl = {
      enable = true;
      networkHardening = true;
    };

    # Audit logging (safe default)
    security.hardening.audit.enable = true;

    # AppArmor confinement (opt-in, enable for desktop hardening)
    security.hardening.apparmor.enable = true;

    # USBGuard device control (opt-in, safe default: allow mode)
    security.hardening.usbguard.enable = true;

    # Additional kernel hardening (desktop-specific)
    boot.kernel.sysctl = {
      # Disable source routing (additional security)
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv6.conf.all.accept_source_route" = 0;
      "net.ipv6.conf.default.accept_source_route" = 0;

      # Log martian packets (packets with impossible source addresses)
      "net.ipv4.conf.all.log_martians" = lib.mkDefault true;
      "net.ipv4.conf.default.log_martians" = lib.mkDefault true;

      # Restrict dmesg access to root only
      "kernel.dmesg_restrict" = 1;

      # Restrict access to kernel pointers
      "kernel.kptr_restrict" = 2;

      # Disable kexec (prevents replacing running kernel)
      "kernel.kexec_load_disabled" = lib.mkDefault 1;
    };

    # Additional security packages
    environment.systemPackages = with pkgs; [
      # Firewall management tool
      nftables
    ];
  };
}
