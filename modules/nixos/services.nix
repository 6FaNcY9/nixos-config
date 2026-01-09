{
  lib,
  pkgs,
  config,
  username ? "vino",
  hostname ? "bandit",
  ...
}: let
  repoRoot = "/home/${username}/src/nixos-config";
in {
  # ------------------------------------------------------------
  # Automated updates (flake inputs + rebuild)
  # ------------------------------------------------------------
  systemd.services.nixos-config-update = {
    description = "Update nixos-config flake inputs and rebuild";
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = repoRoot;
      Environment = ["HOME=/home/${username}"];
    };
    path = [pkgs.nix pkgs.git pkgs.util-linux];
    script = ''
      ${pkgs.util-linux}/bin/runuser -u ${username} -- nix flake update
      ${config.system.build.nixos-rebuild}/bin/nixos-rebuild switch --flake ${repoRoot}#${hostname}
    '';
  };

  systemd.timers.nixos-config-update = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };

  services = {
    openssh = {
      enable = lib.mkDefault false;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
      };
    };

    # fail2ban (optional)
    # fail2ban = {
    #   enable = true;
    #   bantime = "1h";
    #   maxretry = 5;
    #   jails = {
    #     sshd = ''
    #       enabled = true
    #       mode = aggressive
    #     '';
    #   };
    # };

    trezord.enable = true;

    journald.extraConfig = ''
      SystemMaxUse=500M
      RuntimeMaxUse=200M
      MaxRetentionSec=30day
    '';
  };
}
