# NixOS Configuration Refactoring - Development Guide

This document provides context for Claude/Copilot when working on this refactored NixOS configuration.

## 🎯 Project Status

**Current Branch**: `refactor/explicit-modules`
**Status**: Phase 3 in progress (8/15 modules migrated)
**Working Directory**: `/home/vino/src/nixos-config-refactor` (isolated git worktree)

## ✅ Completed Migrations

### Service Features
- ✅ **Tailscale** → `features.services.tailscale`
- ✅ **Backup** → `features.services.backup`
- ✅ **Monitoring** → `features.services.monitoring`
- ✅ **Auto-update** → `features.services.auto-update`
- ✅ **OpenSSH** → `features.services.openssh`
- ✅ **Trezord** → `features.services.trezord`

### Desktop Features
- ✅ **i3-XFCE** → `features.desktop.i3-xfce`

### Security Features
- ✅ **Secrets** → `features.security.secrets`

## 🏗️ New Architecture

### Module Organization
```
nixos-modules/
├── features/           # New feature-based modules
│   ├── services/       # Service features
│   │   ├── tailscale.nix
│   │   ├── backup.nix
│   │   ├── monitoring.nix
│   │   ├── auto-update.nix
│   │   ├── openssh.nix
│   │   └── trezord.nix
│   ├── desktop/        # Desktop features
│   │   └── i3-xfce.nix
│   ├── security/       # Security features
│   │   └── secrets.nix
│   └── ...
├── core/              # Core system (placeholders)
└── profiles/          # Feature bundles (future)
```

### Host Configuration Pattern
```nix
# nixos-configurations/bandit/default.nix
features = {
  services = {
    tailscale.enable = true;
    backup.enable = false;
    monitoring.enable = false;
    auto-update = {
      enable = true;
      timer.enable = false; # Disabled for battery
    };
    openssh.enable = false;
    trezord.enable = true;
  };
  security.secrets.enable = true;
};
```

## 📝 Migration Pattern

When migrating a module:

1. **Create feature module** with explicit `enable` option
2. **Preserve all options** from original module
3. **Declare dependencies** in comments or assertions
4. **Update host config** to use `features.*` namespace
5. **Verify** with `./verify.sh`
6. **Deprecate old module** (mark for Phase 4 deletion)
7. **Commit** with detailed message

## 🔧 Key Conventions

### Feature Module Template
```nix
# Feature: <Name>
# Provides: <what it does>
# Dependencies: <what it needs>
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.<category>.<name>;
in
{
  options.features.<category>.<name> = {
    enable = lib.mkEnableOption "<description>";
    # ... other options
  };

  config = lib.mkIf cfg.enable {
    # configuration here
  };
}
```

### Color System
- `c.base*` - Raw base16 colors (base00..base0F)
- `palette.*` - Semantic color aliases (accent, warn, danger, bg, text)
- Theme colors injected via `_module.args` in home-configurations/vino/default.nix

### Important Paths
- Library: `lib/` (mkShellScript, mkColorReplacer, etc.)
- Verification: `./verify.sh` (5-phase validation)
- Plans: `docs/plans/` (design + implementation)

## ⚠️ Critical Rules

1. **Zero Breaking Changes**: All migrations must preserve functionality
2. **Verify Everything**: Run `./verify.sh` after each change
3. **Atomic Commits**: One logical change per commit
4. **Clean History**: Clear, descriptive commit messages
5. **Git Add First**: New files must be `git add`ed before `nix flake check`

## 🎨 Code Style

- **Formatting**: `nix fmt` (treefmt handles all formatters)
- **Linting**: statix, deadnix (via pre-commit)
- **Secrets**: Never commit unencrypted secrets
- **Polybar Icons**: Use Python `chr()` for Font Awesome 6 icons

## 📊 Verification

The `./verify.sh` script runs:
1. `nix flake check` - Verify flake structure
2. `nixos-rebuild build` - Build NixOS config
3. Home Manager build - Build HM config
4. Package builds - Test all packages
5. Devshell tests - Verify all devshells

**Expected**: All phases pass, package count = 2691

## 🔜 Remaining Work

### Nixos Modules to Migrate
- Hardware features (laptop, printing)
- Development features
- Desktop features (i3, picom)
- Core system modules
- Storage/boot configuration

### Home Modules to Migrate
- Editor (nixvim)
- Shell (git, starship, fish)
- Terminal (alacritty, tmux, yazi)
- Desktop (polybar, rofi, i3 config)

## 📚 Resources

- **Main Plan**: `/home/vino/src/nixos-config/docs/plans/2026-02-18-explicit-modules-implementation.md`
- **Design Doc**: `/home/vino/src/nixos-config/docs/plans/2026-02-18-explicit-modules-design.md`
- **Progress**: `docs/UPDATE.md`
- **Tasks**: `/home/vino/src/nixos-config/.tasks.md`

---

**Last Updated**: 2026-02-19
**Commits**: 22
**Status**: 🟢 Excellent Progress!
