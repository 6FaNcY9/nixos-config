# Refactor Planning Notes: nix-starter-configs Analysis

**Date**: May 13, 2026  
**Task**: Extract architecture and patterns from nix-starter-configs for refactoring guidance  
**Status**: ✅ Complete

---

## DELIVERABLES

Three documentation files have been created in `docs/`:

1. **`nix-starter-configs-analysis.md`** (571 lines)
   - Comprehensive breakdown of repository structure
   - Detailed flake architecture patterns
   - Module organization patterns
   - Architectural decisions with tradeoffs
   - Comparison with your current structure
   - 10 strongest takeaways
   - Specific file references and code examples

2. **`nix-starter-refactor-summary.md`** (179 lines)
   - Executive summary for quick reference
   - 10 strongest takeaways with actions
   - What doesn't transfer well
   - Quick refactor checklist
   - Key files reference table

3. **`nix-starter-patterns-reference.md`** (Quick lookup guide)
   - Pattern-by-pattern reference
   - When to use each pattern
   - Code examples for each pattern
   - Decision tree for adoption
   - Comparison table: your config vs nix-starter-configs

---

## KEY FINDINGS

### Your Config Strengths (Keep These)
1. ✅ `shared-modules/` — Not in nix-starter-configs, enables code reuse
2. ✅ `lib/` — Custom Nix functions, not in nix-starter-configs
3. ✅ `flake-modules/` — Modular flake.nix, not in nix-starter-configs
4. ✅ Host-specific overrides (`home-configurations/vino/hosts/bandit.nix`)
5. ✅ Multi-host, multi-user support (nix-starter-configs assumes single of each)
6. ✅ sops-nix secrets management (nix-starter-configs has none)
7. ✅ Module registry pattern (already using correctly)

### Patterns to Consider Adopting
1. 🔄 **Three-overlay convention** — Separate additions, modifications, unstable
   - Current: Single `overlays/custom-packages.nix`
   - Benefit: Clearer intent, easier to understand
   - Effort: Medium (refactor overlays)

2. 🔄 **Hardware config separation** — Keep `hardware-configuration.nix` separate
   - Current: Likely inline in `nixos-configurations/bandit/default.nix`
   - Benefit: Prevents accidental overwrites
   - Effort: Low (extract to separate file)

3. 🔄 **Unstable packages access** — `pkgs.unstablePkgs.package-name` pattern
   - Current: Unknown (check if you need this)
   - Benefit: Clean namespace for unstable packages
   - Effort: Low (add to overlays)

### Patterns You Already Use Correctly
1. ✅ Module registry aggregation
2. ✅ Flake inputs injection (`specialArgs`)
3. ✅ Opinionated nix settings (flakes-first)
4. ✅ Overlay application in NixOS and HM
5. ✅ Multi-architecture support

### What NOT to Adopt
1. ❌ Minimal/standard split — Your config is already full-featured
2. ❌ Single-host assumption — You support multiple hosts
3. ❌ Single-user assumption — You support multiple users
4. ❌ Lack of secrets management — Keep your sops-nix

---

## REFACTOR DECISION MATRIX

| Pattern | Adopt? | Effort | Benefit | Priority |
|---------|--------|--------|---------|----------|
| Three-overlay convention | Maybe | Medium | Clarity | Low |
| Hardware config separation | Yes | Low | Maintainability | Medium |
| Unstable packages access | Maybe | Low | Convenience | Low |
| Module registry (current) | Keep | None | Already using | N/A |
| Flake inputs injection | Keep | None | Already using | N/A |
| Opinionated nix settings | Keep | None | Already using | N/A |

---

## NEXT STEPS

### Phase 1: Documentation (DONE ✅)
- [x] Extract nix-starter-configs architecture
- [x] Create comprehensive analysis
- [x] Create executive summary
- [x] Create pattern reference guide

### Phase 2: Verification (TODO)
- [ ] Audit your current `flake.nix` against nix-starter-configs patterns
- [ ] Confirm you're using `specialArgs` for flake inputs injection
- [ ] Confirm you're using opinionated nix settings
- [ ] Check if hardware config is separated or inline

