# Home Modules Refactor Plan
**Date**: 2026-02-24  
**Status**: Draft  
**Estimated effort**: 8–12h, ~20 atomic commits  
**Branch**: `refactor/home-modules`  

---

## Background

The `nixos-modules` side was fully refactored to use `features.<category>.<name>.enable` options
(see `docs/plans/2026-02-18-explicit-modules-design.md`). The `home-modules` side was never
completed — Phase 3 (home migrations) and Phase 5 (docs) were abandoned. This document is the
complete plan for finishing the job.

---

## Design Decisions

These resolve the four gaps left open in the original plan.

### D1 — `profiles.*` and `features.*` coexist

- `profiles.*` stays unchanged → controls **package bundles** only
  (`corePkgs`, `devPkgs`, `desktopPkgs`, `extrasPkgs`, `aiPkgs`)
- `features.*` new → controls **configuration modules** (programs, services, dotfiles)
- All `lib.mkIf config.profiles.desktop` conditions in desktop modules are **replaced** with
  per-module `lib.mkIf cfg.enable`
- The existing `options.clipboard.enable` is migrated to `features.desktop.clipboard.enable`
  (removing its `default = config.profiles.desktop` dependency)

### D2 — Naming convention: `features.<category>.<name>`

Identical to `nixos-modules`. No `features.home.*` prefix.  
Four categories: `desktop`, `shell`, `editor`, `terminal`

### D3 — What goes in `core/`

Always-on infrastructure with zero toggle logic:

| File | Destination |
|------|-------------|
| `devices.nix` | `core/devices.nix` (already options-only, no change) |
| `nixpkgs.nix` | `core/nixpkgs.nix` |
| `package-managers.nix` | `core/package-managers.nix` |
| `secrets.nix` | `core/secrets.nix` (needed by shell.fish, so always-on) |

`profiles.nix` stays at the top level — it is not infrastructure, it's a toggleable profile
system that already works correctly.

### D4 — `_module.args` are untouched

All injected args in `home-configurations/vino/default.nix` stay exactly as-is:
`palette`, `workspaces`, `c`, `stylixFonts`, `i3Pkg`, `codexPkg`, `opencodePkg`,
`hostname`, `cfgLib`. These are consumed by feature modules the same way they are today.

### D5 — Migration strategy per module

1. Create `features/<cat>/<name>.nix` with full implementation + `options.features.<cat>.<name>.enable`
2. Swap old import for new in `home-modules/default.nix` (comment out old, add new)
3. Add `features.<cat>.<name>.enable = true` in `home-configurations/vino/hosts/bandit.nix`
4. Run `verify.sh`
5. Commit

**No dual-import.** The old and new module are never both active simultaneously — this avoids
config conflicts.

### D6 — Feature defaults

All `features.*` options default to `false`. `bandit.nix` enables each one explicitly.
This matches the `nixos-modules` pattern exactly.

---

## Complete Feature Map

| Feature option | Source file | Key args consumed |
|----------------|-------------|-------------------|
| `features.shell.git` | `shell/git.nix` | — |
| `features.shell.fish` | `shell/shell.nix` | `repoRoot`, `hostname`, `username` |
| `features.shell.starship` | `shell/starship.nix` | `c` |
| `features.editor.nixvim` | `editor/nixvim/` | — |
| `features.terminal.alacritty` | `terminal/alacritty.nix` | — |
| `features.terminal.tmux` | `terminal/tmux/` | — |
| `features.terminal.yazi` | `terminal/yazi/` | `palette` |
| `features.desktop.services` | `desktop/services.nix` | `palette` |
| `features.desktop.clipboard` | `desktop/clipboard.nix` | — |
| `features.desktop.lock` | `desktop/lock/` | `palette`, `cfgLib` |
| `features.desktop.firefox` | `desktop/firefox.nix` | `c`, `cfgLib`, `username` |
| `features.desktop.xfce-session` | `desktop/xfce-session.nix` | — |
| `features.desktop.i3` | `desktop/i3/` | `i3Pkg` |
| `features.desktop.polybar` | `desktop/polybar/` | `config.devices.*` |
| `features.desktop.rofi` | `desktop/rofi/` | `palette`, `c`, `cfgLib`, `stylixFonts` |

**15 feature modules total.**

---

## Phase 0 — Setup

### 0.1 Git worktree

```bash
git worktree add ../nixos-config-hm-refactor -b refactor/home-modules
cd ../nixos-config-hm-refactor
```

### 0.2 Create `verify.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/3] flake check ==="
nix flake check

echo "=== [2/3] home-manager build ==="
home-manager build --flake .#vino@bandit

echo "=== [3/3] nixos build (regression check) ==="
nixos-rebuild build --flake .#bandit

echo "=== All checks passed! ==="
```

### 0.3 Baseline snapshot

```bash
home-manager build --flake .#vino@bandit --no-link 2>/dev/null \
  | xargs nix-store -q --references \
  > /tmp/hm-refactor-baseline.txt
