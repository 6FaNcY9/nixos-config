# ClamAV On-Demand Scanner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add ClamAV as a NixOS feature module with boot-time definition updates and three `just` scan commands (home, system, custom path) — no daemon, no scheduled scans.

**Architecture:** A new feature module `nixos-modules/features/security/clamav.nix` follows the existing `features.<category>.<name>.enable` pattern. It generates a `clamav-scan` wrapper script at build time with exclusion paths baked in, overrides the freshclam timer to fire once at boot, and creates a root-owned quarantine directory. The `justfile` gets three static recipes that call the wrapper.

**Tech Stack:** Nix, NixOS module system, systemd, clamscan (standalone, no daemon), freshclam

---

## Files

| File | Action | Responsibility |
|------|--------|----------------|
| `nixos-modules/features/security/clamav.nix` | **Create** | Full feature module: options, script, timer, tmpfiles |
| `nixos-modules/features/security/default.nix` | **Modify** | Add `./clamav.nix` import |
| `nixos-modules/core/packages.nix` | **Modify** | Remove `pkgs.clamav` (service module provides it) |
| `nixos-configurations/bandit/default.nix` | **Modify** | Enable feature + set `excludePaths` |
| `justfile` | **Modify** | Add `scan-home`, `scan-system`, `scan PATH` recipes |

---

## Task 1: Create the clamav feature module

**Files:**
- Create: `nixos-modules/features/security/clamav.nix`

- [ ] **Step 1: Write the module file**

Create `nixos-modules/features/security/clamav.nix` with this exact content:

```nix
# Security: ClamAV on-demand antivirus scanner
#
# Provides three scan commands via the `clamav-scan` wrapper script:
#   clamav-scan home    — scans $HOME
#   clamav-scan system  — scans /
#   clamav-scan <path>  — scans a specific path
#
# Virus definitions are updated once at boot via freshclam (no recurring timer).
# Infected files are moved to /var/lib/clamav-quarantine (never auto-deleted).
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.features.security.clamav;
  quarantine = "/var/lib/clamav-quarantine";
  systemExcludes = [
    "/proc"
    "/sys"
    "/dev"
    "/run"
  ];
  excludeFlags = lib.concatMapStringsSep " " (p: "--exclude-dir=${p}") (
    systemExcludes ++ cfg.excludePaths
  );

  scanScript = pkgs.writeShellScriptBin "clamav-scan" ''
    case "$1" in
      home)
        sudo clamscan --recursive --move="${quarantine}" ${excludeFlags} "$HOME"
        ;;
      system)
        sudo clamscan --recursive --move="${quarantine}" ${excludeFlags} /
        ;;
      "")
        echo "Usage: clamav-scan home | system | <path>"
        exit 1
        ;;
      *)
        sudo clamscan --recursive --move="${quarantine}" ${excludeFlags} "$1"
        ;;
    esac
  '';
in
{
  options.features.security.clamav = {
    enable = lib.mkEnableOption "ClamAV on-demand antivirus scanner";
    excludePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Directories excluded from all scans.";
      example = [ "/home/vino/Documents/Projekts/mrijaPage" ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable freshclam (pulls in the clamav package automatically).
    services.clamav.updater.enable = true;

    # Override the recurring timer: fire once 2 minutes after boot instead.
    # mkForce replaces the entire timerConfig set (drops OnCalendar and Persistent).
    systemd.timers.clamav-freshclam.timerConfig = lib.mkForce {
      OnBootSec = "2min";
    };

    # Quarantine directory — root-owned, never auto-cleaned.
    systemd.tmpfiles.rules = [
      "d ${quarantine} 0700 root root -"
    ];

    environment.systemPackages = [ scanScript ];
  };
}
```

- [ ] **Step 2: Register the new file with git**

New Nix files must be git-tracked before `nix flake check` can see them:

```bash
git add nixos-modules/features/security/clamav.nix
```

---

## Task 2: Wire the module into the security aggregator

**Files:**
- Modify: `nixos-modules/features/security/default.nix`

- [ ] **Step 1: Add the import**

In `nixos-modules/features/security/default.nix`, add `./clamav.nix` to the imports list:

