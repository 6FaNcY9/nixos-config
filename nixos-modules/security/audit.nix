# Module: security/audit.nix
# Purpose: Linux audit framework (opt-in)
#
# Notes:
# - Captures security-relevant events and secret access
# - Safe to enable on desktop; log volume is moderate
{
  lib,
  config,
  ...
}: let
  cfg = config.security.hardening.audit;

  watchRules = map (path: "-w ${path} -p rwa -k secrets") cfg.watchPaths;
  auditRules = [
    # Monitor sudo usage
    "-a always,exit -F arch=b64 -S execve -F euid=0 -F key=sudo"

    # Monitor user management
    "-w /etc/passwd -p wa -k users"
    "-w /etc/group -p wa -k users"

    # Monitor network config changes
    "-w /etc/resolv.conf -p wa -k network"
  ] ++ watchRules;
in {
  options.security.hardening.audit = {
    enable = lib.mkEnableOption "Linux audit logging";

    watchPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/var/lib/sops-nix/key.txt"
        "/run/secrets"
        "/etc/nixos"
      ];
      description = "Paths to watch for read/write access";
    };
  };

  config = lib.mkIf cfg.enable {
    security.auditd.enable = true;
    security.audit = {
      enable = true;
      rules = auditRules;
    };
  };
}