```

---

## Phase 1 — Directory skeleton (non-breaking)

**No functional change.** Create new dirs with empty `default.nix` aggregators.

### Directory structure to create

```
home-modules/
  core/
    default.nix      # imports nothing yet
  features/
    default.nix      # imports nothing yet
    desktop/
      default.nix    # imports nothing yet
    shell/
      default.nix    # imports nothing yet
    editor/
      default.nix    # imports nothing yet
    terminal/
      default.nix    # imports nothing yet
```

### Update `home-modules/default.nix`

Add at the end of imports:
```nix
./core
./features
```

Each stub contains exactly `{ imports = []; }` — Nix requires an importable file, not a truly empty file.

```
verify.sh → commit: "refactor(home): add features/ and core/ skeleton"
```

---

## Phase 2 — Migrate infrastructure to `core/`

Copy files into `core/`, update `core/default.nix` to import them, remove old flat imports
from `home-modules/default.nix`.

### `core/default.nix`

```nix
{ ... }:
{
  imports = [
    ./devices.nix
    ./nixpkgs.nix
    ./package-managers.nix
    ./secrets.nix
  ];
}
```

Files are copied verbatim — zero content changes.

```
verify.sh → commit: "refactor(home): move infra files to core/"
```

---

## Phase 3 — Shell features (3 commits)

### Module pattern (reference for all phases)

```nix
{ lib, config, ... }:
let
  cfg = config.features.<cat>.<name>;
