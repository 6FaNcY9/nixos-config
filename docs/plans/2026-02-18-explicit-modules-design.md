# NixOS Config Refactoring: Explicit Module System Design

**Date**: 2026-02-18
**Status**: Approved - Ready for Implementation
**Approach**: Explicit Dependency Graph (Moderate/Recommended)

---

## Executive Summary

**Goal**: Refactor NixOS configuration to improve discoverability, clarify dependencies, fix portability issues, and follow ecosystem best practices—all while preserving existing functionality.

**Problem Statement**: Current pain points:
- **Hard to find things**: Unclear which file contains a specific setting
- **Unclear dependencies**: Not obvious what modules depend on what, or what happens when disabling features
- **Portability issues**: Hardcoded paths prevent config reuse across machines/users
- **15 documented issues**: Critical through low severity, need resolution

**Solution**: Introduce explicit feature modules with:
- `features.*` options namespace for all optional capabilities
- Dependency declarations with assertions
- Clear module organization: `core/` → `features/` → `profiles/`
- Fix all documented issues without changing behavior

**Verification**: Hybrid approach—build + flake check in isolated worktree, then deploy to real hardware for testing.

**Timeline**: 15-20 hours, 25-30 commits over 5 phases

---

## 1. Architecture Overview

### 1.1 Target Directory Structure

```
nixos-config/
├── flake.nix                    # Entry point (ez-configs + flake-parts)
│
├── nixos-configurations/        # ✅ Keep for ez-configs (host configs)
│   └── bandit/
│       ├── default.nix         # Enables features via options
│       └── hardware.nix        # Hardware-specific (disks, boot)
│
├── home-configurations/         # ✅ Keep for ez-configs (user configs)
│   └── vino/
│       ├── default.nix         # Enables user features
│       └── identity.nix        # Git, GPG, email (user-specific)
│
├── nixos-modules/               # 🔄 REORGANIZE: core + features + profiles
│   ├── core/                   # Base system (always enabled, no options)
│   │   ├── nix.nix            # Nix daemon, flakes, gc, nh
│   │   ├── boot.nix           # Bootloader, kernel params
│   │   ├── networking.nix     # Basic networking
│   │   ├── users.nix          # User accounts
│   │   └── default.nix        # Auto-imports all core
│   │
│   ├── features/               # Optional (explicit enable options)
│   │   ├── desktop/
│   │   │   ├── base.nix       # options.features.desktop.enable
│   │   │   ├── i3.nix         # options.features.desktop.i3.enable
│   │   │   ├── compositor.nix # options.features.desktop.compositor.enable
│   │   │   └── default.nix
│   │   ├── development/
│   │   │   ├── base.nix       # options.features.development.enable
│   │   │   ├── containers.nix # options.features.development.containers.enable
│   │   │   └── default.nix
│   │   ├── hardware/
│   │   │   ├── laptop.nix     # options.features.hardware.laptop.enable
│   │   │   ├── printing.nix   # options.features.hardware.printing.enable
│   │   │   └── default.nix
│   │   ├── security/
│   │   │   ├── hardening.nix  # options.features.security.hardening.enable
│   │   │   ├── secrets.nix    # options.features.security.secrets.enable
│   │   │   └── default.nix
│   │   └── services/
│   │       ├── backup.nix     # options.features.services.backup.enable
│   │       ├── monitoring.nix # options.features.services.monitoring.enable
│   │       ├── tailscale.nix  # options.features.services.tailscale.enable
│   │       └── default.nix
│   │
│   ├── profiles/               # Pre-configured bundles
│   │   ├── desktop.nix        # Enables desktop features
│   │   ├── laptop.nix         # Enables laptop features
│   │   └── development.nix    # Enables dev features
│   │
│   └── default.nix             # Imports core + features + profiles
│
├── home-modules/                # 🔄 REORGANIZE: Same pattern as nixos-modules
│   ├── core/                   # Essential user config (always enabled)
│   │   ├── xdg.nix
│   │   ├── packages.nix
│   │   └── default.nix
│   ├── features/               # Optional user features
│   │   ├── desktop/           # i3 config, polybar, rofi
│   │   ├── editor/            # nixvim
│   │   ├── shell/             # zsh, starship, git
│   │   └── terminal/          # alacritty, tmux, yazi
│   ├── profiles/              # User profile bundles
│   └── default.nix
│
├── shared-modules/              # ✅ Keep (NixOS + HM shared code)
│   ├── stylix.nix
│   ├── palette.nix
│   └── workspaces.nix
│
├── lib/                         # ✅ Keep (pure helper functions)
│   └── default.nix             # Single file OK for current size
│
├── overlays/                    # 📝 Split into multiple files
│   ├── stable.nix              # pkgs.stable overlay
│   ├── custom-packages.nix     # Custom package definitions
│   └── default.nix             # Composes all overlays
│
└── flake-modules/               # ✅ Keep (already well-organized)
    ├── _common.nix             # Add more inline docs
    ├── apps.nix                # Remove duplication with packages
    ├── packages.nix            # Build artifacts
    ├── devshells.nix           # Add nix-tree, nix-index, nvd
    ├── services.nix            # Add inline service docs
    ├── pre-commit.nix
    ├── treefmt.nix
    ├── checks.nix
    └── default.nix
```

