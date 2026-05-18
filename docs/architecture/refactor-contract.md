# Refactor Architecture Contract

**Status:** Active  
**Scope:** All structural refactor waves for this repository  
**Purpose:** Freeze the target-state architecture before any file moves or namespace changes occur. Later tasks must treat this document as the migration law.

---

## 1. Preserved Anchors (Never Move, Never Rename)

These paths are **stable migration surfaces**. Every refactor wave must leave them intact and importable at the same path. Downstream consumers, CI, and the `ez-configs` auto-discovery mechanism depend on them.

| Path | Role | Why it must stay |
|------|------|-----------------|
| `flake.nix` | Orchestration root | Entry point for all `nix` commands; ez-configs scans from here |
| `nixos-modules/default.nix` | Stable NixOS import surface | ez-configs wires this into every NixOS host automatically |
| `home-modules/default.nix` | Stable Home Manager import surface | ez-configs wires this into every HM user automatically |
| `lib/default.nix` | Shared helper boundary | Injected as `cfgLib` via `_module.args`; used across both layers |
| `nixos-modules/features/default.nix` | NixOS feature aggregator | Collects all `features.<category>.<name>.enable` option modules |
| `home-modules/features/default.nix` | HM feature aggregator | Collects all HM feature modules |
| `shared-modules/` | Cross-layer shared modules | Stylix, palette, and workspace modules consumed by both NixOS and HM |
| `overlays/` | Centralized overlay ownership | All nixpkgs overlays live here; no overlay logic belongs elsewhere |
| `flake-modules/` | Flake composition layer | perSystem devshells, apps, checks; not a target for consolidation |

**Rule:** If a task requires moving or renaming any path in this table, it must be escalated and this contract must be updated first. No silent renames.

---

## 2. Canonical Layer Definitions

Each layer has a single owner. A concern belongs in exactly one layer. When ownership is unclear, the rule of thumb is: does this affect the system state or the user session?

### 2.1 Orchestration (`flake.nix`, `flake-modules/`)

Owns: input declarations, `ez-configs` wiring, `globalArgs` injection, perSystem outputs (devshells, checks, apps).

Does **not** own: module logic, package definitions, user preferences, secrets.

### 2.2 Host Composition (`nixos-configurations/<host>/`, `home-configurations/<user>/`)

Owns: feature enable flags, host-specific overrides, hardware imports, user-host wiring.

Does **not** own: implementation of any feature. A host config file should be a list of `features.<x>.<y>.enable = true` declarations and nothing more.

### 2.3 NixOS Core (`nixos-modules/core/`)

Owns: base system configuration that every host needs unconditionally: nix settings, users, networking, fonts, essential programs, base packages.

Does **not** own: optional features, desktop session logic, user-space tooling.

### 2.4 NixOS Features (`nixos-modules/features/`)

Owns: optional system-level capabilities gated behind `options.features.<category>.<name>.enable`. Each feature module declares its own option and implements `config = lib.mkIf cfg.enable { ... }`.

Categories currently in use: `desktop`, `development`, `hardware`, `security`, `services`, `storage`, `theme`.

Does **not** own: Home Manager user session logic. Display manager configuration lives here; window manager session composition lives in HM features.

### 2.5 Home Manager Core (`home-modules/core/`)

Owns: base user environment every user needs unconditionally: shell init, XDG dirs, base dotfiles, essential user packages.

Does **not** own: optional tools, editor configuration, desktop session.

### 2.6 Home Manager Features (`home-modules/features/`)

Owns: optional user-space capabilities gated by the same `options.features.<category>.<name>.enable` namespace. Categories currently in use: `shell`, `editor`, `terminal`, `desktop`, `ai`.

Does **not** own: system-level service activation. A HM feature may configure a user-facing tool; it must not start systemd system services.

### 2.7 Shared Modules (`shared-modules/`)