in
{
  options.features.<cat>.<name> = {
    enable = lib.mkEnableOption "<description>";
  };

  config = lib.mkIf cfg.enable {
    # ... existing config verbatim ...
  };
}
```

### 3.1 `features.shell.git`

- New file: `features/shell/git.nix`
- Content: wrap `shell/git.nix` in the module pattern above
- Swap import in `shell/default.nix` (comment out `./git`, add to features/shell/default.nix)
- Add `features.shell.git.enable = true;` in `bandit.nix`
- `verify.sh` → commit: `"feat(home): migrate shell.git to feature module"`

### 3.2 `features.shell.fish`

- New file: `features/shell/fish.nix`
- Note: uses `repoRoot`, `hostname`, `username` — `repoRoot` and `username` are injected via
  `extraSpecialArgs` in `nixos-modules/home-manager.nix` (not `_module.args`). Already available.
- `verify.sh` → commit: `"feat(home): migrate shell.fish to feature module"`

### 3.3 `features.shell.starship`

- New file: `features/shell/starship.nix`
- Uses `c` (colors) — available via `_module.args`
- Update `features/shell/default.nix` to import all 3
- `verify.sh` → commit: `"feat(home): migrate shell.starship to feature module"`

---

## Phase 4 — Editor (1 commit)

### 4.1 `features.editor.nixvim`

- New dir: `features/editor/nixvim/` — copy all 7 sub-files verbatim
- Wrapper `features/editor/nixvim/default.nix`:

```nix
{ lib, config, ... }:
let cfg = config.features.editor.nixvim; in
{
  options.features.editor.nixvim.enable = lib.mkEnableOption "nixvim editor";
  config = lib.mkIf cfg.enable {
    imports = [ ./options.nix ./autocmds.nix ./highlights.nix ./ui.nix
                ./plugins ./keymaps ./extra-config.nix ];
    programs.nixvim.enable = true;
  };
}
```

- `features/editor/default.nix` imports `./nixvim`
- Add `features.editor.nixvim.enable = true;` in `bandit.nix`
- `verify.sh` → commit: `"feat(home): migrate editor.nixvim to feature module"`

---

## Phase 5 — Terminal features (3 commits)

### 5.1 `features.terminal.alacritty`

- New file: `features/terminal/alacritty.nix`
- No args needed
- `verify.sh` → commit: `"feat(home): migrate terminal.alacritty to feature module"`

### 5.2 `features.terminal.tmux`

- New dir: `features/terminal/tmux/` — copy sub-files verbatim
- `verify.sh` → commit: `"feat(home): migrate terminal.tmux to feature module"`

### 5.3 `features.terminal.yazi`

- New dir: `features/terminal/yazi/` — uses `palette` arg
- Update `features/terminal/default.nix` to import all 3
- `verify.sh` → commit: `"feat(home): migrate terminal.yazi to feature module"`

---

## Phase 6 — Desktop features (8 commits)

All desktop modules currently guard with `lib.mkIf config.profiles.desktop`.
Each one gets its own `features.desktop.*.enable` replacing that guard.
Migration order: simplest → most complex.

### 6.1 `features.desktop.services`

- `desktop/services.nix` → `features/desktop/services.nix`
- Replace `lib.mkIf config.profiles.desktop` with `lib.mkIf cfg.enable`
- Uses `palette`
- `verify.sh` → commit: `"feat(home): migrate desktop.services to feature module"`

### 6.2 `features.desktop.clipboard`

- `desktop/clipboard.nix` → `features/desktop/clipboard.nix`
- **Breaking change in option name**: `options.clipboard.enable` → `options.features.desktop.clipboard.enable`
- Remove `default = config.profiles.desktop` → `default = false` (explicit in bandit.nix)
- Verified: `config.clipboard.enable` has zero consumers outside `clipboard.nix` itself — safe rename.
- `verify.sh` → commit: `"feat(home): migrate desktop.clipboard to feature module"`

### 6.3 `features.desktop.lock`

- `desktop/lock/` → `features/desktop/lock/`
- Uses `palette`, `cfgLib.mkShellScript`
- `verify.sh` → commit: `"feat(home): migrate desktop.lock to feature module"`

### 6.4 `features.desktop.firefox`

- `desktop/firefox.nix` → `features/desktop/firefox.nix`
- Uses `c`, `cfgLib.mkColorReplacer`, `username`
- `verify.sh` → commit: `"feat(home): migrate desktop.firefox to feature module"`

### 6.5 `features.desktop.xfce-session`

- `desktop/xfce-session.nix` → `features/desktop/xfce-session.nix`
- No external args
- `verify.sh` → commit: `"feat(home): migrate desktop.xfce-session to feature module"`

### 6.6 `features.desktop.i3`

- `desktop/i3/` → `features/desktop/i3/` (copy all sub-files verbatim)
- Uses `i3Pkg` — still injected from `home-configurations/vino/default.nix` via
  `config.features.desktop.i3-xfce.i3Package` on the NixOS side. **No change needed.**
- `verify.sh` → commit: `"feat(home): migrate desktop.i3 to feature module"`

### 6.7 `features.desktop.polybar`

- `desktop/polybar/` → `features/desktop/polybar/` (copy sub-files)
- Uses `config.devices.*` — accessible since `devices.nix` moved to `core/` in Phase 2
- **Note**: `lock/` also uses `config.devices.*` (battery detection) — same, safe for same reason
- `verify.sh` → commit: `"feat(home): migrate desktop.polybar to feature module"`

### 6.8 `features.desktop.rofi`

- `desktop/rofi/` → `features/desktop/rofi/` (copy sub-files)
- Uses `palette`, `c`, `cfgLib.mkColorReplacer`, `stylixFonts`
- Update `features/desktop/default.nix` to import all 8
- `verify.sh` → commit: `"feat(home): migrate desktop.rofi to feature module"`

---

## Phase 7 — `bandit.nix` final state

After Phase 6, `home-configurations/vino/hosts/bandit.nix` should contain:

```nix
{
  # Package profiles (unchanged)
  profiles.extras = true;
  profiles.ai = true;

  # Device hardware (unchanged)
  devices.battery = "BAT1";
  devices.backlight = "amdgpu_bl1";
  devices.networkInterface = "wlp1s0";

  # Shell features
  features.shell.git.enable = true;
  features.shell.fish.enable = true;
  features.shell.starship.enable = true;

  # Editor features
  features.editor.nixvim.enable = true;

  # Terminal features
  features.terminal.alacritty.enable = true;
  features.terminal.tmux.enable = true;
  features.terminal.yazi.enable = true;

  # Desktop features
  features.desktop.services.enable = true;
  features.desktop.clipboard.enable = true;
  features.desktop.lock.enable = true;
  features.desktop.firefox.enable = true;
  features.desktop.xfce-session.enable = true;
  features.desktop.i3.enable = true;
  features.desktop.polybar.enable = true;
  features.desktop.rofi.enable = true;
}
```

---

## Phase 8 — Delete old modules (1 commit)

Remove entirely:
```
home-modules/desktop/
home-modules/editor/
home-modules/shell/
home-modules/terminal/
```

Clean up `home-modules/default.nix` — remove all now-dead imports.

```
verify.sh → commit: "refactor(home): remove old flat modules"
```

---

## Phase 9 — Documentation (1 commit)

- Update `docs/FEATURE_MODULES.md` with the home-modules section
- Update `README.md`
- Merge `refactor/home-modules` into main

```
commit: "docs: document home-modules feature system"
```

---

## Phase summary

| Phase | Description | Commits | Risk |
|-------|-------------|---------|------|
| 0 | Setup + verify.sh + baseline | 1 | None |
| 1 | Directory skeleton | 1 | None |
| 2 | Migrate infra to core/ | 1 | Low |
| 3 | Shell features (3 modules) | 3 | Low |
| 4 | Editor (1 module) | 1 | Low |
| 5 | Terminal features (3 modules) | 3 | Low |
| 6 | Desktop features (8 modules) | 8 | Medium |
| 7 | (bandit.nix updated incrementally) | — | — |
| 8 | Delete old modules | 1 | Low (all verified) |
| 9 | Docs + merge | 1 | None |
| **Total** | | **20** | |

---

## Differences from original plan

| Original weakness | Resolution |
|-------------------|------------|
| Home plan too coarse (4 tasks) | 15 granular tasks, one per module |
| `profiles.*` conflict unaddressed | D1: coexist — profiles=packages, features=config |
| Flat infra files not mentioned | D3: devices/nixpkgs/package-managers/secrets → core/ |
| `_module.args` not addressed | D4: all args stay unchanged in vino/default.nix |
| Naming convention undefined | D2: `features.<cat>.<name>` matching nixos exactly |
| Dual-import risk | D5: swap strategy — old and new never coexist |
| `desktop/` underestimated | Explicitly broken into 8 separate feature modules |
