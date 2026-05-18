# Architecture Documentation

Comprehensive architectural analysis of the nixos-config repository.

## 📋 Documents

| Document | Purpose | Lines | Size |
|----------|---------|-------|------|
| **[components.md](./components.md)** | Complete inventory of all .nix files organized by architectural layer | 289 | 18KB |
| **[diagram.md](./diagram.md)** | Visual architecture diagram (Mermaid + ASCII) showing system wiring and data flow | 380 | 22KB |
| **[patterns.md](./patterns.md)** | Documentation of 6 major architectural patterns with examples and anti-patterns | 521 | 17KB |
| **[refactor-contract.md](./refactor-contract.md)** | Target-state architecture contract: preserved anchors, layer ownership, migration guardrails, and forbidden patterns for all refactor waves | 261 | ~12KB |

**Total:** 4 documents covering all architectural layers (counts vary as docs are updated)

---

## 🎯 Quick Start

### For New Contributors
1. Start with **[diagram.md](./diagram.md)** to understand the overall architecture
2. Review **[patterns.md](./patterns.md)** to learn the conventions used
3. Consult **[components.md](./components.md)** when you need to find specific functionality

### For Maintainers
1. Read **[refactor-contract.md](./refactor-contract.md)** before making any structural changes
2. Check **[patterns.md](./patterns.md)** for established conventions
3. Consult **[components.md](./components.md)** for the current file inventory

### For System Understanding
1. **[diagram.md](./diagram.md)** → High-level system flow
2. **[patterns.md](./patterns.md)** → Design decisions and conventions
3. **[components.md](./components.md)** → Detailed file-by-file reference
4. **[refactor-contract.md](./refactor-contract.md)** → Migration law and layer ownership

---

## 📊 Repository Overview

### Statistics
- **Total Files:** 128 .nix files
- **Layers:** 7 architectural layers (Flake → NixOS → Home Manager)
- **Modules:** 36 NixOS modules, 65 Home Manager modules, 4 shared modules
- **Configurations:** 2 hosts (bandit, homelab), 1 user (vino)
- **Patterns:** 6 major architectural patterns documented
- **Issues:** No open issues in canonical architecture docs

### Architecture Highlights
- **Flake-based** using flake-parts + ez-configs for auto-discovery
- **Feature system** for system capabilities (desktop/laptop/server/development) via `features.*` options
- **Profile system** for user package preferences (core/dev/desktop/extras/ai) via `profiles.*` options
- **Theming** via Stylix with Gruvbox Dark Pale palette + semantic color layer
- **Secrets** managed with sops-nix + validation helpers
- **Modular structure** with clear separation: NixOS (system) / Home Manager (user) / Shared (both)

---

## 🗂️ Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        flake.nix                            │
│                  (Entry point + orchestrator)               │
└─────────────────────────────────────────────────────────────┘
                             ↓
┌─────────────────────────────────────────────────────────────┐
│                     flake-parts                             │
│              (Framework + perSystem wiring)                 │
└─────────────────────────────────────────────────────────────┘
                             ↓
┌──────────────────────┬──────────────────────────────────────┐
│    ez-configs        │     flake-modules/                   │
│  (Auto-discovery)    │  (Apps, DevShells, Checks, QA)       │
└──────────────────────┴──────────────────────────────────────┘
                             ↓
┌──────────────────────┬──────────────────────────────────────┐
│ nixosConfigurations  │    homeConfigurations                │
│      (System)        │         (User)                       │
└──────────────────────┴──────────────────────────────────────┘
                             ↓
┌──────────────────────┬──────────────────────────────────────┐
│  nixos-modules/      │      home-modules/                   │
│  (36 modules)        │      (65 modules)                    │
└──────────────────────┴──────────────────────────────────────┘
                             ↓
                  shared-modules/
        (Stylix, Palette, Workspaces)
