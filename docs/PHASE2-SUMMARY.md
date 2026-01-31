# Phase 2: Module Refactoring Summary

**Status**: ✅ COMPLETED  
**Date**: January 31, 2026  
**Branch**: `claude/explore-nixos-config-ZhsHP`  
**Commits**: `e180f8f`, `89bf426`

---

## Overview

Phase 2 focused on refactoring large monolithic Home Manager modules into feature-based directory structures. This improves maintainability, makes it easier to locate specific configurations, and follows community best practices identified in Phase 1.

---

## What Was Refactored

### 1. nixvim.nix (478 LOC → 5 files)

**Before**: Single `home-modules/nixvim.nix` file  
**After**: `home-modules/features/editor/nixvim/` directory

**Structure**:
```
home-modules/features/editor/nixvim/
├── default.nix       # Main config + imports
├── options.nix       # Vim options (line numbers, tabs, etc.)
├── keymaps.nix       # All keybindings
├── plugins.nix       # Plugin configurations
└── extra-config.nix  # Raw Lua/Vimscript
```

**Benefits**:
- Plugins separated from core options
- Keybindings easy to find and modify
- Extra Lua config isolated for clarity

---

### 2. polybar.nix (254 LOC → 3 files)

**Before**: Single `home-modules/polybar.nix` file  
**After**: `home-modules/features/desktop/polybar/` directory

**Structure**:
```
home-modules/features/desktop/polybar/
├── default.nix  # Bar settings + imports
├── colors.nix   # Color definitions
└── modules.nix  # All bar modules
```

**Benefits**:
- Colors separated for easy theme adjustments
- Module definitions isolated from bar config
- Path corrections applied (4 levels up: `../../../../lib`)

**Fixed Issues**:
- Template variable escaping: `\${colors...}` (single backslash)
- Relative path to lib corrected

---

### 3. i3.nix (231 LOC → 5 files)

**Before**: Single `home-modules/i3.nix` file  
**After**: `home-modules/features/desktop/i3/` directory

**Structure**:
```
home-modules/features/desktop/i3/
├── default.nix      # Main config + imports
├── config.nix       # Window rules, appearance, gaps, colors
├── keybindings.nix  # All keybindings (focus, move, layout, system)
├── autostart.nix    # Startup applications
└── workspace.nix    # Workspace assignments
```

**Benefits**:
- Keybindings grouped logically (directional, layout, system)
- Workspace assignments easy to modify
- Startup apps isolated
- Color config separate from keybindings

**Key Variables Shared Across Files**:
- `mod = "Mod4"` (used in keybindings, workspace bindings)
- `cfgLib` (helper library for workspace bindings)
- `c.*` (Stylix color integration)
- Package references (`pkgs.i3lock`, etc.)

---

## Migration Guide

### Old Paths → New Paths

| Old Path | New Path |
|----------|----------|
| `home-modules/nixvim.nix` | `home-modules/features/editor/nixvim/` |
| `home-modules/polybar.nix` | `home-modules/features/desktop/polybar/` |
| `home-modules/i3.nix` | `home-modules/features/desktop/i3/` |

### How to Find Specific Features

| Feature | File Location |
|---------|---------------|
| **Nixvim keybindings** | `features/editor/nixvim/keymaps.nix` |
| **Nixvim plugins** | `features/editor/nixvim/plugins.nix` |
| **Nixvim options (tabs, line numbers)** | `features/editor/nixvim/options.nix` |
| **Polybar colors** | `features/desktop/polybar/colors.nix` |
| **Polybar modules** | `features/desktop/polybar/modules.nix` |
| **i3 keybindings** | `features/desktop/i3/keybindings.nix` |
| **i3 window colors** | `features/desktop/i3/config.nix` |
| **i3 workspace assignments** | `features/desktop/i3/workspace.nix` |
| **i3 startup apps** | `features/desktop/i3/autostart.nix` |

---

## Testing & Verification

### Configuration Validation
```bash
nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath
# Result: "/nix/store/vsg5m54b0kh92kf5ww6dr6855frjpmrf-nixos-system-bandit-26.05.20260126.bfc1b8a.drv"
# Status: ✅ Success
```

### QA Checks
```bash
# Formatting
nix fmt
# Result: ✅ 9 files formatted, 1 changed

# Static analysis
nix develop --command statix check .
# Result: ✅ Only warnings on empty patterns (acceptable)

# Dead code detection
nix develop --command deadnix -f .
# Result: ✅ No issues found
```

