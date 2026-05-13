# NixOS configuration for host: homelab
#
# Hardware: Intel i9 + RTX 4090 + 4TB NVMe + 64GB DDR5
# Storage:  BTRFS with subvolumes (@, @home, @nix, @var, @swap), dual-boot Windows 11
# Features: Headless server — SSH + Tailscale + Podman
#
# Before first deployment:
#   1. Run nixos-generate-config on the target and update hardware-configuration.nix
#   2. Replace REPLACE-WITH-BTRFS-UUID in hardware-configuration.nix and mainDisk below
#   3. Add SSH public key to authorizedKeys (see TODO below)
#   4. Generate homelab age key, add to .sops.yaml, re-encrypt secrets, then set secrets.enable = true
{
  inputs,
  lib,
  username,
  ...
}:
let
  # UUID of the BTRFS partition (all subvolumes share one partition).
  # Update after running nixos-generate-config on the target.
  mainDisk = "/dev/disk/by-uuid/REPLACE-WITH-BTRFS-UUID";

  cfgLib = import ../../lib { inherit lib; };
  inherit (cfgLib) mkBtrfsOpts;
in
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
    inputs.arion.nixosModules.arion
    ./hardware-configuration.nix
  ];

  networking.hostName = "homelab";
  system.stateVersion = "25.11";

  # arion backend = "podman-socket": the arion NixOS module auto-enables
  # virtualisation.podman.dockerSocket so no explicit setting is needed here.
  virtualisation.arion = {
    backend = "podman-socket";
    projects.web.settings = {
        services.caddy.service = {
          image = "caddy:2-alpine";
          # Loopback only — cloudflared (host process) forwards here.
          # No 0.0.0.0 or port 443: Cloudflare terminates TLS at the edge;
          # ACME is never needed on this host.
          ports = [ "127.0.0.1:80:80" ];
          volumes = [
            "/var/lib/caddy/data:/data"
            "/var/lib/caddy/config:/config"
            "/etc/caddy/Caddyfile:/etc/caddy/Caddyfile:ro"
          ];
          restart = "unless-stopped";
        };
      };
  };

  # Phase 1 placeholder Caddyfile — replaced in Phase 2 with per-domain reverse_proxy blocks
  environment.etc."caddy/Caddyfile".text = ''
    {
      admin off
    }

    :80 {
      respond "homelab phase 1 ready" 200
    }
  '';

  systemd.tmpfiles.rules = [
    "d /var/lib/caddy/data   0750 root root -"
    "d /var/lib/caddy/config 0750 root root -"
  ];

  # Home Manager imports Stylix explicitly in home-modules/default.nix.
  # Disable Stylix's automatic HM injection to avoid double-importing the module.
  stylix.homeManagerIntegration.autoImport = false;

  # ================================================================
  # Feature modules
  # ================================================================
  features = {
    services = {
      openssh = {
        enable = true;
        # passwordAuthentication defaults to false — key-only access enforced.
      };

      tailscale = {
        enable = true;
        # "server" enables subnet routing and exit-node capability (deferred).
        useRoutingFeatures = "server";
      };

      monitoring = {
        enable = false; # Grafana/Prometheus deferred until needed
        grafana.enable = false;
        # Enhanced journal runs independently of monitoring.enable.
        logging.enhancedJournal = true;
      };

      auto-update = {
        enable = true;
        timer.enable = true; # Server can afford background updates
        timer.calendar = "weekly";
      };
    };

    storage = {
      boot = {
        enable = true;
        bootloader = "grub";
        # Detect Windows 11 partition for dual-boot GRUB menu.
        useOSProber = true;
      };

      btrfs = {
        enable = true;
        fstrim.enable = true; # NVMe benefits from periodic TRIM
        autoScrub = {
          enable = true;
          fileSystems = [
            "/"
            "/home"
          ];
          interval = "monthly";
        };
      };

      snapper = {
        enable = true;
        enableTimeline = true; # Hourly snapshots — server storage is not a concern
        configs = {
          root = {
            subvolume = "/";
            numberLimit = "50";
          };
          home = {
            subvolume = "/home";
            numberLimit = "50";
          };
        };
      };
    };

    development.base = {
      enable = true;
      # Podman for container-based web hosting (no Docker — avoids daemon conflict).
      virtualization.podman = {
        enable = true;
        dockerCompat = true; # docker CLI alias points to podman
      };
      virtualization.docker.enable = false;
    };

    security = {
      # server-hardening requires openssh.enable = true (assertion in module).
      server-hardening = {
        enable = true;
        ssh.allowUsers = [ username ]; # Restrict SSH to vino only
      };

      # Secrets disabled until homelab age key is generated and added to .sops.yaml.
      # Steps to enable:
      #   1. Boot the machine — sops-nix auto-generates /var/lib/sops-nix/key.txt
      #   2. Extract the public key:
      #        sudo nix-shell -p age --run "age-keygen -y /var/lib/sops-nix/key.txt"
      #   3. Add as &host_homelab in .sops.yaml and update creation_rules
      #   4. Re-encrypt: cd secrets && sops updatekeys *.yaml
      #   5. Set secrets.enable = true here
      secrets.enable = false;
    };
  };

  # ================================================================
  # Filesystem mounts — optimized BTRFS options override hardware-configuration.nix.
  # ================================================================
  fileSystems = {
    "/" = {
      device = mainDisk;
      fsType = "btrfs";
      options = lib.mkForce (mkBtrfsOpts "@");
    };
    "/home" = {
      device = mainDisk;
      fsType = "btrfs";
      options = lib.mkForce (mkBtrfsOpts "@home");
    };
    "/nix" = {
      device = mainDisk;
      fsType = "btrfs";
      options = lib.mkForce (mkBtrfsOpts "@nix");
    };
    "/var" = {
      device = mainDisk;
      fsType = "btrfs";
      options = lib.mkForce (mkBtrfsOpts "@var");
    };
  };

  # ================================================================
  # SSH authorised keys
  # TODO: Add SSH public key(s) before first deployment.
  #
  # From bandit, generate (if not already):
  #   ssh-keygen -t ed25519 -C "vino@bandit" -f ~/.ssh/id_ed25519
  # Then add the public key below:
  #   cat ~/.ssh/id_ed25519.pub
  # ================================================================
  users.users.${username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAoSDGCuesPlnsVjFMEYjOHE0gedGD2LUnpwKn/QjurC vino@bandit→homelab"
  ];
}
