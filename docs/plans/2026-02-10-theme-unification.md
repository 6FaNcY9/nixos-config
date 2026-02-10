# Theme Unification & Polybar Final Polish

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Unify all desktop theming to match the polybar Gruvbox design, fix polybar text readability, and reorganize home-modules into a cleaner folder structure.

**Architecture:** Centralized palette system already exists (`shared-modules/palette.nix` + `_module.args` injection). Most apps are unified. This plan fixes the remaining hardcoded colors in polybar/rofi, bumps polybar font size for readability, restructures flat home-modules into categorized subdirectories, and ensures tmux/starship/dunst/picom all use consistent semantic palette references.

**Tech Stack:** NixOS, Home Manager, Nix (Alejandra fmt), Stylix base16, Polybar, Rofi, i3, tmux, starship, picom, dunst

---

## Current State

### Already Unified (no changes needed)
- i3 borders: `palette.warn`, `palette.danger`, `c.base*`
- Tmux: `palette.*` throughout
- Starship: `c.base*` throughout
- Dunst: `palette.*` with `lib.mkForce`
- Flameshot: `palette.*`
- Nixvim: `c.base*` + Stylix auto theme
- Firefox: color replacer with `c.base*`
- Alacritty: Stylix-managed
- GTK/Qt: Stylix-managed

### Needs Fixing
- **Polybar colors.nix**: 10 hardcoded hex colors for two-tone pairs
- **Rofi default.nix**: 9 hardcoded hex colors in color replacer
- **Picom**: `shadow-color = "#1d2021"` hardcoded
- **Polybar text**: font size too small to read comfortably

### Folder Structure (current)
```
home-modules/
├── alacritty.nix          # flat - should be in terminal/
├── clipboard.nix          # flat - should be in desktop/
├── default.nix            # aggregator
├── desktop/               # good pattern
│   ├── i3/
│   └── polybar/
├── desktop-services.nix   # flat - should be in desktop/
├── devices.nix            # flat - infrastructure, ok
├── editor/                # good pattern
│   └── nixvim/
├── firefox.nix            # flat - should be in desktop/
├── git.nix                # flat - should be in shell/
├── nixpkgs.nix            # infrastructure, ok
├── package-managers.nix   # infrastructure, ok
├── profiles.nix           # infrastructure, ok
├── rofi/                  # should be in desktop/rofi/
├── secrets.nix            # infrastructure, ok
├── shell.nix              # flat - should be in shell/
├── starship.nix           # flat - should be in shell/
├── tmux.nix               # flat - should be in terminal/
└── xfce-session.nix       # flat - should be in desktop/
```

---

## Task 1: Bump Polybar Font Size for Readability

**Files:**
- Modify: `home-modules/desktop/polybar/default.nix:53`

**Step 1: Increase font sizes**

Change font-0 from size=11 to size=12, and FA6 fonts from pixelsize=12 to pixelsize=13:

```nix
font-0 = "Iosevka Term:size=12:weight=bold;2";
font-1 = "Font Awesome 6 Free Solid:pixelsize=13;3";
font-2 = "Font Awesome 6 Free:pixelsize=13;3";
font-3 = "Font Awesome 6 Brands:pixelsize=13;3";
```

Also bump bar height from 15pt to 17pt to accommodate the larger text:

```nix
height = "17pt";
```

**Step 2: Validate**

Run: `nix fmt && nix flake check`
Expected: exit 0

**Step 3: Commit**

```bash
git add home-modules/desktop/polybar/default.nix
git commit -m "fix(polybar): increase font size for readability"
```

---

## Task 2: Unify Polybar Hardcoded Colors

**Files:**
- Modify: `home-modules/desktop/polybar/colors.nix`
- Reference: `shared-modules/palette.nix` for available colors

**Step 1: Replace hardcoded hex with `c.base*` references where possible**