```

---

## 🔍 Finding Things

### By Use Case

| I want to... | Look in... |
|-------------|-----------|
| Understand overall structure | [diagram.md](./diagram.md) |
| Find where X is configured | [components.md](./components.md) + search for keyword |
| Learn the design conventions | [patterns.md](./patterns.md) |
| Add a new NixOS module | [patterns.md](./patterns.md) → "Module Aggregator Topology" |
| Add a new user package | [components.md](./components.md) → `home-modules/profiles.nix` |
| Change theme colors | [patterns.md](./patterns.md) → "Theming System" |
| Add a secret | [patterns.md](./patterns.md) → "Secrets Management" |

### By Component Type

| Component | Location | Details |
|-----------|----------|---------|
| **System configuration** | `nixos-modules/` | [components.md § Layer 4](./components.md) |
| **User configuration** | `home-modules/` | [components.md § Layer 6](./components.md) |
| **Host configs** | `nixos-configurations/bandit/` | [components.md § Layer 3](./components.md) |
| **User entry points** | `home-configurations/vino/` | [components.md § Layer 5](./components.md) |
| **Dev tools** | `flake-modules/` | [components.md § Layer 2](./components.md) |
| **Utilities** | `lib/default.nix` | [components.md § Layer 1](./components.md) |
| **Theme/colors** | `shared-modules/` | [components.md § Layer 7](./components.md) |
| **Secrets** | `.sops.yaml`, `secrets/*.yaml`, `*-modules/secrets.nix` | [patterns.md § Secrets](./patterns.md) |

---

## 🏗️ Key Patterns

### 1. Flake Composition
**flake-parts** framework + **ez-configs** auto-discovery eliminates boilerplate.

**See:** [patterns.md § Flake Composition](./patterns.md)

### 2. Module Aggregators
Hierarchical `default.nix` files import collections of modules by category.

**See:** [patterns.md § Module Aggregator Topology](./patterns.md)

### 3. Arg Injection
`_module.args` provides dependency injection at multiple levels:
- Flake level: `inputs`, `username`, `repoRoot`
- Home Manager: `palette`, `workspaces`, `cfgLib`, `stylixFonts`

**See:** [patterns.md § Arg Injection](./patterns.md)

### 4. Features vs Profiles
- **Features** (NixOS): System capabilities (desktop/laptop/server/development) via `features.*` options
- **Profiles** (Home Manager): User package preferences (core/dev/desktop/extras/ai) via `profiles.*` options

**See:** [patterns.md § Features vs Profiles](./patterns.md)

### 5. Theming System
Two-tier color system:
1. **Base layer:** Stylix with Base16 Gruvbox Dark Pale
2. **Semantic layer:** Palette module (`bg`, `text`, `accent`, `warn`, `danger`)

**See:** [patterns.md § Theming System](./patterns.md)

### 6. Secrets Management
sops-nix + validation helpers ensure safe secret handling.

**See:** [patterns.md § Secrets Management](./patterns.md)



---

## 📚 External Resources

### Official Documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Flakes](https://nixos.org/manual/nix/stable/command-ref/flake/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [flake-parts](https://flake.parts/)

### Tools Used
- [ez-configs](https://github.com/ehllie/ez-configs)
- [sops-nix](https://github.com/Mic92/sops-nix)
- [stylix](https://github.com/danth/stylix)
- [nixvim](https://github.com/nix-community/nixvim)

### Community Best Practices
- [nix.dev](https://nix.dev/)
- [NixOS Wiki](https://nixos.wiki/)

---

## ✅ Verification Results

**Last Verified:** 2026-05-14

### Coverage Verification
- ✅ **All .nix files** documented in components.md
- ✅ **Flake evaluation** successful (`nix flake show`)
- ✅ **Outputs validated:**
  - 2 nixosConfigurations (bandit, homelab)
  - 2 homeConfigurations (vino@bandit, vino@homelab)
  - nixosModules (via ez-configs)
  - apps, devShells, checks

### Documentation Quality
- ✅ Architecture documentation created and validated against actual repository
- ✅ Cross-references between documents maintained
- ✅ Code examples validated against actual repository
- ✅ All issues backed by concrete evidence (file:line references)

### Statistics
- **Total:** 128 .nix files, 7 layers, 6 patterns
- **Documentation:** components.md, diagram.md, patterns.md, refactor-contract.md
- **Completeness:** All .nix files documented in components.md
- **Evidence-based:** All claims verified with grep/read

---

## 🚀 Next Steps

### For Immediate Action
1. Review [refactor-contract.md](./refactor-contract.md) before making structural changes
2. Check [patterns.md](./patterns.md) for established conventions
3. Consult [components.md](./components.md) for the current file inventory

### For Long-term Planning
1. Establish CI/CD based on `just qa` gate
2. Consider architecture evolution as system grows
3. Add new hosts by creating `nixos-configurations/<hostname>/default.nix`

### For Maintenance
1. Update documentation when architectural changes are made
2. Re-run `just qa` after any structural changes

---

## 📝 Maintenance Notes

### How This Documentation Was Created
- **Method:** Manual analysis + structured refactor plan (tasks 1-8)
- **Tools:** grep, file reading, flake evaluation
- **Validation:** Cross-referenced all findings with actual code
- **Evidence:** All claims backed by file:line references

### Keeping It Current
- Update [components.md](./components.md) when adding/removing .nix files
- Update [patterns.md](./patterns.md) when introducing new conventions
- Re-generate [diagram.md](./diagram.md) if major architectural changes occur

### Regeneration
To regenerate this analysis:
1. Update components.md when adding/removing .nix files
2. Validate against current flake structure with `just qa`

---

**Last Updated:** 2026-05-14
**Repository State:** post-refactor (architecture docs current as of 2026-05-14)
**Documentation Completeness:** All architectural layers documented