### 1.2 Key Principles

1. **Explicit over Implicit**: Every feature must be explicitly enabled via `features.*.enable = true`
2. **Dependency Declaration**: Modules declare what they need; NixOS enforces it
3. **Layered Dependencies**: `core` → `features` → `profiles` → `hosts` (dependencies only go down)
4. **Single Responsibility**: Each module does one thing well
5. **Self-Documenting**: Option descriptions explain what, why, and dependencies
6. **ez-configs Compatible**: Keep `nixos-configurations/` and `home-configurations/` for auto-discovery
7. **Research-backed**: Follows patterns from flake-parts docs, nix-starter-configs, NixOS & Flakes Book

### 1.3 What Changes vs. Current Structure

**Keeps**:
- `nixos-configurations/` and `home-configurations/` (ez-configs requirement)
- `shared-modules/` (correct pattern for NixOS + HM theming)
- `lib/` single file (fine for 240 lines)
- `flake-modules/` organization (already well-structured)

**Reorganizes**:
- `nixos-modules/*.nix` → `nixos-modules/{core,features,profiles}/`
- `home-modules/{desktop,editor,shell,terminal}` → `home-modules/features/{desktop,editor,shell,terminal}`
- Add `home-modules/core/` for always-enabled user config

**Splits**:
- `overlays/default.nix` → `stable.nix` + `custom-packages.nix` + `default.nix`
- Large modules (`desktop.nix`, `services.nix`) → focused feature modules

**Adds**:
- Explicit `features.*` options namespace
- Dependency checks with assertions
- Inline documentation in all modules
- New ecosystem tools (nix-tree, nix-index, nvd)

---

## 2. Module System Pattern

### 2.1 The Pattern: Options + Config + Dependencies

Every feature module follows this structure:

```nix
# Example: nixos-modules/features/desktop/i3.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.features.desktop.i3;
in
{
  # 1. DECLARE OPTIONS (what this module provides)
  options.features.desktop.i3 = {
    enable = lib.mkEnableOption "i3 window manager";

    terminal = lib.mkOption {
      type = lib.types.str;
      default = "alacritty";
      description = "Default terminal emulator for i3";
    };
  };

  # 2. DECLARE DEPENDENCIES (what this module needs)
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.features.desktop.enable;
        message = "features.desktop.i3 requires features.desktop.enable = true";
      }
    ];

    # 3. CONFIGURE SYSTEM (only if enabled)
    services.xserver.windowManager.i3 = {
      enable = true;
      package = pkgs.i3;
    };

    environment.systemPackages = with pkgs; [
      i3status
      i3lock
      dmenu
    ];
  };
}
```