The Gruvbox Dark Pale base16 scheme provides these mappings:
- `c.base08` = red (#d75f5f) - use for `red`
- `c.base09` = orange-alt (#ff8700)
- `c.base0A` = yellow/warn (#ffaf00)
- `c.base0B` = green/accent (#afaf00)
- `c.base0C` = aqua (#85ad85)
- `c.base0D` = blue/accent2 (#83adad)
- `c.base0E` = purple (#d485ad)
- `c.base0F` = orange (#d65f5f)

For the two-tone pairs (dark/bright variants), the base16 scheme only provides one shade per hue. The "-alt" (bright) variants are standard Gruvbox values that don't exist in base16. Keep these as hardcoded — they're Gruvbox-specific design choices, not theme-switchable values.

**What to change:**
```nix
# Change these to use c.* / palette.*:
green = c.base0B;        # was "#98971a" — close enough via base16
blue = c.base0D;         # was "#458588"
purple = c.base0E;       # was "#b16286" — close via base16
aqua = c.base0C;         # was "#689d6a"
yellow = palette.warn;   # was "#d79921"

# Keep these hardcoded (no base16 equivalent for bright variants):
green-alt = "#b8bb26";
yellow-alt = "#fabd2f";
blue-alt = "#83a598";
aqua-alt = "#8ec07c";
red-alt = "#fb4934";
```

**Step 2: Validate**

Run: `nix fmt && nix flake check`

**Step 3: Commit**

```bash
git add home-modules/desktop/polybar/colors.nix
git commit -m "refactor(polybar): use palette/base16 refs for primary colors"
```

---

## Task 3: Unify Rofi Hardcoded Colors

**Files:**
- Modify: `home-modules/rofi/default.nix`

**Step 1: Replace hardcoded hex with palette/c references**

```nix
replace = cfgLib.mkColorReplacer {
  colors = {
    "bg-col" = palette.bg;
    "bg-col-light" = palette.bgAlt;
    "border-col" = palette.muted;         # was "#928374"
    "selected-col" = c.base0F;            # was "#d65d0e" — Gruvbox orange
    "orange" = c.base0F;                  # was "#d65d0e"
    "orange-alt" = c.base09;              # was "#fe8019"
    "yellow" = palette.warn;              # was "#d79921"
    "yellow-alt" = "#fabd2f";             # no base16 equiv — keep
    "fg-col" = palette.text;              # was "#ebdbb2"
    "fg-col2" = c.base06;
    "grey" = palette.muted;               # was "#928374"
    "cream" = c.base07;                   # was "#ebdbb2"
    "red-alt" = "#fb4934";                # no base16 equiv — keep
    "element-bg" = "#1b1b1b";             # design choice — keep
    "element-alternate-bg" = palette.bg;
    "font-base" = fontBase;
    "icon-theme" = "Papirus-Dark";
    "terminal" = "alacritty";
  };
};
```

**Step 2: Validate**

Run: `nix fmt && nix flake check`

**Step 3: Commit**

```bash
git add home-modules/rofi/default.nix
git commit -m "refactor(rofi): use palette/base16 refs for colors"
```

---

## Task 4: Fix Picom Hardcoded Shadow Color

**Files:**
- Modify: `home-modules/desktop-services.nix:84`

**Step 1: Replace hardcoded shadow-color**

```nix
shadow-color = palette.bg;  # was "#1d2021"
```

**Step 2: Validate**

Run: `nix fmt && nix flake check`

**Step 3: Commit**

```bash
git add home-modules/desktop-services.nix
git commit -m "refactor(picom): use palette.bg for shadow-color"
```

---

## Task 5: Reorganize home-modules Folder Structure

**This is the big structural refactor.** Move flat files into categorized subdirectories matching the existing `desktop/` and `editor/` pattern.

**Target structure:**
```
home-modules/
├── default.nix              # aggregator (update imports)
├── desktop/                 # all GUI/WM related
│   ├── clipboard.nix        # move from root
│   ├── default.nix          # NEW aggregator for desktop/
│   ├── firefox.nix          # move from root
│   ├── i3/
│   │   ├── autostart.nix
│   │   ├── config.nix
│   │   ├── default.nix
│   │   ├── keybindings.nix
│   │   └── workspace.nix
│   ├── polybar/
│   │   ├── colors.nix
│   │   ├── default.nix
│   │   └── modules.nix
│   ├── rofi/                # move from root
│   │   ├── config.rasi
│   │   ├── default.nix
│   │   ├── powermenu-theme.rasi
│   │   └── theme.rasi
│   ├── services.nix         # rename from desktop-services.nix
│   └── xfce-session.nix     # move from root
├── editor/
│   └── nixvim/
│       └── (existing files)
├── shell/                   # NEW category
│   ├── default.nix          # NEW aggregator
│   ├── git.nix              # move from root
│   ├── shell.nix            # move from root (zsh/bash config)
│   └── starship.nix         # move from root
├── terminal/                # NEW category
│   ├── alacritty.nix        # move from root
│   ├── default.nix          # NEW aggregator
│   └── tmux.nix             # move from root
├── devices.nix              # stays (hardware abstraction)
├── nixpkgs.nix              # stays (infrastructure)
├── package-managers.nix     # stays (infrastructure)
├── profiles.nix             # stays (package groups)
└── secrets.nix              # stays (sops)
```

### Step 1: Create new directories and aggregator files

Create `home-modules/shell/default.nix`:
```nix
{...}: {
  imports = [
    ./git.nix
    ./shell.nix
    ./starship.nix
  ];
}
```

Create `home-modules/terminal/default.nix`:
```nix
{...}: {
  imports = [
    ./alacritty.nix
    ./tmux.nix
  ];
}
```

Create `home-modules/desktop/default.nix` (replace existing or update):
```nix
{...}: {
  imports = [
    ./clipboard.nix
    ./firefox.nix
    ./i3
    ./polybar
    ./rofi
    ./services.nix
    ./xfce-session.nix
  ];
}
```

### Step 2: Move files

```bash
# Shell
mkdir -p home-modules/shell
git mv home-modules/git.nix home-modules/shell/
git mv home-modules/shell.nix home-modules/shell/
git mv home-modules/starship.nix home-modules/shell/

# Terminal
mkdir -p home-modules/terminal
git mv home-modules/alacritty.nix home-modules/terminal/
git mv home-modules/tmux.nix home-modules/terminal/

# Desktop (already has subdirectory)
git mv home-modules/clipboard.nix home-modules/desktop/
git mv home-modules/firefox.nix home-modules/desktop/
git mv home-modules/rofi home-modules/desktop/
git mv home-modules/desktop-services.nix home-modules/desktop/services.nix
git mv home-modules/xfce-session.nix home-modules/desktop/
```

### Step 3: Fix relative import path in rofi/default.nix

The rofi module imports `../../lib`. After moving to `desktop/rofi/`, this needs to become `../../../lib`:
```nix
cfgLib = import ../../../lib {inherit lib;};
```

Similarly check firefox.nix for any relative path imports.

### Step 4: Update root home-modules/default.nix

Replace the flat import list with the new categorized structure:
```nix
{...}: {
  imports = [
    # Categories
    ./desktop
    ./editor
    ./shell
    ./terminal
    # Infrastructure (flat)
    ./devices.nix
    ./nixpkgs.nix
    ./package-managers.nix
    ./profiles.nix
    ./secrets.nix
  ];
}
```

### Step 5: Validate

Run: `nix fmt && nix flake check`
Expected: exit 0 (pure restructure, no behavior change)

### Step 6: Commit

```bash
git add -A
git commit -m "refactor(home-modules): reorganize into categorized subdirectories

Move flat module files into desktop/, shell/, terminal/ categories
matching the existing editor/ pattern. No functional changes."
```

---

## Task 6: Final Validation & System Switch

**Step 1: Full QA**

```bash
nix run .#qa
```

**Step 2: System rebuild (includes new iosevka-bin font)**

```bash
nh os switch -H bandit
```

**Step 3: Home Manager rebuild**

```bash
nh home switch -c vino@bandit
```

**Step 4: Visual verification checklist**

- [ ] Polybar text is readable at new font size
- [ ] Polybar workspace icons are centered (proportional FA6)
- [ ] Polybar workspace bullet separators display correctly
- [ ] Polybar two-tone blocks have correct colors
- [ ] Rofi drun: orange prompt, orange selection, dark elements
- [ ] Rofi powermenu: horizontal, red-alt selection
- [ ] i3 borders match palette colors
- [ ] Dunst notifications match palette
- [ ] tmux status bar matches palette
- [ ] Starship prompt colors match palette

---

## Dependency Order

```
Task 1 (polybar font) ─┐
Task 2 (polybar colors)─┤
Task 3 (rofi colors) ──┤── can be parallel
Task 4 (picom shadow) ─┘
                        │
Task 5 (folder restructure) ── depends on all above being committed
                        │
Task 6 (validation) ──── depends on Task 5
```

Tasks 1-4 are independent and can run in parallel. Task 5 (restructure) should be done after to avoid merge conflicts. Task 6 is final validation.