Owns: modules that must be imported by **both** NixOS and Home Manager to function correctly. Current residents: `stylix-common.nix`, `workspaces.nix`, `palette.nix`.

Does **not** own: modules that only one layer needs. If a module is only used by HM, it belongs in `home-modules/`. If only by NixOS, in `nixos-modules/`. Moving a module here just to avoid duplication is wrong.

### 2.8 Helper Library (`lib/`)

Owns: pure helper functions with no side effects: color utilities, workspace name formatting, secret validation helpers, option builders, polybar helpers.

Does **not** own: NixOS or HM module logic, package derivations, overlay definitions.

### 2.9 Overlays (`overlays/`)

Owns: all nixpkgs overlay definitions. Overlays should be organized by intent, not lumped into a single file. The three-category convention from `nix-starter-configs` (`additions`, `modifications`, `unstable-packages`) is the target shape.

Does **not** own: feature module logic. An overlay adds or patches packages; it must not configure services or user preferences.

### 2.10 Profiles (`home-modules/profiles.nix`)

Owns: named package bundles that a user can enable as a unit (e.g., `core`, `dev`, `desktop`, `extras`, `ai`). Profiles are additive and orthogonal to feature flags.

Does **not** own: system-level packages, service configuration.

### 2.11 Secrets (`secrets/`)

Owns: sops-encrypted secret files. Secret *configuration* (which files, which keys) belongs in the module that consumes the secret, not scattered across unrelated modules.

---

## 3. Target Taxonomy

The directory tree below is the target state. Paths marked `[stable]` are preserved anchors from Section 1. Paths marked `[refactor target]` are candidates for structural improvement in later waves. Paths marked `[current]` are correct and should not change.

```
flake.nix                          [stable] orchestration root
flake-modules/                     [stable] perSystem outputs
  default.nix
  devshells.nix
  apps.nix
  checks.nix

nixos-configurations/              [current] host intent declarations
  bandit/
    default.nix

home-configurations/               [current] user intent declarations
  vino/
    default.nix
    hosts/
      bandit.nix

nixos-modules/                     [stable import surface]
  default.nix                      [stable]
  core/                            [current]
    default.nix
  features/                        [stable aggregator]
    default.nix
    desktop/
    development/
    hardware/
    security/
    services/
    storage/
    theme/

home-modules/                      [stable import surface]
  default.nix                      [stable]
  profiles.nix                     [current]
  core/                            [current]
    default.nix
  features/                        [stable aggregator]
    default.nix
    shell/
    editor/
    terminal/
    desktop/
    ai/

shared-modules/                    [stable] cross-layer modules
  stylix-common.nix
  workspaces.nix
  palette.nix

overlays/                          [refactor target] split by intent
  custom-packages.nix              -> target: additions.nix, modifications.nix

lib/                               [stable] pure helpers
  default.nix

secrets/                           [current] sops-encrypted files
```

---

## 4. Migration Guardrails (Forbidden Patterns)

These patterns are explicitly forbidden across all refactor waves. A task that would introduce any of them must be rejected or redesigned.

### 4.1 No dynamic import or hidden dynamic imports

Modules must not use `builtins.readDir`, `lib.filesystem.listFilesRecursive`, or similar mechanisms to auto-discover and import other modules at evaluation time. All imports must be explicit and traceable by reading `default.nix` files. **Hidden dynamic imports** break the ability to audit the import tree and make it impossible to reason about what a host configuration actually includes.

### 4.2 No HM/NixOS concern mixing

A NixOS module must not configure user-space dotfiles, user packages, or Home Manager options. A Home Manager module must not activate system services, set system-level options, or reference `config.system.*`. **HM/NixOS concern mixing** produces modules that are impossible to test in isolation and creates hidden coupling between layers.

### 4.3 No overlay scattering across feature modules

