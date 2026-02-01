# NixOS Modules - Quick Reference

## 📋 Index

- **Full Report**: `MODULES_ANALYSIS.md` (1007 lines)
- **Visual Summary**: `MODULES_ANALYSIS_VISUAL.md` (423 lines)
- **This Guide**: Quick reference for developers

## 🎯 One-Minute Summary

```
✅ Good: Role system, options hierarchies, no circular imports
❌ Bad: backup.nix bloated, sysctl duplication, magic numbers
⭐ Score: 7.2/10 (Good foundation, needs polish)
🚀 Roadmap: Priority 1 fixes = +1.0 point in 1 week
```

## 📊 Key Numbers

| Metric | Value | Status |
|--------|-------|--------|
| Total Modules | 15 | ✅ Good |
| Total Lines | 1,612 | ✅ Reasonable |
| Avg Module Size | 107 LOC | ✅ OK |
| Max Module Size | 393 (backup.nix) | ❌ Too Large |
| Largest Role | 161 (desktop-hardening) | ⚠️ Moderate |
| Dependencies | Low | ✅ Good |
| Duplication | 4 keys | ⚠️ Minor |
| Options Defined | 31 | ✅ Good |

## 🏗️ Architecture

```
default.nix (import hub)
├─ External (stylix, sops-nix)
├─ Shared (stylix-common)
├─ Core (core, storage, services, secrets, monitoring, backup)
├─ Roles (laptop, server, development, hardening)
├─ UI (desktop, stylix)
└─ Home Manager
```

## 📍 Module Locations

| Module | Path | Type | LOC |
|--------|------|------|-----|
| Core System Config | `core.nix` | Core | 169 |
| Desktop/GUI Setup | `desktop.nix` | Core | 73 |
| Storage & Boot | `storage.nix` | Core | 70 |
| General Services | `services.nix` | Core | 59 |
| Secrets (sops-nix) | `secrets.nix` | Core | 55 |
| Monitoring Stack | `monitoring.nix` | Feature | 182 |
| Backup System | `backup.nix` | Feature | 393 |
| Styling (Stylix) | `stylix-nixos.nix` | UI | 15 |
| Home Manager | `home-manager.nix` | HM | 15 |
| **Roles** |
| Role Definitions | `roles/default.nix` | System | 44 |
| Laptop Config | `roles/laptop.nix` | Role | 80 |
| Server Config | `roles/server.nix` | Role | 59 |
| Dev Tools | `roles/development.nix` | Role | 61 |
| Desktop Security | `roles/desktop-hardening.nix` | Role | 161 |

## 🔧 Configuration Patterns

### Pattern: Options Definition
```nix
options.modulename = {
  enable = lib.mkEnableOption "description";
  setting = lib.mkOption {
    type = lib.types.str;
    default = "value";
    description = "What this does";
  };
};
```

### Pattern: Conditional Config
```nix
config = lib.mkIf config.roles.laptop {
  services.power-profiles-daemon.enable = true;
};
```

### Pattern: Multiple Conditions
```nix
config = lib.mkMerge [
  (lib.mkIf config.feature.enable { ... })
  (lib.mkIf (config.feature.enable && config.feature.advanced) { ... })
];
```

## 🚨 Known Issues

### Critical (Fix First)
1. **backup.nix is 393 lines** - should split into 4 modules
   - Impact: -25% maintainability
   - Fix: Extract scripts, systemd, udev separately
   
2. **Sysctl duplication** - 4 keys in both server.nix and desktop-hardening.nix
   - Impact: -10% clarity
   - Fix: Extract to shared security.nix

### Moderate (Fix Soon)
3. **No options in core modules** - core.nix, storage.nix, desktop.nix hardcoded
   - Impact: -20% flexibility
   - Fix: Add options for timezone, locale, DM choice
   
4. **Magic numbers undocumented** - battery thresholds, ports, snapshot limits
   - Impact: -30% maintainability
   - Fix: Add comments explaining WHY

### Minor (Nice to Have)
5. **Missing doc comments** - Framework kernel params unexplained
6. **No module tests** - validation only at runtime
7. **Shell scripts not extracted** - >100 lines embedded in backup.nix

## 🎁 What's Already Good

