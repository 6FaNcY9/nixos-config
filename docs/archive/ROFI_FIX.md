# Rofi Power Menu Fix - Palette-Based Theme

## Issue
Rofi power menu showing all white text (no theme applied)

## Root Cause
1. Theme reference mismatch in the powermenu
2. Mixing custom themes with Stylix rofi target produced inconsistent styles

## Solution
Use explicit Rasi files (Frost-Phoenix structure) and drive colors from the shared palette, while disabling Stylix rofi theming.

## Changes Made

### Files
- `home-modules/rofi/default.nix` - wires the theme files and disables Stylix rofi target
- `home-modules/rofi/theme.rasi` - palette-driven color variables
- `home-modules/rofi/config.rasi` - main launcher layout
- `home-modules/rofi/powermenu-theme.rasi` - power menu layout

## Palette Mapping
Colors are sourced from `shared-modules/palette.nix` and injected into `theme.rasi` so all rofi menus stay consistent with your palette.

## Testing
After rebuild:
```bash
# Test power menu
Mod+Shift+e

# Should now show:
# - Colored background
# - Visible text in foreground color
# - Selected item with accent background
```

## Rebuild
```bash
nh home switch -c vino@bandit
```
