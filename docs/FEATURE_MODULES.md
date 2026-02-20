# Feature Modules Guide

This NixOS config uses explicit feature modules with dependency declarations for discoverability and maintainability.

## Architecture

```
core/        - Always enabled (nix, users, networking, programs, packages, fonts)
features/    - Optional capabilities (explicit enable)
profiles/    - Pre-configured bundles (future use)
```

## Discovering Features

### Method 1: nix repl (Interactive)

```bash
nix repl
> :lf .
> :t config.features

# Shows all available features:
{
  desktop.i3-xfce = { enable = ...; keyboardLayout = ...; };
  development.base = { enable = ...; virtualization = { ... }; };
  hardware.laptop = { enable = ...; cpu = { ... }; framework = { ... }; };
  security = {
    secrets = { enable = ...; };
    server-hardening = { enable = ...; ssh = { ... }; fail2ban = { ... }; };
    desktop-hardening = { enable = ...; sudo = { ... }; polkit = { ... }; };
  };
  services = {
    tailscale = { enable = ...; };
    backup = { enable = ...; };
    monitoring = { enable = ...; };
    auto-update = { enable = ...; timer = { ... }; };
    openssh = { enable = ...; };
    trezord = { enable = ...; };
  };
  storage = {
    boot = { enable = ...; bootloader = ...; };
    swap = { enable = ...; devices = [...]; };
    btrfs = { enable = ...; fstrim = { ... }; autoScrub = { ... }; };
    snapper = { enable = ...; configs = { ... }; };
  };
  theme.stylix = { enable = ...; targets = { ... }; };
}
```

### Method 2: nixos-option (Command Line)

```bash
# List all features
nixos-option features

# Get specific feature info
nixos-option features.desktop.i3-xfce.enable
# Shows: value, type, description, declared in file

# Explore a feature's options
nixos-option features.hardware.laptop
```

### Method 3: Directory Structure (Predictable Paths)

```
nixos-modules/features/
├── desktop/
│   └── i3-xfce.nix              - i3 window manager + XFCE components
├── development/
│   └── base.nix                 - Development tools (Docker, Podman, direnv)
├── hardware/
│   └── laptop.nix               - Laptop hardware support (power, bluetooth, Framework)
├── security/
│   ├── secrets.nix              - SOPS-nix secrets management
│   ├── server-hardening.nix     - Server security (fail2ban, sysctl, nftables)
│   └── desktop-hardening.nix    - Desktop security (sudo, polkit, firewall)
├── services/
│   ├── tailscale.nix            - Tailscale VPN
│   ├── backup.nix               - Restic backup
│   ├── monitoring.nix           - System monitoring
│   ├── auto-update.nix          - Automated system updates
│   ├── openssh.nix              - SSH server
│   └── trezord.nix              - Trezor hardware wallet daemon
├── storage/
│   ├── boot.nix                 - GRUB/systemd-boot bootloader
│   ├── swap.nix                 - Swap configuration
│   ├── btrfs.nix                - BTRFS maintenance (fstrim, scrub)
│   └── snapper.nix              - BTRFS snapshots
└── theme/
    └── stylix.nix               - System-wide Stylix theme
```

## Creating Features

### Template

```nix
# Feature: [Name]
# Provides: [what it does]
# Dependencies: [what it needs]
{ config, lib, pkgs, ... }:
let
  cfg = config.features.[category].[name];
in
{
  # 1. OPTIONS: What this provides
  options.features.[category].[name] = {
    enable = lib.mkEnableOption "[description]";

    # Optional sub-options
    setting = lib.mkOption {
      type = lib.types.str;
      default = "value";
      description = "Description of setting";
    };
  };

  # 2. CONFIG: What this does (guarded by enable)
  config = lib.mkIf cfg.enable {
    # Configuration here
    services.example.enable = true;

    # Optional: Warnings for missing configuration
    warnings = lib.optional (cfg.setting == "") ''
      features.[category].[name]: setting is empty.
      Set features.[category].[name].setting = "value";
    '';

    # Optional: Assertions for hard dependencies
    assertions = [
      {
        assertion = condition;
        message = "[name] requires [dependency]";
      }
    ];
  };
}
```

