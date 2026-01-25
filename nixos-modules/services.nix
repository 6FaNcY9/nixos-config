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

  systemd.timers.nixos-config-update = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "weekly";
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

    journald.extraConfig = ''
      SystemMaxUse=500M
      RuntimeMaxUse=200M
      MaxRetentionSec=30day
    '';
  };
}