### Phase 3: Optional Refactoring (TODO)
- [ ] Decide: Adopt three-overlay convention? (Y/N)
- [ ] Decide: Separate hardware config? (Y/N)
- [ ] Decide: Add unstable packages access? (Y/N)
- [ ] If yes to any above, create refactoring plan

### Phase 4: Documentation Update (TODO)
- [ ] Update `CLAUDE.md` with refactoring decisions
- [ ] Document any new patterns adopted
- [ ] Update architecture diagrams if applicable

---

## REFERENCE STRUCTURE

### nix-starter-configs Layout
```
nix-starter-configs/
├── minimal/              # Minimal template (bare-bones)
│   ├── flake.nix
│   ├── nixos/configuration.nix
│   ├── nixos/hardware-configuration.nix
│   └── home-manager/home.nix
└── standard/             # Standard template (full-featured)
    ├── flake.nix
    ├── nixos/configuration.nix
    ├── nixos/hardware-configuration.nix
    ├── home-manager/home.nix
    ├── modules/
    │   ├── nixos/default.nix
    │   └── home-manager/default.nix
    ├── overlays/default.nix
    └── pkgs/default.nix
```

### Your Config Layout
```
nixos-config/
├── flake.nix
├── nixos-configurations/
│   └── bandit/default.nix
├── nixos-modules/
│   └── default.nix
├── home-configurations/
│   ├── vino/default.nix
│   └── vino/hosts/bandit.nix
├── home-modules/
│   └── default.nix
├── shared-modules/       # ✅ Your addition
├── overlays/
│   └── custom-packages.nix
├── lib/                  # ✅ Your addition
├── flake-modules/        # ✅ Your addition
└── secrets/              # ✅ Your addition (sops-nix)
```

---

## EXACT FILE REFERENCES

### Three-Overlay Convention
- **File**: `standard/overlays/default.nix`
- **Lines**: 1-24
- **Pattern**: `additions`, `modifications`, `unstable-packages`

### Custom Packages
- **File**: `standard/pkgs/default.nix`
- **Lines**: 1-5
- **Pattern**: `pkgs: { example = pkgs.callPackage ./example { }; }`

### Module Registry
- **File**: `standard/modules/nixos/default.nix`
- **Lines**: 1-6
- **Pattern**: Comment + empty object with commented example

### Flake Exports
- **File**: `standard/flake.nix`
- **Lines**: 37-49
- **Pattern**: `packages`, `overlays`, `nixosModules`, `homeManagerModules`

### Opinionated Nix Settings
- **File**: `standard/nixos/configuration.nix`
- **Lines**: 54-59
- **Pattern**: `nix.settings.experimental-features`, `flake-registry`, `channel.enable`

### Hardware Config Separation
- **File**: `standard/nixos/configuration.nix`
- **Lines**: 23
- **Pattern**: `imports = [./hardware-configuration.nix];`

### Unstable Packages Access
- **File**: `standard/overlays/default.nix`
- **Lines**: 16-23
- **Pattern**: `unstablePkgs = import inputs.nixpkgs-unstable { ... }`

---

## QUESTIONS FOR NEXT PHASE

1. **Three-overlay convention**: Do you have multiple types of package modifications that would benefit from separation?

2. **Hardware config**: Is your hardware config currently inline or separate?

3. **Unstable packages**: Do you need access to unstable packages? If so, how do you currently handle it?

4. **Flake inputs**: Are you using `specialArgs` to inject flake inputs into modules?

5. **Nix settings**: Are you using the opinionated nix settings (flakes-first)?

6. **Shared modules**: What patterns do you use in `shared-modules/`? Should this be documented?

7. **Lib utilities**: What helper functions are in `lib/`? Should these be documented?

8. **Flake modules**: How are you organizing `flake-modules/`? Should this be documented?

---

## DOCUMENTATION FILES

- **Full analysis**: `docs/nix-starter-configs-analysis.md`
- **Executive summary**: `docs/nix-starter-refactor-summary.md`
- **Pattern reference**: `docs/nix-starter-patterns-reference.md`
- **This file**: `docs/REFACTOR-NOTES.md`

---

**Created**: May 13, 2026  
**Repository analyzed**: https://github.com/Misterio77/nix-starter-configs  
**Status**: Ready for Phase 2 (Verification)

