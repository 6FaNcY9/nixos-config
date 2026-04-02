# ClamAV On-Demand Scanner — Design Spec

**Date:** 2026-04-02
**Status:** Approved

## Overview

Integrate ClamAV as a purely on-demand virus scanner with no background daemon and no scheduled scans. Virus definitions update automatically once at boot. Three `just` commands cover the common scan targets.

## Goals

- Manual-only scanning: no clamd daemon, no recurring scan timer
- Definitions stay fresh via a single freshclam run 2 minutes after boot
- Three scan modes: home directory, full system, custom path
- Infected files moved to quarantine (not deleted)
- Configurable exclusion paths baked into the scanner at build time
- Forensics directory `/home/vino/Documents/Projekts/mrijaPage` always excluded

## Non-Goals

- Real-time filesystem monitoring
- Email/desktop notifications on scan completion
- Scan result logging or history

## Architecture

### Feature Module

New file: `nixos-modules/features/security/clamav.nix`

Follows the existing `features.<category>.<name>.enable` pattern. Registered in `nixos-modules/features/security/default.nix`. Enabled in `nixos-configurations/bandit/default.nix`.

### Options

```nix
options.features.security.clamav = {
  enable = lib.mkEnableOption "ClamAV on-demand antivirus scanner";
  excludePaths = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Directories excluded from all scans.";
    example = [ "/home/vino/Documents/Projekts/mrijaPage" ];
  };
};
```

### Definition Updates (freshclam)

`services.clamav.updater.enable = true` is set, which creates the `clamav-freshclam` systemd service and timer. The timer is overridden via `lib.mkForce` to fire once at boot (`OnBootSec = "2min"`) instead of on a recurring calendar schedule. The 2-minute delay ensures the network (Tailscale, DHCP) is up before freshclam contacts upstream mirrors.

### Scanner Wrapper Script

A `pkgs.writeShellScriptBin "clamav-scan"` script is generated at NixOS build time. The configured `excludePaths` plus system pseudo-filesystem paths (`/proc`, `/sys`, `/dev`, `/run`) are interpolated as `--exclude-dir=` flags at build time — no runtime config reading. The script is installed via `environment.systemPackages`.

```
clamav-scan home    → scans $HOME
clamav-scan system  → scans /
clamav-scan <path>  → scans given path
```

All three modes pass `--recursive --move=<quarantine>` and the baked-in exclusion flags. All invocations use `sudo` so infected files can be moved to the root-owned quarantine directory.

### Quarantine Directory

`/var/lib/clamav-quarantine` — created via `systemd.tmpfiles.rules`, owned by root, mode `0700`. Infected files are moved here by `clamscan --move`. The directory is never auto-cleaned; manual review and deletion is the user's responsibility.

### Justfile Recipes

Three static recipes added to the root `justfile`:

```just
scan-home:
    clamav-scan home

scan-system:
    clamav-scan system

scan PATH:
    clamav-scan {{PATH}}
```

## Files Changed

| File | Change |
|------|--------|
| `nixos-modules/features/security/clamav.nix` | **New** — full module |
| `nixos-modules/features/security/default.nix` | Add `./clamav.nix` import |
| `nixos-modules/core/packages.nix` | Remove `pkgs.clamav` |
| `nixos-configurations/bandit/default.nix` | Enable feature + set `excludePaths` |
| `justfile` | Add `scan-home`, `scan-system`, `scan PATH` recipes |

## Bandit Configuration

```nix
features.security.clamav = {
  enable = true;
  excludePaths = [ "/home/vino/Documents/Projekts/mrijaPage" ];
};
```
