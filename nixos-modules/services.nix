{
  lib,
  pkgs,
  config,
  username,
  repoRoot,
  ...
}: {
  # ------------------------------------------------------------
  # Automated updates (flake inputs + rebuild)
  # ------------------------------------------------------------
  systemd.services.nixos-config-update = {
    description = "Update nixos-config flake inputs and rebuild";
    unitConfig = {
      ConditionACPower = true;
    };
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = repoRoot;
      Environment = ["HOME=/home/${username}"];
    };
    path = [pkgs.nix pkgs.git pkgs.util-linux];
    script = ''
      ${pkgs.util-linux}/bin/runuser -u ${username} -- nix flake update
      ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch --flake ${repoRoot}#${config.networking.hostName}
    '';
  };

  # Auto-update timer: DISABLED for battery life (manual updates preferred)
  # Battery impact: 2-4% per update (flake update + rebuild = 10-15min CPU)
  # Re-enable by uncommenting wantedBy line
  systemd.timers.nixos-config-update = {
    # wantedBy = ["timers.target"];  # ← DISABLED for battery
    timerConfig = {
      OnCalendar = "monthly"; # Changed from weekly (if re-enabled)
      RandomizedDelaySec = "2h";
      Persistent = true;
    };
  };

  services = {
    openssh = {
      enable = lib.mkDefault config.roles.server;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
      };
    };

    trezord.enable = lib.mkDefault config.roles.desktop;

    # journald settings are managed by monitoring.nix (monitoring.logging.*)
    # to avoid duplicate directives in extraConfig
  };
}
