# nix-starter-configs: Refactor Insights (Executive Summary)

**Source**: https://github.com/Misterio77/nix-starter-configs  
**Date**: May 13, 2026

---

## 10 STRONGEST TAKEAWAYS

### 1. ✅ Three-Overlay Convention (ADOPT)
**Pattern**: Separate overlays for `additions` (custom pkgs), `modifications` (overrides), `unstable-packages`

**Why**: Explicit intent, easy to understand what each overlay does, scales well

**Your action**: Consider refactoring `overlays/custom-packages.nix` into three overlays

**Location**: `standard/overlays/default.nix`

---

### 2. ✅ Module Registry Aggregation (ALREADY USING)
**Pattern**: `modules/nixos/default.nix` and `modules/home-manager/default.nix` import individual modules

**Why**: Simple, scalable, one module per file

**Your status**: Already using this pattern in `nixos-modules/` and `home-modules/`

**No action needed**

---

### 3. ✅ Hardware Config Separation (CONSIDER)
**Pattern**: Keep `hardware-configuration.nix` separate from `configuration.nix`

**Why**: Prevents accidental overwrites during config rewrites

**Your action**: Extract hardware config to separate file in `nixos-configurations/bandit/`

**Location**: `standard/nixos/configuration.nix:23`

---

### 4. ✅ Flake Inputs Injection (ALREADY USING)
**Pattern**: `specialArgs = {inherit inputs;}` enables modules to reference flake inputs

**Why**: Allows modules to use `inputs.hardware`, `inputs.nix-colors`, etc.

**Your status**: Likely already using this

**No action needed**

---

### 5. ✅ Opinionated Nix Settings (ALREADY USING)
**Pattern**: Disable channels and global registry for flakes-first philosophy

```nix
nix.settings.experimental-features = "nix-command flakes";
nix.settings.flake-registry = "";
nix.channel.enable = false;
```

**Why**: Prevents confusion, no legacy baggage

**Your status**: Likely already doing this

**Location**: `standard/nixos/configuration.nix:54-59`

---

### 6. ✅ Unstable Packages Access Pattern (CONSIDER)
**Pattern**: Make unstable packages available as `pkgs.unstablePkgs.package-name`

```nix
unstable-packages = final: _prev: {
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = final.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
};
```

**Why**: Clean way to access unstable packages without separate nixpkgs instance

**Your action**: Consider if you need unstable packages access

**Location**: `standard/overlays/default.nix:16-23`

---

### 7. ✅ Your `shared-modules/` is a Strength (KEEP)
**Pattern**: Directory for modules shared between NixOS and Home Manager

**Why**: Code reuse, reduces duplication

**Your status**: Already using this (nix-starter-configs doesn't have this)

**No action needed**

---

### 8. ✅ Your `lib/` Directory is a Strength (KEEP)
**Pattern**: Custom Nix functions and utilities

**Why**: Reusable helpers, cleaner configs

**Your status**: Already using this (nix-starter-configs doesn't have this)

**No action needed**

---

### 9. ✅ Your Host-Specific Overrides Pattern is a Strength (KEEP)
**Pattern**: `home-configurations/vino/hosts/bandit.nix` for per-host overrides

**Why**: More flexible than single `homeConfigurations` entry

**Your status**: Already using this (nix-starter-configs doesn't have this)

**No action needed**

---

### 10. ✅ Your `flake-modules/` is a Strength (KEEP)
**Pattern**: Modular flake.nix using flake-parts or similar

**Why**: Keeps flake.nix organized, easier to maintain

**Your status**: Already using this (nix-starter-configs doesn't have this)

**No action needed**

---

## WHAT DOESN'T TRANSFER

### ❌ Single-Host, Single-User Assumption
nix-starter-configs assumes one host and one user. Your config supports multiple. **Don't simplify.**

### ❌ No Secrets Management
nix-starter-configs has no sops-nix. Your config does. **Keep your sops-nix integration.**

### ❌ No Dev Shell or Testing
nix-starter-configs has no dev shells. Your config may have these. **Don't remove.**

### ❌ No Build Automation
nix-starter-configs has no justfile. Your config does. **Keep your justfile.**

---

## QUICK REFACTOR CHECKLIST

- [ ] **Optional**: Refactor overlays into three-overlay convention
- [ ] **Optional**: Extract hardware config to separate file
- [ ] **Optional**: Add unstable packages access pattern if needed
- [ ] **Verify**: Confirm you're using flake inputs injection (`specialArgs`)
- [ ] **Verify**: Confirm you're using opinionated nix settings (flakes-first)
- [ ] **Keep**: All your existing patterns (shared-modules, lib, flake-modules, host overrides)

---

## FULL ANALYSIS

See `docs/nix-starter-configs-analysis.md` for detailed breakdown with code examples and exact file references.

---

## KEY FILES FROM nix-starter-configs

| File | Key Pattern |
|------|------------|
| `standard/flake.nix:37` | `packages = forAllSystems (system: import ./pkgs ...)` |
| `standard/flake.nix:43` | `overlays = import ./overlays {inherit inputs;}` |
| `standard/overlays/default.nix` | Three-overlay convention |
| `standard/nixos/configuration.nix:28-32` | Overlay application |
| `standard/nixos/configuration.nix:54-59` | Opinionated nix settings |
| `standard/modules/nixos/default.nix` | Module registry template |
| `standard/pkgs/default.nix` | Custom packages template |