Overlay definitions must live exclusively in `overlays/`. A feature module that needs a custom package must reference it as `pkgs.<name>` (available because the overlay is loaded at the flake level), not define the package inline or add a new overlay from within the module. **Overlay scattering** across feature modules makes it impossible to audit what packages are being patched or added.

### 4.4 No same-wave namespace churn plus file moves

Within a single refactor wave, a task must not both rename option namespaces (e.g., `features.desktop.i3` to `features.desktop.wm`) and move the files that implement those options. **Namespace churn** combined with file moves in the same wave makes it impossible to bisect regressions. Rename first in one wave; move files in the next.

### 4.5 No collapsing layers into monolithic files

Splitting a large module into smaller single-responsibility files is always preferred over merging files for brevity. A module that configures more than one independent concern is a candidate for splitting, not a virtue.

### 4.6 No hostname-based implicit behavior

Feature activation must come from explicit `features.<category>.<name>.enable = true` declarations in host configurations. A module must not inspect `config.networking.hostName` or similar to change its behavior implicitly.

---

## 5. Transitional Boundaries

Some paths are currently correct but will change shape in later waves. This section names them so implementers know what is stable now versus what will move.

| Path | Current state | Target state | Wave |
|------|--------------|-------------|------|
| `overlays/custom-packages.nix` | Single file, mixed concerns | Split into `additions.nix`, `modifications.nix` | Overlay wave |
| `nixos-modules/core/` | Functional but may contain some feature-adjacent logic | Strictly unconditional system baseline only | Boundary cleanup wave |
| `home-modules/core/` | Functional | Same as above for user baseline | Boundary cleanup wave |
| `secrets/` | Functional | Potentially add dedicated module structure for secret consumers | Secrets wave |

During any wave, only the paths listed as targets for that wave should change. Paths not listed for a wave are off-limits.

---

## 6. Selective Adoption from Reference Repos

This section records the guidance from the reference study (`docs/superpowers/specs/2026-05-13-refactor-reference-study.md`) so it is embedded in the contract.

### Adopt from `dustinlyons/nixos-config`

- Clear platform/domain separation by directory structure (already present; reinforce, don't weaken)
- Secrets in dedicated modules rather than mixed into unrelated feature modules
- Overlay loading patterns that reduce manual flake wiring
- Composition-first Home Manager assembly (smaller modules, not monolithic files)

### Adopt from `Misterio77/nix-starter-configs`

- Three-overlay convention: `additions`, `modifications`, `unstable-packages`
- Hardware-specific state isolated from broader host intent
- Starter-friendly clarity: even advanced repos benefit from readable module registry files

### Do Not Adopt

- Hardcoded user or host assumptions
- Hostname-based implicit behavior
- Collapsing `shared-modules/`, `lib/`, or flake modularization depth to match a simpler starter layout
- Removing feature-toggle flexibility in favor of ad-hoc host logic
- Darwin-specific patterns (this repo is Linux-only for now)

---

## 7. Anti-Goals

The refactor must not produce any of the following outcomes:

- A flattened repo that resembles a generic starter template
- Loss of `shared-modules/` or `lib/` as meaningful abstractions
- Replacement of feature toggles with hostname conditionals
- A single large `configuration.nix` or equivalent monolith
- Documentation that drifts from the actual code state

---

## 8. Verification Checklist

Before marking any refactor wave complete, verify:

- [ ] `flake.nix`, `nixos-modules/default.nix`, and `home-modules/default.nix` are unchanged (stable migration surfaces)
- [ ] No new `builtins.readDir` or dynamic import calls introduced (no hidden dynamic imports)
- [ ] No NixOS module sets HM options; no HM module activates system services (no HM/NixOS concern mixing)
- [ ] All overlay definitions remain in `overlays/` (no overlay scattering)
- [ ] No option namespace rename and file move in the same wave (no namespace churn)
- [ ] `just qa` passes (format + lint + flake checks)
- [ ] Architecture docs updated to match any structural changes made