### Functional Testing
- No functional changes made (refactoring only)
- All imports updated in `home-modules/default.nix`
- Old monolithic files removed after verification

---

## Implementation Details

### Path Corrections
All split modules now correctly reference the shared lib:
```nix
# From home-modules/features/desktop/i3/
cfgLib = import ../../../../lib {inherit lib;};

# 4 levels up:
# i3/ → desktop/ → features/ → home-modules/ → lib/
```

### Shared Variables Pattern
Variables needed across multiple files are defined in `let` blocks and passed through module args:

```nix
# keybindings.nix
let
  mod = "Mod4";  # Also used in workspace bindings
  cfgLib = import ../../../../lib {inherit lib;};
  
  workspaceSwitch = cfgLib.mkWorkspaceBindings {
    inherit mod workspaces;
    commandPrefix = "workspace";
  };
in { ... }
```

### Module Arguments
Required args injected from `home-configurations/vino/default.nix`:
- `c` - Stylix colors
- `palette` - Color palette
- `stylixFonts` - Font configuration
- `i3Pkg` - i3 package
- `workspaces` - Workspace list
- Standard args: `lib`, `pkgs`, `config`

---

## Benefits of This Refactoring

1. **Improved Maintainability**
   - Easier to locate specific configurations
   - Smaller files are easier to understand
   - Logical grouping reduces cognitive load

2. **Better Organization**
   - Feature-based structure matches mental models
   - Related configs are colocated
   - Clear separation of concerns

3. **Follows Community Best Practices**
   - Matches patterns from analyzed high-quality configs
   - Directory-based module structure is standard
   - Easier for others to contribute/understand

4. **Easier Customization**
   - Want to change keybindings? Edit one file
   - Want to adjust colors? Edit one file
   - Want to modify startup apps? Edit one file

---

## Files Changed

**New Files** (15 files):
```
home-modules/features/editor/nixvim/
├── default.nix
├── options.nix
├── keymaps.nix
├── plugins.nix
└── extra-config.nix

home-modules/features/desktop/polybar/
├── default.nix
├── colors.nix
└── modules.nix

home-modules/features/desktop/i3/
├── default.nix
├── config.nix
├── keybindings.nix
├── autostart.nix
└── workspace.nix
```

**Modified Files** (1 file):
- `home-modules/default.nix` - Updated imports

**Removed Files** (3 files):
- `home-modules/nixvim.nix` (obsolete)
- `home-modules/polybar.nix` (obsolete)
- `home-modules/i3.nix` (obsolete)

---

## Next Steps (Phase 3+)

Phase 2 is complete. Future phases planned:

- **Phase 3**: System-level refactoring (nixos-modules/)
- **Phase 4**: Advanced features (dev environments, impermanence)
- **Optional**: Home Manager profiles, automated testing

See `docs/FINDINGS-SUMMARY.md` for full roadmap.

---

## Quick Reference

### Editing Common Configs

**Add i3 keybinding**:
```bash
$EDITOR home-modules/features/desktop/i3/keybindings.nix
```

**Change nixvim plugin**:
```bash
$EDITOR home-modules/features/editor/nixvim/plugins.nix
```

**Modify polybar module**:
```bash
$EDITOR home-modules/features/desktop/polybar/modules.nix
```

**Adjust i3 colors**:
```bash
$EDITOR home-modules/features/desktop/i3/config.nix
```

### Rebuild After Changes

```bash
# Verify config evaluates
nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath

# Apply changes
nh home switch -c vino@bandit  # Home Manager only
# or
nh os switch -H bandit         # Full system rebuild
```

---

## Lessons Learned

1. **Path Arithmetic is Critical**
   - Always count directory depth carefully
   - From `features/desktop/polybar/`: need `../../../../lib`
   - Incorrect paths cause evaluation failures

2. **Escaping Matters**
   - Polybar template vars: `\${colors...}` (single backslash)
   - Double backslash breaks template substitution

3. **Git Add Before Eval**
   - Flakes only see files in git index
   - Must `git add` new files before testing config

4. **Shared Variables Pattern**
   - Define once in `let` block
   - Use across multiple attribute sets
   - Prevents duplication and drift

5. **Module Args from Parent**
   - `_module.args` in home config makes vars available everywhere
   - No need to thread through every import
   - Cleaner function signatures

---

**Phase 2 Status**: ✅ Complete  
**Configuration Status**: ✅ Evaluates successfully  
**QA Status**: ✅ All checks pass  
**Documentation**: ✅ Complete
