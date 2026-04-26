# NixOS configuration for host: homelab
#
# Hardware: Intel i9 + RTX 4090 + 4TB NVMe + 64GB DDR5
# Storage:  1TB Windows 11 (dual-boot) + 3TB NixOS (LUKS2+BTRFS)
#           Subvolumes: @, @home, @nix, @var, @swap, @/.snapshots, @home/.snapshots
# Features: Headless server — SSH + Tailscale + Podman
#
# Before first deployment:
#   1. Resize Windows to ~1TB and set up LUKS+BTRFS on the rest — see docs/homelab-partition-guide.md
#   2. Replace REPLACE-WITH-LUKS-UUID in hardware-configuration.nix (the encrypted NixOS partition)
#   3. Replace REPLACE-WITH-EFI-UUID in hardware-configuration.nix (the NixOS EFI partition)
#   4. Add SSH public key to authorizedKeys (see TODO below)
#   5. Generate homelab age key, add to .sops.yaml, re-encrypt secrets, then set secrets.enable = true
{
  inputs,
  lib,
  username,
  ...
}:
let
  # All BTRFS subvolumes live on the unlocked LUKS device.
  # The LUKS partition UUID lives in hardware-configuration.nix under boot.initrd.luks.devices.
  mainDisk = "/dev/mapper/cryptroot";

  cfgLib = import ../../lib { inherit lib; };
  inherit (cfgLib) mkBtrfsMounts;
in
{
  imports = [
    inputs.nix-index-database.nixosModules.nix-index
    ./hardware-configuration.nix
  ];

  networking.hostName = "homelab";

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
        kernelPackage = "latest";
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
  # Filesystem mounts — optimized BTRFS options for all subvolumes.
  # mkBtrfsMounts applies mkForce so these win over hardware-configuration.nix stubs.
  # All subvolumes are on /dev/mapper/cryptroot (unlocked LUKS device).
  # ================================================================
  fileSystems = mkBtrfsMounts mainDisk [
    "@"
    "@home"
    "@nix"
    "@var"
    "@swap"
    "@/.snapshots"
    "@home/.snapshots"
  ];

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
    # "ssh-ed25519 AAAA... vino@bandit"
  ];

  # ================================================================
  # Pre-deployment reminders (warnings, not assertions — must not break nix flake check)
  # ================================================================
  warnings =
    lib.optional (lib.hasInfix "REPLACE-WITH-" config.boot.initrd.luks.devices.cryptroot.device)
      "homelab: REPLACE-WITH-LUKS-UUID is still a placeholder in hardware-configuration.nix. Replace it with the actual LUKS partition UUID before deploying (see docs/homelab-partition-guide.md)."
    ++ lib.optional (config.users.users.${username}.openssh.authorizedKeys.keys == [ ])
      "homelab: no SSH authorized_keys configured — you will be locked out after first boot. Add your public key to users.users.${username}.openssh.authorizedKeys.keys.";
}
