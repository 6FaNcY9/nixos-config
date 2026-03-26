# Phase 0: Multi-Host Repo Refactoring Design

**Date:** 2026-03-26
**Goal:** Fix the minimal set of issues that prevent adding a second NixOS host (the server) to this repo, without over-engineering or touching anything unrelated.
**Approach:** Option A — targeted fixes for blocker/moderate audit findings only. Minors deferred.

---

## Context

This is Phase 0 of a multi-phase homelab expansion:

| Phase | Sub-project |
|-------|------------|
| **0** | **Multi-host repo refactoring** ← this spec |
| 1 | Base server host (headless, TTY only, i9/RTX4090/64GB/4TB) |
| 2 | Network infrastructure (AdGuard, Caddy, Cloudflare Tunnel) |
| 3 | Core services (Filebrowser, Borgbackup, Grafana) |
| 4 | Web presence (web apps on subdomains of atmospheare.at) |

The server is a high-end machine (i9, RTX 4090, 64GB DDR5, 4TB NVMe) running headless — no WM, no DM, TTY only. It will be configured minimally: only what a server needs.

Phase 0 is a prerequisite for all subsequent phases.

---

## What We Fix (and What We Skip)

### Fixed in this phase

| # | File | Change | Why |
|---|------|--------|-----|
| 1 | `flake.nix` | Replace `${primaryHost}` with literal `bandit`, remove `primaryHost` variable | Decouples host registration from a hardcoded primary |
| 2 | `lib/default.nix` | Add `mkUserModuleArgs` helper | Extracts `_module.args` block so second user doesn't copy-paste |
| 3 | `home-configurations/vino/default.nix` | Use `mkUserModuleArgs` | Consumes the new helper |
| 4 | `nixos-modules/core/networking.nix` | Wrap timezone, locale, keyMap in `lib.mkDefault` | Server inherits wrong locale/tz without this |
| 5 | `home-modules/features/editor/nixvim/plugins.nix` | Replace hardcoded `bandit`/`vino@bandit` with injected `hostname`/`username` | LSP config breaks on any non-bandit host |
| 6 | `home-modules/core/secrets.nix` | Gate each secret with `builtins.pathExists` | Server build fails if any secret file is absent |
| 7 | `.sops.yaml` | Rename `&host` → `&host_bandit` | Must name host keys before adding a second host key |

### Skipped (don't affect server build)

- `core/nix.nix` Cachix URL in shared module — server benefits from the cache too, fine for now
- `features/storage/snapper.nix` ALLOW_USERS — server will not enable snapper
- `features/services/auto-update.nix` username coupling — server will not enable auto-update
- `shared-modules/` palette/workspaces not in nixos layer — server has no desktop
- Font sizes not wrapped in `mkDefault` — server has no display
- `profiles.nix` jetbrains.idea unconditional — server will set `dev = false`

---

## Detailed Design

### 1. flake.nix

**Before:**
```nix
primaryHost = "bandit";
# ...
ezConfigs.nixos.hosts.${primaryHost}.userHomeModules = [ username ];
```

**After:**
```nix
# primaryHost variable removed entirely
# ...
ezConfigs.nixos.hosts.bandit.userHomeModules = [ username ];
```

Ez-configs already auto-discovers hosts from `nixos-configurations/` — no other flake.nix changes are needed to support additional hosts. The server gets no `userHomeModules` entry (headless, no Home Manager).

The `username` single-user assertion and `system = "x86_64-linux"` stay unchanged — the server is also x86_64-linux and has no `home-configurations/` directory.

### 2. lib/default.nix — mkUserModuleArgs

New helper added to `lib/default.nix`:

```nix
mkUserModuleArgs =
  {
    config,
    pkgs,
    inputs,
  }:
  {
    c = config.theme.colors;
    palette = config.theme.palette;
    workspaces = import ../shared-modules/workspaces.nix;
    cfgLib = import ../lib;
    stylixFonts = config.stylix.fonts;
    i3Pkg = pkgs.i3;
  };
```

This is a pure function — takes what it needs, returns the `_module.args` attrset. No host-specific assumptions.

### 3. home-configurations/vino/default.nix

The existing `_module.args` derivation block is replaced with a call to the new helper:

```nix
_module.args = cfgLib.mkUserModuleArgs { inherit config pkgs inputs; };
```

The file otherwise stays unchanged. A future `home-configurations/alice/default.nix` calls the same helper.

### 4. nixos-modules/core/networking.nix

Locale, timezone, and keymap wrapped in `lib.mkDefault` so any host entrypoint can override:

```nix
time.timeZone = lib.mkDefault "Europe/Vienna";
i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
console.keyMap = lib.mkDefault "de-latin1-nodeadkeys";
```

The server will set `time.timeZone = "UTC"` and `console.keyMap = "us"` in `nixos-configurations/server/default.nix` (Phase 1).

### 5. home-modules/features/editor/nixvim/plugins.nix

The nixd LSP expressions hardcode `bandit` and `vino@bandit`. Both `hostname` and `username` are already injected via `_module.args` — the fix replaces the literals:

```nix
# Before:
nixosConfigurations.bandit
homeConfigurations."vino@bandit"

# After:
nixosConfigurations.${hostname}
homeConfigurations."${username}@${hostname}"
```

### 6. home-modules/core/secrets.nix

Each secret declaration is guarded with `builtins.pathExists` so a host that doesn't have a given secret file doesn't fail at eval time:

```nix
sops.secrets = lib.mkMerge (
  lib.optional (builtins.pathExists ./secrets/github.yaml) {
    github = { sopsFile = ./secrets/github.yaml; };
  }
  # ... same pattern for each secret
);
```

The server starts with zero home-manager secrets. Secrets are added per-host in Phase 1+.

### 7. .sops.yaml

The generic `&host` anchor is renamed to `&host_bandit` to establish the per-host naming convention before a second host key is added:

```yaml
# Before:
keys:
  - &host age1...

# After:
keys:
  - &host_bandit age1...
```

When the server age key is generated in Phase 1, it gets its own `&host_server` anchor.

---

## Verification

After all changes, run:

```bash
just qa          # format + lint + flake check
just rebuild-test # dry-run NixOS build for bandit
```

Both must pass before committing. The bandit Home Manager activation must also be verified:

```bash
nix build .#homeConfigurations."vino@bandit".activationPackage --dry-run
```

---

## What This Enables

After Phase 0:
- `nixos-configurations/server/default.nix` can be created and it auto-registers via ez-configs
- A second user directory under `home-configurations/` can be added without touching flake.nix
- The server host inherits sane locale/tz defaults and can override them
- Secrets are optional per-host — no build failures on a clean server