### Example: Storage Feature

```nix
# Feature: BTRFS Maintenance
# Provides: BTRFS filesystem maintenance (fstrim, auto-scrub)
# Dependencies: BTRFS filesystems
{ lib, config, ... }:
let
  cfg = config.features.storage.btrfs;
in
{
  options.features.storage.btrfs = {
    enable = lib.mkEnableOption "BTRFS filesystem maintenance";

    fstrim = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable fstrim for SSD maintenance";
      };

      interval = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "How often to run fstrim";
      };
    };

    autoScrub = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic BTRFS scrubbing";
      };

      fileSystems = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "BTRFS filesystems to scrub";
        example = [ "/" "/home" ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.fstrim = lib.mkIf cfg.fstrim.enable {
      enable = true;
      inherit (cfg.fstrim) interval;
    };

    services.btrfs.autoScrub = lib.mkIf cfg.autoScrub.enable {
      enable = true;
      inherit (cfg.autoScrub) fileSystems interval;
    };

    warnings = lib.optional (cfg.autoScrub.enable && cfg.autoScrub.fileSystems == []) ''
      features.storage.btrfs.autoScrub is enabled but no filesystems specified.
      Set features.storage.btrfs.autoScrub.fileSystems to enable scrubbing.
    '';
  };
}
```

## Enabling Features

In `nixos-configurations/<host>/default.nix`:

```nix
{
  features = {
    # Desktop environment
    desktop.i3-xfce = {
      enable = true;
      keyboardLayout = "at";
    };

    # Development tools
    development.base = {
      enable = true;
      virtualization.docker.enable = false;
      virtualization.podman.enable = false;
    };

    # Hardware support
    hardware.laptop = {
      enable = true;
      cpu.vendor = "amd";
      framework = {
        enable = true;
        model = "framework-13-amd";
      };
    };

    # Security
    security = {
      secrets.enable = true;
      desktop-hardening.enable = true;
    };

    # Services
    services = {
      tailscale = {
        enable = true;
        useRoutingFeatures = "client";
      };
      auto-update = {
        enable = true;
        timer.enable = false; # Manual triggering only
      };
    };

    # Storage
    storage = {
      boot = {
        enable = true;
        bootloader = "grub";
      };
      btrfs = {
        enable = true;
        autoScrub = {
          enable = true;
          fileSystems = [ "/" "/home" ];
        };
      };
    };
  };
}
```

## Dependency Warnings

If you forget recommended configuration:

```
warning: features.storage.btrfs.autoScrub is enabled but no filesystems specified.
         Set features.storage.btrfs.autoScrub.fileSystems to enable scrubbing.
```

Just add the required configuration!

## Best Practices

1. **One module, one feature**: Keep modules focused on a single capability
2. **Declare dependencies**: Use warnings for missing configuration, assertions for hard dependencies
3. **Document everything**: Add description to all options with examples
4. **Test changes**: Run `nix flake check` after modifications
5. **YAGNI principle**: Don't add options you don't need yet
6. **Use inherit**: Prefer `inherit (cfg.foo) bar;` over `bar = cfg.foo.bar;`
7. **Merge attribute sets**: Avoid repeated keys like multiple `services.*` assignments

## Adding a New Feature

1. **Create the module**: `nixos-modules/features/[category]/[name].nix`
2. **Add to category default.nix**: Import in `features/[category]/default.nix`
3. **Test locally**: Enable in your host config
4. **Verify**: Run `nix flake check` and `nixos-rebuild build`
5. **Document**: Add to this guide if it's a major feature
6. **Commit**: Use descriptive commit message with feature details

## Migration from Old Roles System

The old `roles.*` options have been fully removed. Use `features.*` instead:

**Old**:
```nix
roles.desktop = true;
roles.laptop = true;
desktop.hardening.enable = true;
```

**New**:
```nix
features.desktop.i3-xfce.enable = true;
features.hardware.laptop.enable = true;
features.security.desktop-hardening.enable = true;
```

Benefits: More explicit, better discoverability, clearer dependencies.
