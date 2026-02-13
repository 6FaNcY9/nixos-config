# Flake Input Comparison: Us vs Misterio77

**Date**: 2026-01-31

## Channel Strategy

### Ours
```nix
nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";          # PRIMARY: stable
nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";  # overlay only
```

**Strategy**: Stable first, unstable via overlay for specific packages

### Misterio77
```nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";       # PRIMARY: unstable
nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";   # fallback
```

**Strategy**: Unstable first, stable as fallback for broken packages

### Analysis
- **Misterio77 approach**: More aggressive (latest everything, stable fallback)
- **Our approach**: More conservative (stable base, unstable opt-in)
- **Recommendation**: Consider switching to Misterio77's approach for desktop use
  - Desktop benefits from latest packages
  - Stable fallback when unstable breaks
  - Server would use opposite strategy

---

## Shared Inputs (Both Use)

| Input | Our Version | Misterio77 Version | Notes |
|-------|-------------|-------------------|-------|
| nixos-hardware | latest | latest | Framework quirks |
| home-manager | release-25.11 | follows nixpkgs (unstable) | Version difference due to channel |
| sops-nix | Mic92/sops-nix | mic92/sops-nix | Same (case doesn't matter) |

---

## Misterio77 Has (We Don't)

### System Infrastructure
- **impermanence** (misterio77 fork) - Opt-in state persistence
  - Uses custom fork with home-manager integration
  - Major workflow change
  - Benefits: Clean state, reproducibility
  - Costs: Need to declare all persistent paths

- **disko** - Declarative disk partitioning
  - Automates disk setup
  - Useful for multi-host configs
  - We have single host (bandit) - lower priority

- **lanzaboote** - Secure Boot with UEFI
  - Security hardening
  - TPM integration
  - Framework supports it
  - Medium priority

- **nix-colors** - Declarative color scheme system
  - Alternative to Stylix
  - More granular control
  - We use Stylix - evaluate if worth switching

### Theming & Desktop
- **nix-gl** - OpenGL wrapper for non-NixOS systems
  - Not needed (we're on NixOS)

### Applications
- **firefox-addons** (rycee/nur-expressions)
  - Declarative Firefox extensions
  - We manually install extensions
  - Worth considering

- **nixos-mailserver** - Self-hosted mail server
  - Not applicable (laptop config)

- **nix-minecraft** - Minecraft server management
  - Game server hosting
  - Not applicable for our use case

- **hytale** - Hytale game launcher
  - Specific game launcher
  - Not applicable

### Other
- **systems** (nix-systems/default-linux)
  - Standardized system definitions
  - We hardcode `x86_64-linux`
  - Minor improvement

---

## We Have (Misterio77 Doesn't)

### Development Tools
- **nixvim** - Neovim configuration framework
  - Home Manager module for Neovim
  - We use extensively (~478 LOC)
  - They might use different editor setup

- **stylix** - System-wide theming framework
  - Auto-generates themes for all apps
  - They use nix-colors instead
  - Different approach, both valid

- **codex-cli-nix** - OpenCode Codex integration
  - AI coding assistant
  - Specific to our workflow

- **opencode** - AI development environment
  - Core to our development workflow
  - Not common in other configs

### Flake Composition (Our Abstraction Layer)
- **flake-parts** - Modular flake composition
  - We use, they use traditional flakes
  - More modular, but adds complexity
  - Both approaches work

- **ez-configs** - Automated host/user config generation
  - Reduces boilerplate
  - Auto-imports modules
  - Simplifies multi-host setup

- **treefmt-nix** - Formatting infrastructure
  - We integrate via flake-parts
  - They might use different formatting

- **mission-control** - Development environment menu
  - Nice DX for `nix develop`
  - Not essential

- **devshell** - Development shell framework
  - Multiple shell profiles (maintenance, flask, pentest)
  - Alternative to mkShell

- **flake-root** - Repository root detection
  - Utility for scripts
  - Minor helper

### Development Services
- **process-compose-flake** - Service orchestration
  - Replaces docker-compose
  - For local dev services

- **services-flake** - Pre-configured services
  - Database/service definitions
  - Integration with process-compose

### Aesthetic
- **gruvbox-wallpaper** - Wallpaper collection
  - Theming consistency
  - Minor aesthetic choice

### Pre-commit
- **pre-commit-hooks** (cachix/git-hooks.nix)
  - Automated QA checks
  - statix, deadnix, treefmt
  - They might use different QA approach

---

## Input Strategy Comparison

### Our Philosophy
1. **Stable base** (25.11) + **unstable overlay** for specific needs
2. **Heavy abstraction** (flake-parts, ez-configs) for DRY
3. **Developer tooling** (nixvim, opencode, devshell)
4. **Automated QA** (pre-commit hooks)
5. **Theming integration** (stylix)

### Misterio77 Philosophy
1. **Unstable base** + **stable fallback** for broken packages
2. **Traditional flake** structure (no abstraction layer)
3. **Infrastructure focus** (impermanence, disko, lanzaboote)
4. **Security hardening** (Secure Boot, opt-in persistence)
5. **Declarative everything** (nix-colors, firefox-addons)

---

## Potential Optimizations

### High Priority (Should Consider)
1. **Switch channel strategy** - unstable primary, stable fallback
   - Benefit: Latest packages + stability net
   - Effort: Low (just swap inputs)
   - Risk: Low (can revert easily)

2. **firefox-addons** - Declarative extensions
   - Benefit: Reproducible browser config
   - Effort: Low (add input + configure)
   - Risk: None

3. **nix-colors evaluation** - Compare with Stylix
   - Benefit: Potentially better theming control
   - Effort: Medium (learning curve)
   - Risk: Low (can keep Stylix)

### Medium Priority (Evaluate)
4. **lanzaboote** - Secure Boot
   - Benefit: Security hardening, TPM integration
   - Effort: Medium (UEFI setup)
   - Risk: Medium (boot issues if misconfigured)

5. **systems** input - Standardize system definitions
   - Benefit: Cleaner flake structure
   - Effort: Low (minor refactor)
   - Risk: None

### Low Priority (Future)
6. **impermanence** - Opt-in persistence
   - Benefit: Clean state, full reproducibility
   - Effort: High (major workflow change)
   - Risk: High (data loss if misconfigured)

7. **disko** - Declarative disks
   - Benefit: Reproducible disk setup
   - Effort: Medium (partition migration)
   - Risk: High (data loss risk)
   - Use case: When adding more hosts

---

## Questions for Further Investigation

1. **Why unstable primary?**
   - Does Misterio77 have frequent breakage?
   - How often is stable fallback needed?
   - What's the practical experience?

2. **flake-parts vs traditional?**
   - Performance differences?
   - Maintenance burden?
   - Community preference?

3. **Stylix vs nix-colors?**
   - Feature comparison
   - Integration quality
   - Community adoption

4. **Impermanence real-world usage?**
   - What actually needs persistence?
   - Workflow impact?
   - Worth the complexity for single laptop?

---

## Action Items

- [ ] Test unstable-primary channel strategy in branch
- [ ] Add firefox-addons input
- [ ] Research nix-colors vs Stylix tradeoffs
- [ ] Evaluate lanzaboote for Framework 13 AMD
- [ ] Document findings in COMPARISON.md

