# Home-Modules Improvement Recommendations

This document provides specific, actionable recommendations for improving the home-modules directory.

## Table of Contents
1. [Quick Fixes (30 min - 1 hour)](#quick-fixes)
2. [Medium-term Improvements (1-3 hours)](#medium-term)
3. [Long-term Refactoring (3+ hours)](#long-term)
4. [Code Examples](#code-examples)

---

## Quick Fixes

### 1. Normalize Package References

**Current State:** Inconsistent package reference styles
```nix
# Style 1: Direct package
terminal = "alacritty";

# Style 2: Full path
"${pkgs.i3lock}/bin/i3lock"

# Style 3: Wrapped script
${powerMenu}/bin/rofi-power-menu
```

**Recommendation:** Standardize to `${pkgs.X}/bin/Y` format
```nix
# home-modules/features/desktop/i3/keybindings.nix
# BEFORE
"${mod}+Shift+x" = "exec ${pkgs.i3lock}/bin/i3lock";

# AFTER (consistent)
"${mod}+Shift+x" = "exec ${pkgs.i3lock}/bin/i3lock";
```

**Files to Update:**
- `home-modules/features/desktop/i3/keybindings.nix` (6 occurrences)
- `home-modules/rofi/rofi.nix` (15+ occurrences)
- `home-modules/features/desktop/polybar/modules.nix` (10+ occurrences)

**Effort:** 30 minutes

---

### 2. Fix Hardcoded Paths

**Current State:** Hardcoded user paths
```nix
# home-modules/shell.nix
set -gx PATH /home/vino/.cache/.bun/bin $PATH
```

**Recommendation:** Use home directory variable
```nix
# home-modules/shell.nix
set -gx PATH $HOME/.cache/.bun/bin $PATH
```

**Additional Fix:** GitHub token path already correct
```nix
if test -r ${config.sops.secrets.github_mcp_pat.path}  # ✓ Good
```

**Effort:** 15 minutes

---

### 3. Add Documentation

**Create:** `home-modules/README.md`
```markdown
# Home Modules

Overview of home-manager configuration modules.

## Module Organization

- `profiles.nix`: Package group toggles (core, dev, desktop, extras, ai)
- `shell.nix`: Fish shell, atuin, fzf, direnv, zoxide
- `features/desktop/i3/`: i3 window manager config
- `features/desktop/polybar/`: Status bar configuration
- `features/editor/nixvim/`: NeoVim setup
- `rofi/`: Application launcher

## Adding New Modules

1. Create module file: `home-modules/mymodule.nix`
2. Define options:
   ```nix
   options.myModule.enable = lib.mkEnableOption "my module";
   ```
3. Add to `home-modules/default.nix` imports
4. Gate with `lib.mkIf config.myModule.enable { ... }`

## Configuration Options

See individual modules for available options.
```

**Effort:** 30 minutes

---

## Medium-term Improvements

### 4. Extract Keybinding Helpers

**Current State:** Keybinding duplication in i3
```nix
# home-modules/features/desktop/i3/keybindings.nix (87 lines)
directionalFocus = {
  "${mod}+j" = "focus left";
  "${mod}+k" = "focus down";
  "${mod}+l" = "focus up";
  "${mod}+semicolon" = "focus right";
  "${mod}+Left" = "focus left";      # <- Duplicate
  "${mod}+Down" = "focus down";      # <- Duplicate
  "${mod}+Up" = "focus up";          # <- Duplicate
  "${mod}+Right" = "focus right";    # <- Duplicate
};
```

**Recommendation:** Create helper in lib
```nix
# lib/default.nix - Add this helper
mkI3Keybindings = {
  mod,
  hjkl ? ["j" "k" "l" "semicolon"],
  directions ? ["left" "down" "up" "right"],
  arrows ? true,
}:
  let
    hjklBindings = builtins.listToAttrs (
      lib.zipListsWith (key: dir: {
        name = "${mod}+${key}";
        value = "focus ${dir}";
      }) hjkl directions
    );
    arrowBindings = if arrows then
      builtins.listToAttrs (
        lib.zipListsWith (arrow: dir: {
          name = "${mod}+${arrow}";
          value = "focus ${dir}";
        }) ["Left" "Down" "Up" "Right"] directions
      )
    else {};
  in
    hjklBindings // arrowBindings;

# home-modules/features/desktop/i3/keybindings.nix - Use it
directionalFocus = cfgLib.mkI3Keybindings {
  inherit mod;
};
```

**Savings:** 8 lines in keybindings.nix
**Effort:** 1-2 hours

---

### 5. Add Network Interface Configuration

**Current State:** Hardcoded interface in polybar
```nix
# home-modules/features/desktop/polybar/modules.nix (line 85)
interface = "wlp1s0";  # Hardcoded!
```

**Recommendation:** Add to devices.nix
```nix
# home-modules/devices.nix
options.devices = {
  battery = lib.mkOption { ... };
  backlight = lib.mkOption { ... };
  
  # ADD THIS:
  networkInterface = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = "Network interface name (e.g., wlp1s0, enp0s31f6)";
  };
};
```

**Update Polybar:**
```nix
# home-modules/features/desktop/polybar/modules.nix
"module/network" = {
  type = "internal/network";
  interface = config.devices.networkInterface or "wlp1s0";
  ...
};
```

**Effort:** 1 hour

---

### 6. Document Option Conventions

**Create:** `home-modules/OPTIONS.md`
```markdown
# Configuration Options

## Convention: Option Naming

All options use hierarchical naming:
- `desktop.i3.*` - i3 window manager options
- `desktop.polybar.*` - Status bar options
- `editor.nixvim.*` - Editor options
- `shell.*` - Shell tool options
- `devices.*` - Hardware device names

## Common Patterns

### Boolean Toggles
```nix
options.myFeature.enable = lib.mkEnableOption "my feature";
config = lib.mkIf config.myFeature.enable { ... };
```

### Selection Options
```nix
options.clipboard.manager = lib.mkOption {
  type = lib.types.enum ["clipmenu" "parcellite"];
  default = "clipmenu";
};
```

### Path Options
```nix
options.myService.path = lib.mkOption {
  type = lib.types.path;
  default = "${config.home.homeDirectory}/.config";
};
```

### Color Injection
```nix
# Modules receive `c` and `palette` as arguments
# Use c.base00-0F for gruvbox colors
# Use palette.{bg, accent, danger} for semantic names
```
```

**Effort:** 30 minutes

---

## Long-term Refactoring

### 7. Split Polybar Modules (2-3 hours)

**Current State:** 256 lines in 3 files
```
polybar/
├── default.nix (63 lines)
├── modules.nix (191 lines) ← Too large!
└── colors.nix (12 lines)
```

**Proposed Structure:**
```
polybar/
├── default.nix (unchanged, 63 lines)
├── colors.nix (unchanged, 12 lines)
├── modules/
│   ├── default.nix (imports all modules)
│   ├── i3.nix (i3 workspace module)
│   ├── host.nix (hostname display)
│   ├── xwindow.nix (active window title)
│   ├── pulseaudio.nix (volume control)
│   ├── network.nix (WiFi status)
│   ├── time.nix (clock/calendar)
│   ├── tray.nix (system tray)
│   ├── spacer.nix (visual spacer)
│   ├── battery.nix (optional)
│   ├── power.nix (optional)
│   ├── backlight.nix (optional)
│   └── ip.nix (optional)
```

**Benefits:**
- Easier to maintain individual modules
- Clearer module responsibilities
- Easier to add/remove modules

**Implementation:**
```nix
# polybar/modules/default.nix
{lib, ...}: {
  imports = [
    ./i3.nix
    ./host.nix
    ./xwindow.nix
    ./pulseaudio.nix
    ./network.nix
    ./time.nix
    ./tray.nix
    ./spacer.nix
    ./battery.nix
    ./power.nix
    ./backlight.nix
    ./ip.nix
  ];
}

# polybar/default.nix - Unchanged imports structure
imports = [
  ./colors.nix
  ./modules
];
```

**Effort:** 2-3 hours

---

### 8. Reorganize Shell Tools (2 hours)

**Current State:** Scattered across root
```
home-modules/
├── shell.nix (121 lines)
├── git.nix (56 lines)
├── starship.nix (56 lines)
├── alacritty.nix (47 lines)
└── clipboard.nix (47 lines)
```

**Proposed Structure:**
```
home-modules/features/shell/
├── default.nix (aggregator)
├── fish.nix (fish shell, plugins, abbrs)
├── git.nix (git + delta)
├── starship.nix (prompt)
├── atuin.nix (command history)
├── fzf.nix (fuzzy finder)
├── direnv.nix (environment)
└── zoxide.nix (smart cd)
```

**Update default.nix:**
```nix
# home-modules/default.nix
imports = [
  ...
  # Shell & CLI
  ./features/shell
  ./alacritty.nix  # Terminal, not shell tool
  ...
];
```

**Benefits:**
- Consistent organization
- Clearer feature grouping
- Easier to discover shell modules

**Effort:** 2 hours

---

### 9. Extract Rofi Scripts (1-2 hours)

**Current State:** Scripts inline in rofi.nix
```nix
# rofi/rofi.nix (191 lines)
powerMenu = cfgLib.mkShellScript {...};
networkMenu = cfgLib.mkShellScript {...};
clipboardMenu = cfgLib.mkShellScript {...};
```

**Proposed Structure:**
```
rofi/
├── rofi.nix (main config, ~60 lines after extraction)
├── scripts/
│   ├── default.nix (aggregator, imports all)
│   ├── power-menu.nix (~20 lines)
│   ├── network-menu.nix (~80 lines)
│   └── clipboard-menu.nix (~5 lines)
├── config.rasi
├── theme.rasi
└── powermenu-theme.rasi
```

**Implementation:**
```nix
# rofi/scripts/default.nix
{
  power-menu = import ./power-menu.nix;
  network-menu = import ./network-menu.nix;
  clipboard-menu = import ./clipboard-menu.nix;
}

# rofi/rofi.nix - Use aggregated scripts
let
  scripts = import ./scripts;
in {
  home.packages = [
    scripts.power-menu
    scripts.network-menu
    scripts.clipboard-menu
  ];
}
```

**Benefits:**
- Scripts easier to modify individually
- Clearer separation of concerns
- Easier to reuse scripts in other configs

**Effort:** 1-2 hours

---

## Code Examples

### Example 1: Creating a New Module with Options

```nix
# home-modules/features/shell/zoxide.nix
{lib, config, ...}: {
  options.shell.zoxide = {
    enable = lib.mkEnableOption "zoxide (smart cd)";
    command = lib.mkOption {
      type = lib.types.str;
      default = "z";
      description = "Command to use for zoxide (default: z)";
    };
  };
  
  config = lib.mkIf config.shell.zoxide.enable {
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
      options = ["--cmd" config.shell.zoxide.command];
    };
  };
}
```

### Example 2: Using Device Configuration

```nix
# home-modules/features/desktop/polybar/modules/battery.nix
{config, lib, ...}: {
  config = lib.mkIf (config.devices.battery != "") {
    services.polybar.settings."module/battery" = {
      type = "internal/battery";
      battery = config.devices.battery;
      adapter = "AC";
      full-at = 98;
      format-charging = "<label-charging>";
      label-charging = " %percentage%%";
    };
  };
}
```

### Example 3: Color Injection Pattern

```nix
# home-modules/features/shell/starship.nix
{c, palette, ...}: {
  programs.starship.settings = {
    directory.style = "fg:${c.base05} bg:${c.base01}";
    character.success_symbol = " [](fg:${palette.accent})";
    character.error_symbol = " [](fg:${palette.danger})";
  };
}
```

### Example 4: Conditional Module Loading

```nix
# home-modules/features/desktop/polybar/modules/ip.nix
{config, lib, pkgs, ...}: {
  config = lib.mkIf (config.devices.battery == "") {
    services.polybar.settings."module/ip" = {
      type = "custom/script";
      exec = "${pkgs.iproute2}/bin/ip -4 route get 1.1.1.1 | ...";
      interval = 5;
      format = "<label>";
      label = "  %output%";
    };
  };
}
```

---

## Implementation Priority

### Priority 1 (Do First - 1.5 hours)
1. ✅ Fix hardcoded paths (15 min)
2. ✅ Normalize package references (30 min)
3. ✅ Create home-modules/README.md (30 min)

### Priority 2 (Do Next - 4-5 hours)
1. Extract keybinding helpers (1-2 hours)
2. Add network interface to devices.nix (1 hour)
3. Document option conventions (30 min)
4. Add comments to complex modules (1 hour)

### Priority 3 (Do Later - 6-8 hours)
1. Split polybar modules (2-3 hours)
2. Reorganize shell tools (2 hours)
3. Extract rofi scripts (1-2 hours)
4. Profile nixvim LSPs (1-2 hours)

---

## Validation Checklist

After making changes, verify:

- [ ] All files pass `nix fmt` formatting
- [ ] `nix flake check` passes (pre-commit hooks)
- [ ] `home-manager switch --flake .#vino@bandit` rebuilds successfully
- [ ] No new hardcoded paths introduced
- [ ] All new modules have options section
- [ ] All conditional modules use `lib.mkIf`
- [ ] Color references use `c.*` or `palette.*`
- [ ] Package references use `${pkgs.X}/bin/Y` format

---

## Questions & Answers

**Q: Should we make all packages use `${pkgs.X}/bin/Y` format?**  
A: Yes, for consistency. Some packages only need the package name (e.g., `terminal = "alacritty"`), but full paths are clearer for executables.

**Q: Should we extract user services to a helper pattern?**  
A: Yes, but lower priority. The pattern is clean enough as-is. Extract only if adding more services.

**Q: Should we reduce the 19 LSP servers?**  
A: Consider profiling. Core servers (nixd, pyright, rust_analyzer, ts_ls) should always be available. Others could be optional.

**Q: Should we move rofi to features/desktop/?**  
A: Not necessary. Current rofi/ location works. If reorganizing, keep consistency with i3/polybar.