```nix
# Security Features Aggregator
#
# Imports security-related modules including secrets management (sops-nix),
# server hardening (fail2ban, sysctls), and desktop hardening (polkit, firewall).
{ ... }:
{
  imports = [
    ./secrets.nix
    ./server-hardening.nix
    ./desktop-hardening.nix
    ./tor-routing.nix
    ./clamav.nix
  ];
}
```

---

## Task 3: Enable the feature on bandit

**Files:**
- Modify: `nixos-configurations/bandit/default.nix`

- [ ] **Step 1: Add clamav to the security block**

The `security` block in `bandit/default.nix` currently ends at line 147. Add `clamav` inside it, after `desktop-hardening`:

```nix
    security = {
      secrets.enable = true;

      # Desktop security hardening
      desktop-hardening = {
        enable = true;
        # Disable kernel image protection to allow hibernation.
        # kexec is still blocked via sysctl in desktop-hardening regardless of this setting.
        protectKernelImage = false;
        firewall.allowedTCPPorts = [ 8181 ];
      };

      clamav = {
        enable = true;
        excludePaths = [ "/home/vino/Documents/Projekts/mrijaPage" ];
      };
    };
```

---

## Task 4: Remove clamav from core packages

**Files:**
- Modify: `nixos-modules/core/packages.nix`

- [ ] **Step 1: Delete the pkgs.clamav line**

`services.clamav.updater.enable = true` pulls in the clamav package automatically. The explicit entry in `systemPackages` is now redundant. Remove line 21:

```nix
# Core: System packages
# Always enabled (no option)
{
  lib,
  pkgs,
  ...
}:
let
  systemPackages = [
    pkgs.btrfs-progs
    pkgs.cachix # Binary cache management
    pkgs.curl
    pkgs.efibootmgr
    pkgs.git
    pkgs.vim
    pkgs.wget
    pkgs.gnupg
    pkgs.sops
    pkgs.age
    pkgs.ssh-to-age
  ];
in
{
  environment.systemPackages = systemPackages;

  # Many third-party scripts use #!/bin/bash shebangs (e.g. Claude Code plugins).
  # NixOS doesn't provide /bin/bash by default — only /bin/sh.
  # See docs/bin-bash.md for rationale, alternatives, and when the symlink is justified.
  environment.shells = [ pkgs.bash ];
  system.activationScripts.binbash = lib.stringAfter [ "stdio" ] ''
    ln -sfn ${pkgs.bash}/bin/bash /bin/bash
  '';
}
```

---

## Task 5: Add justfile recipes

**Files:**
- Modify: `justfile`

- [ ] **Step 1: Add a Security section with the three scan recipes**

Append a new section to `justfile` after the existing sections. Find the last recipe in the file and add below it:

```just
# ── Security ─────────────────────────────────────────────

# Scan home directory for viruses (moves infected files to /var/lib/clamav-quarantine)
scan-home:
    clamav-scan home

# Scan entire system for viruses (moves infected files to /var/lib/clamav-quarantine)
scan-system:
    clamav-scan system

# Scan a specific path: just scan ~/Downloads
scan PATH:
    clamav-scan {{PATH}}
```

---

## Task 6: Validate and commit

- [ ] **Step 1: Run QA**

```bash
just qa
```

Expected: exits 0 with no warnings. If `statix` or `deadnix` complain, fix the flagged lines before continuing. Common issues:
- Unused `pkgs` argument if the module doesn't reference `pkgs` directly — but `scanScript` uses `pkgs.writeShellScriptBin`, so this is fine.
- `nixfmt-rfc-style` may reformat spacing in the module — accept those changes.

- [ ] **Step 2: Dry-run NixOS build**

```bash
just rebuild-test
```

Expected: build completes without errors. This confirms:
- The module evaluates correctly
- `services.clamav.updater.enable` is accepted by the NixOS module system
- The `clamav-scan` script derivation builds
- The quarantine tmpfiles rule is valid

- [ ] **Step 3: Commit all changes**

```bash
git add \
  nixos-modules/features/security/clamav.nix \
  nixos-modules/features/security/default.nix \
  nixos-modules/core/packages.nix \
  nixos-configurations/bandit/default.nix \
  justfile
git commit -m "feat(security): add ClamAV on-demand scanner module"
```