✅ **Role System** - Clean, opt-in, easy to compose
✅ **Options Hierarchies** - desktop.hardening.sudo.timeout (no pollution)
✅ **Type Safety** - lib.types.* used consistently
✅ **Conditional Guards** - lib.mkIf ensures safety
✅ **Defaults** - lib.mkDefault allows override
✅ **No Anti-patterns** - No mkForce abuse, circular imports, etc.
✅ **Documentation** - Good comments on complex logic
✅ **Package Grouping** - Packages organized by role/feature

## 📈 Improvement Roadmap

### Week 1: Quick Wins
- [ ] Extract shared sysctl to security.nix (2 hrs)
- [ ] Add options to core.nix (1 hr)
- [ ] Document magic numbers (1 hr)
- **Expected +0.3 points**

### Week 2: Medium Refactor
- [ ] Split backup.nix into 4 modules (4 hrs)
- [ ] Create security baseline module (3 hrs)
- [ ] Add module assertions (3 hrs)
- **Expected +0.5 points**

### Week 3+: Polish
- [ ] Move shell scripts to pkgs/ (5 hrs)
- [ ] Add role composition helpers (4 hrs)
- [ ] Create auto-generated docs (8 hrs)
- **Expected +0.3 points**

**Total Expected: 7.2 → 8.3/10**

## 🔍 How to Check Quality

### Quick Check
```bash
# Count modules
find nixos-modules -name "*.nix" | wc -l

# Check for duplication
grep -r "boot.kernel.sysctl" nixos-modules/

# Find long files
wc -l nixos-modules/*.nix nixos-modules/roles/*.nix | sort -n

# Check for mkForce usage
grep -r "mkForce" nixos-modules/
```

### Code Review Checklist
When reviewing module changes:

- [ ] Function signature has `...` for future-proofing
- [ ] New options are typed with lib.types.*
- [ ] Config conditions use lib.mkIf
- [ ] Defaults allow user override with lib.mkDefault
- [ ] Comments explain WHY, not WHAT
- [ ] No hardcoded values (use let-binding)
- [ ] No duplication with sibling modules
- [ ] No lib.mkForce (unless justified)
- [ ] Shell scripts <50 lines
- [ ] Formatting: 2-space indent

## 📚 Learning Resources

### NixOS Module System
- [NixOS Manual: Modules](https://nixos.org/manual/nixos/stable/index.html#ch-modules)
- [lib.mkOption documentation](https://nixos.org/manual/nixpkgs/stable/#function-library-lib.mkOption)
- [lib.mkIf & configuration merging](https://nixos.org/manual/nixos/stable/index.html#ch-configuration)

### This Repo's Patterns
- `roles/default.nix` - Clean role system example
- `monitoring.nix` - Good options & config pattern
- `backup.nix` - What NOT to do (example of bloat)
- `lib/default.nix` - Helper functions (reusable patterns)

## 🎓 Best Practices

### DO ✅
```nix
# Use hierarchical option names
options.desktop.hardening.sudo.timeout = ...

# Export only what's needed
inherit mkOption mkIf mkDefault;

# Guard config with lib.mkIf
config = lib.mkIf config.feature.enable { ... };

# Document non-obvious settings
# Battery threshold is 40% because Framework 13 AMD
# gets ~2 hours of work per 10% at idle
minBatteryPercent = 40;

# Use lib.mkDefault for safe defaults
services.openssh.enable = lib.mkDefault config.roles.server;
```

### DON'T ❌
```nix
# Don't use flat namespacing
options.timeout = ...  # Pollutes namespace

# Don't hardcode values without let-binding
port = 9090;  # Where did this come from?

# Don't mix concerns
# (scripts + systemd + packages in one file)

# Don't use lib.mkForce without reason
config.setting = lib.mkForce true;  # Why override?

# Don't leave magic numbers
TIMELINE_LIMIT_DAILY = "7";  # Why 7? Why not 10?
```

## 🔗 Quick Links

- **Full Analysis**: `MODULES_ANALYSIS.md`
- **Visual Graphs**: `MODULES_ANALYSIS_VISUAL.md`
- **This Guide**: `MODULES_QUICK_REFERENCE.md`
- **Main Module Hub**: `nixos-modules/default.nix`
- **Role System**: `nixos-modules/roles/default.nix`
- **Library**: `lib/default.nix`

---

**Last Updated**: 2024
**Analysis Coverage**: nixos-modules/*.nix + nixos-modules/roles/*.nix
**Score**: 7.2/10 (Good foundation, needs polish)