### 2.2 How It Solves Pain Points

**Problem B: Hard to find things**

Before:
- Unclear which file contains a setting
- Must grep or remember structure
- No discovery mechanism

After:
```bash
# Method 1: Use nix repl to explore
nix repl
> :lf .
> :t config.features
{ desktop = { enable = ...; i3 = { enable = ...; }; }; ... }

# Method 2: Predictable location
# Want i3? → nixos-modules/features/desktop/i3.nix
# Want backup? → nixos-modules/features/services/backup.nix

# Method 3: nixos-option
nixos-option features.desktop.i3.enable
# Shows: value, type, description, declared in file
```

**Problem C: Unclear dependencies**

Before:
- Not obvious what a module needs
- Silent failures or mysterious breakage
- Must read code to understand

After:
```nix
# In nixos-configurations/bandit/default.nix
features.desktop.i3.enable = true;

# If you forgot desktop.enable, clear error:
# error: Failed assertion: features.desktop.i3 requires features.desktop.enable = true
```

### 2.3 Dependency Declaration Patterns

**Hard Dependencies** (module won't work without them):
```nix
assertions = [
  {
    assertion = config.features.desktop.enable;
    message = "i3 requires desktop base (features.desktop.enable = true)";
  }
];
```

**Soft Dependencies** (warn but allow):
```nix
warnings = lib.optional
  (!config.features.hardware.laptop.enable)
  "i3 power management works best with features.hardware.laptop.enable";
```

**Conditional Behavior** (adapt based on other features):
```nix
config = lib.mkIf cfg.enable {
  services.xserver.windowManager.i3.extraConfig = lib.optionalString
    config.features.hardware.laptop.enable
    ''
      # Laptop-specific i3 config
      bindsym XF86PowerOff exec systemctl suspend
    '';
};
```

### 2.4 Host Configuration Becomes Simple

Before:
```nix
# nixos-configurations/bandit/default.nix
{
  roles = {
    development = true;
    desktop = true;
    laptop = true;
  };
  desktop.variant = "i3-xfce";  # What does this enable? 🤷
}
```

After:
```nix
# nixos-configurations/bandit/default.nix
{
  # Crystal clear what's enabled
  features = {
    desktop = {
      enable = true;
      i3.enable = true;
      compositor.enable = true;
    };
    development = {
      enable = true;
      containers.enable = true;
    };
    hardware.laptop.enable = true;
    security.hardening.enable = true;
    services = {
      tailscale.enable = true;
      backup.enable = false;
      monitoring.enable = false;
    };
  };
}
```

---

## 3. Migration Strategy

### 3.1 Git Workflow: Isolated Worktree

**Setup**:
```bash
# Create refactoring branch in separate directory
git worktree add ../nixos-config-refactor -b refactor/explicit-modules
cd ../nixos-config-refactor

# Main branch stays clean! ✅
```

**Why**: Test aggressively without risk. If broken, just delete worktree.

### 3.2 Phase 0: Setup (15 min)

1. Create worktree (above)
2. Create `verify.sh` script for automated checks
3. Take baseline snapshot:
   ```bash
   nixos-rebuild build --flake .#bandit
   nix-store --query --requisites result | sort > /tmp/baseline.txt
   ```

### 3.3 Phase 1: Non-Breaking Improvements (2-3 hours)

**Quick wins, each a separate commit**:

1. Fix repoRoot portability (Critical issue #1)
2. Split overlays into multiple files
3. Add inline documentation to services
4. Remove apps/packages duplication
5. Fix non-interactive app hazards

**Verification**: `nix flake check` + `nixos-rebuild build`

### 3.4 Phase 2: New Structure (1-2 hours)

**Create new directories alongside old**:
- `mkdir -p nixos-modules/{core,features,profiles}`
- `mkdir -p home-modules/{core,features,profiles}`
- Create empty feature modules
- Update `default.nix` to import both old AND new

**Verification**: System still builds with old `roles.*` API

### 3.5 Phase 3: Migrate Modules (8-12 hours)

**One feature at a time**:
1. Create feature module with options
2. Move logic from old module
3. Update host to use new feature
4. Remove from old module
5. Test
6. Commit

**Migration order** (simplest → complex):
- Services (backup, monitoring, tailscale)
- Hardware (laptop, printing)
- Development (base, containers)
- Desktop (base, i3, compositor)

**Verification**: After each feature, run full checks + compare package list

### 3.6 Phase 4: Remove Old Modules (1 hour)

**Once all migrated**:
- Delete old module files
- Update `default.nix` to import only new structure
- Verify package list identical to baseline

### 3.7 Phase 5: Polish (2-3 hours)

**Final touches**:
- Add ecosystem tools (nix-tree, nix-index, nvd)
- Create documentation guides
- Update README
- Final verification

**Timeline**: 15-20 hours total, 25-30 commits

---

## 4. Verification Plan

### 4.1 Automated Verification (Every Commit)

```bash
#!/usr/bin/env bash
# verify.sh - Run after every commit

nix flake check
nixos-rebuild build --flake .#bandit
nix build .#homeConfigurations.vino@bandit.activationPackage
nix build .#packages.x86_64-linux.commit-tool
nix develop .#web --command echo "OK"
```

### 4.2 Per-Phase Verification

**Phase 1**: All checks pass, no new warnings, minimal diff from main

**Phase 2**: New directories exist, both old and new modules work

**Phase 3**: After each feature migration:
- All checks pass
- Closure size unchanged (±10MB)
- Dependency count similar
- Feature works correctly

**Phase 4**: Old modules removed, package list identical to baseline

**Phase 5**: New tools work, documentation exists

### 4.3 Real Hardware Testing (Hybrid Approach)

**When ready**:
```bash
# In worktree
sudo nixos-rebuild test --flake .#bandit
# Or: sudo nixos-rebuild switch --flake .#bandit
```

**Test checklist**:
- Desktop: i3, polybar, rofi
- Terminal: alacritty, tmux, colors
- Editor: neovim, plugins
- Development: direnv, docker
- Hardware: bluetooth, power, suspend
- Services: tailscale
- Theming: stylix colors
- Git: signing, GPG key

### 4.4 Success Criteria

✅ Builds cleanly (no warnings/errors)
✅ Behavior unchanged (same packages, services, closure size)
✅ Discoverability improved (nixos-option features works)
✅ Dependencies explicit (clear errors if missing)
✅ Documentation complete (inline + guides)

---

## 5. Known Issues Resolution

### 5.1 Critical Issues (2)

**Issue #1: Hardcoded repoRoot** (Phase 1)
```nix
# Solution: Make overridable
repoRoot = lib.mkDefault "/home/${username}/src/nixos-config";
```

**Issue #2: Hardcoded username** (Phase 5)
- Document as known limitation for single-user setup
- Already auto-derived from directory name

### 5.2 High Issues (3)

**Issue #3: Update automation dirty tree** (Phase 3)
- Fix: Commit flake.lock in same transaction as update

**Issue #4: Non-interactive apps** (Phase 1)
- Fix: Add CI mode detection, non-interactive flags

**Issue #5: osConfig coupling** (Phase 3)
- Fix: Add fallbacks when `osConfig ? null`

### 5.3 Medium Issues (3)

**Issue #6: GPG split-brain** (Phase 3)
- Fix: Define GPG key once in `users/vino/identity.nix`

**Issue #7: Stylix sprawl** (Already correct)
- Keep in `shared-modules/stylix-common.nix`

**Issue #8: Import duplication** (Phase 2)
- Fix: Import modules once in `default.nix`

### 5.4 Low Issues (7)

**Issues #9-15**: Minor consistency issues (Phase 5)
- Add descriptions to all options
- Standardize naming
- Add inline documentation

**Result**: 15/15 issues resolved (13 fixed, 2 documented)

---

## 6. Research Findings Summary

### 6.1 flake-parts Ecosystem

**Current usage**: Comprehensive ✅
- ez-configs, treefmt-nix, pre-commit-hooks, devshell, process-compose-flake, services-flake

**Recommendation**: No major modules missing

### 6.2 Module Organization Patterns

**shared-modules/**: ✅ Correct pattern for theming shared between NixOS + HM

**overlays/**: Split into stable.nix + custom-packages.nix (better organization)

**lib/**: Single file OK for current size (~240 lines)

### 6.3 devShells vs apps vs packages

**Clear separation**:
- packages = Build artifacts
- apps = Runnable shortcuts (reference packages)
- devShells = Full development environments

**Fix**: Apps should reference packages (no duplication)

### 6.4 Development Services

**services-flake**: 30+ services (PostgreSQL, Redis, etc.)

**Improvement**: Add inline documentation explaining what/where/how

### 6.5 NixOS Ecosystem Tools

**Already using**: nh, nom, direnv, statix, deadnix, treefmt ✅

**Add to nix-debug shell**: nix-tree, nix-index, manix, nvd

---

## 7. Design Principles

1. **KISS (Keep It Simple Stupid)**: Simplify without over-engineering
2. **Preserve Behavior**: All current features work identically
3. **Explicit Dependencies**: Clear what depends on what
4. **Self-Documenting**: Code and options tell the story
5. **Incremental Migration**: Small, safe, testable steps
6. **Research-Backed**: Follow ecosystem best practices
7. **ez-configs Compatible**: Work within the framework

---

## 8. References

**flake-parts**:
- [flake-parts built-in modules](https://github.com/hercules-ci/flake-parts/tree/main/modules)
- [flake-parts documentation](https://flake.parts)
- [Overlays guide](https://flake.parts/overlays)
- [easyOverlay](https://flake.parts/options/flake-parts-easyoverlay)

**NixOS Best Practices**:
- [NixOS & Flakes Book - Modularize Configuration](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration)
- [NixOS & Flakes Book - Home Manager](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/start-using-home-manager)
- [Mastering Nixpkgs Overlays](https://nixcademy.com/posts/mastering-nixpkgs-overlays-techniques-and-best-practice/)
- [Understanding NixOS Modules](https://britter.dev/blog/2025/01/09/nixos-modules/)

**Development Services**:
- [services-flake documentation](https://community.flake.parts/services-flake)
- [process-compose-flake](https://community.flake.parts/process-compose-flake)
- [Replacing docker-compose with Nix](https://nixos.asia/en/blog/replacing-docker-compose)

**Configuration Examples**:
- [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs)
- [NixOS Wiki - Flakes](https://wiki.nixos.org/wiki/Flakes)

**Ecosystem Tools**:
- [nh - Nix Helper](https://github.com/nix-community/nh)
- [nix-output-monitor](https://discourse.nixos.org/t/announcing-nix-output-monitor-2-0/22668)

---

## Appendix A: Example Feature Module (Complete)

```nix
# nixos-modules/features/services/tailscale.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.features.services.tailscale;
in
{
  options.features.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN";

    exitNode = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Tailscale exit node to use (optional)";
      example = "exit-node-hostname";
    };

    useRoutingFeatures = lib.mkOption {
      type = lib.types.enum [ "none" "client" "server" "both" ];
      default = "client";
      description = "Enable routing features (subnet routes, exit nodes)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Tailscale service
    services.tailscale = {
      enable = true;
      useRoutingFeatures = cfg.useRoutingFeatures;
    };

    # Firewall: Allow Tailscale
    networking.firewall = {
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ]; # Tailscale port
    };

    # Optional: Auto-connect to exit node
    systemd.services.tailscale-exit-node = lib.mkIf (cfg.exitNode != null) {
      description = "Tailscale exit node configuration";
      after = [ "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];

      script = ''
        ${pkgs.tailscale}/bin/tailscale up --exit-node=${cfg.exitNode}
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
```

---

**Next Steps**: Proceed to implementation planning with `writing-plans` skill.
