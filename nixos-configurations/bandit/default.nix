# NixOS configuration for host: bandit
#
# Hardware: Framework 13 AMD (7040 series)
# Storage:  BTRFS with subvolumes (@, @home, @nix, @var, @swap)
# Features: Desktop (i3 + greetd), Laptop optimizations, Stylix theming
#
# Boundary: This file is the composition root for the bandit host.
# It declares which features are enabled and wires together the import graph.
# Machine-specific facts (disk UUID, resume offset, mount options) live in
# host-params.nix. Generated hardware facts live in hardware-configuration.nix.
{ inputs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
    ./host-params.nix
    inputs.nix-index-database.nixosModules.nix-index
    ../../nixos-modules/home-manager.nix
  ];

  networking.hostName = "bandit";
  services.dbus.implementation = "dbus";
  system.stateVersion = "25.11";

  # Feature modules
  features = {
    services = {
      tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };

      # Monitoring (currently disabled for battery life)
      monitoring = {
        enable = false;
        logging.enhancedJournal = true; # Runs independently of monitoring.enable (separate guard in module)
      };

      # Automated updates (timer disabled for battery life)
      auto-update = {
        enable = true; # Service available for manual triggering
        timer.enable = false; # Disabled for battery (2-4% per update, 10-15min CPU)
        timer.calendar = "monthly"; # When enabled, run monthly
      };

    };

    desktop.i3 = {
      enable = true;
      keyboardLayout = "at"; # Austrian keyboard
    };

    storage = {
      boot = {
        enable = true;
        bootloader = "grub";
        kernelPackage = "latest";
      };

      swap = {
        enable = true;
        devices = [
          {
            device = "/swap/swapfile";
            priority = 1; # Lower priority - use as backup after zram is full
          }
        ];
      };

      btrfs = {
        enable = true;
        fstrim.enable = true;
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
        enableTimeline = false; # Disabled for I/O reduction — manual snapshots preferred
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

    theme.stylix = {
      enable = true;
      targets.grub.enable = true;
    };

    hardware.laptop = {
      enable = true;
      cpu.vendor = "amd";
      # useAutoFreq intentionally not set (defaults to false) — auto-cpufreq caused
      # instability on this machine; using power-profiles-daemon instead.
      powerManagement.enableHibernation = true;
      zram = {
        memoryPercent = 50; # Increase from 25% to 50% for better memory headroom
      };
      framework = {
        enable = true;
        model = "framework-13-amd";
      };
    };

    development.base = {
      enable = true;
      virtualization.docker.rootless.enable = true;
      wireshark.enable = true;
    };

    security = {
      secrets.enable = true;

      # Desktop security hardening
      desktop-hardening = {
        enable = true;
        # Disable kernel image protection to allow hibernation.
        # kexec is still blocked via sysctl in desktop-hardening regardless of this setting.
        protectKernelImage = false;
      };

      clamav = {
        enable = true;
        # excludePaths is set in host-params.nix (machine-specific paths)
      };
    };
  };
}
