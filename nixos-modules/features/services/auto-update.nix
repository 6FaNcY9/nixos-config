# Feature: Automated System Updates
# Provides: Automated flake update + rebuild via systemd timer
# Dependencies: None (but requires repoRoot to be set)
{
  lib,
  pkgs,
  config,
  username,
  repoRoot,
  ...
}:
let
  cfg = config.features.services.auto-update;
in
{
  options.features.services.auto-update = {
    enable = lib.mkEnableOption "automated NixOS flake updates and rebuilds";

    timer = {
      enable = lib.mkEnableOption "systemd timer for automatic updates";

      calendar = lib.mkOption {
        type = lib.types.str;
        default = "monthly";
        description = "OnCalendar systemd timer specification";
        example = "weekly";
      };

      randomizedDelay = lib.mkOption {
        type = lib.types.str;
        default = "2h";
        description = "RandomizedDelaySec for timer (spreads load)";
      };

      persistent = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to run missed updates on boot";
      };
    };

    requireACPower = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Only run updates when on AC power (battery saving)";
    };

    autoCommit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically commit flake.lock after successful update";
    };

    commitMessage = lib.mkOption {
      type = lib.types.str;
      default = "chore: automated flake update [skip ci]";
      description = "Git commit message for automated updates";
    };
  };

  config = lib.mkIf cfg.enable {
    # Automated update service
    systemd.services.nixos-config-update = {
      description = "Update nixos-config flake inputs and rebuild";
      unitConfig = lib.mkIf cfg.requireACPower {
        ConditionACPower = true;
      };

      path = [
        pkgs.nix
        pkgs.git
        pkgs.util-linux
      ];

      serviceConfig = {
        Type = "oneshot";
        WorkingDirectory = repoRoot;
      };

      script = ''
        set -euo pipefail

        # Abort if repoRoot is dirty - prevents data loss from uncommitted changes
        ${pkgs.util-linux}/bin/runuser -u ${username} -- \
          ${pkgs.git}/bin/git -C ${repoRoot} diff --quiet

        # Update flake.lock as the user (preserves file ownership)
        ${pkgs.util-linux}/bin/runuser -u ${username} -- \
          ${pkgs.nix}/bin/nix flake update

        ${lib.optionalString cfg.autoCommit ''
          # Auto-commit the updated flake.lock to prevent dirty tree on subsequent runs
          ${pkgs.util-linux}/bin/runuser -u ${username} -- \
            ${pkgs.git}/bin/git -C ${repoRoot} add flake.lock
          ${pkgs.util-linux}/bin/runuser -u ${username} -- \
            ${pkgs.git}/bin/git -C ${repoRoot} commit -m "${cfg.commitMessage}"
        ''}

        # Switch as root (requires elevated permissions for system changes)
        ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch \
          --flake ${repoRoot}#${config.networking.hostName}
      '';
    };

    # Optional timer for automatic updates
    systemd.timers.nixos-config-update = lib.mkIf cfg.timer.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.timer.calendar;
        RandomizedDelaySec = cfg.timer.randomizedDelay;
        Persistent = cfg.timer.persistent;
      };
    };

    # Warning if timer is disabled
    warnings = lib.optional (cfg.enable && !cfg.timer.enable) ''
      features.services.auto-update is enabled but timer is disabled.
      Updates will only run when manually triggered via:
        systemctl start nixos-config-update

      To enable automatic updates, set:
        features.services.auto-update.timer.enable = true;

      Note: Disabled by default for battery life (2-4% per update, 10-15min CPU)
    '';
  };
}
