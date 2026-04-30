# Config Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove bitwarden + network menu integrations, replace clipmenu with copyq (same keybinding), and trim redundant package declarations from profiles.nix.

**Architecture:** Four independent edits to the HM module tree — each committed separately. No new modules created. QA gate is `just qa` (nixfmt + statix + deadnix + nix flake check).

**Tech Stack:** Nix / Home Manager / i3 / Rofi

---

## File Map

| Action | File |
|---|---|
| Delete | `home-modules/features/desktop/bitwarden.nix` |
| Delete | `home-modules/features/desktop/bitwarden-menu.sh` |
| Delete | `home-modules/features/desktop/rofi/scripts/network-menu.sh` |
| Delete | `home-modules/features/desktop/rofi/scripts/clipboard-menu.sh` |
| Modify | `home-modules/features/desktop/default.nix` |
| Modify | `home-configurations/vino/hosts/bandit.nix` |
| Modify | `home-modules/features/desktop/i3/keybindings.nix` |
| Modify | `home-modules/features/desktop/i3/config.nix` |
| Modify | `home-modules/features/desktop/rofi/scripts.nix` |
| Modify | `home-modules/features/desktop/rofi/default.nix` |
| Modify | `home-modules/profiles.nix` |

---

## Task 1: Remove Bitwarden

**Files:**
- Delete: `home-modules/features/desktop/bitwarden.nix`
- Delete: `home-modules/features/desktop/bitwarden-menu.sh`
- Modify: `home-modules/features/desktop/default.nix`
- Modify: `home-configurations/vino/hosts/bandit.nix`
- Modify: `home-modules/features/desktop/i3/keybindings.nix`

- [ ] **Step 1: Delete the bitwarden module and shell script**

```bash
rm home-modules/features/desktop/bitwarden.nix
rm home-modules/features/desktop/bitwarden-menu.sh
```

- [ ] **Step 2: Remove bitwarden import from desktop aggregator**

In `home-modules/features/desktop/default.nix`, remove line 17:

```nix
# old_string to remove:
    ./bitwarden.nix
```

File after edit (lines 1–20):
```nix
# Desktop feature module - Aggregates all desktop-related configuration
# Imports: services, clipboard, screen lock, qutebrowser, Firefox, XFCE session, i3, polybar, rofi, FileZilla, Bitwarden

{
  imports = [
    ./services.nix
    ./clipboard.nix
    ./lock
    ./qutebrowser.nix
    ./firefox.nix
    ./xfce-session.nix
    ./i3
    ./polybar
    ./rofi
    ./vibe
    ./filezilla.nix
    ./notepad.nix
  ];
}
```

Also update the comment on line 2 — remove "Bitwarden" from the imports list description.

- [ ] **Step 3: Disable bitwarden in bandit host config**

In `home-configurations/vino/hosts/bandit.nix`, remove line 51:

```nix
# Remove this line:
      bitwarden.enable = true;
```

- [ ] **Step 4: Remove bitwarden keybindings from i3**

In `home-modules/features/desktop/i3/keybindings.nix`, remove lines 66–67 from `systemBindings`:

```nix
# Remove these two lines:
    "${mod}+p" = "exec rofi-rbw"; # Bitwarden credential picker (autotype)
    "${mod}+Shift+b" = "exec qutebrowser vault.bitwarden.com"; # Bitwarden web vault
```

- [ ] **Step 5: Stage and verify**

```bash
git add -A
just qa
```

Expected: all checks pass (nixfmt, statix, deadnix, nix flake check).

- [ ] **Step 6: Commit**

```bash
git commit -m "chore: remove bitwarden integration (using tray icon instead)"
```

---

## Task 2: Remove Rofi Network Menu

**Files:**
- Delete: `home-modules/features/desktop/rofi/scripts/network-menu.sh`
- Modify: `home-modules/features/desktop/rofi/scripts.nix`
- Modify: `home-modules/features/desktop/rofi/default.nix`

- [ ] **Step 1: Delete the network menu shell script**

```bash
rm home-modules/features/desktop/rofi/scripts/network-menu.sh
```

- [ ] **Step 2: Remove networkMenu derivation from scripts.nix**

In `home-modules/features/desktop/rofi/scripts.nix`, remove the `networkMenu` let-binding (lines 17–30):

```nix
# Remove this block:
  networkMenu = pkgs.writeShellApplication {
    name = "rofi-network-menu";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.iproute2
      pkgs.libnotify
      pkgs.networkmanager
      pkgs.networkmanagerapplet
      pkgs.rofi
    ];
    text = builtins.readFile ./scripts/network-menu.sh;
  };
```

- [ ] **Step 3: Remove networkMenu from home.packages**

In `home-modules/features/desktop/rofi/scripts.nix`, in the `home.packages` list, remove:

```nix
      networkMenu
```

- [ ] **Step 4: Remove polybar click binding for network menu**

In `home-modules/features/desktop/rofi/scripts.nix`, remove from `services.polybar.settings`:

```nix
      "module/network".click-left = "exec ${networkMenu}/bin/rofi-network-menu &";
```

- [ ] **Step 5: Remove i3 keybinding for network menu**

In `home-modules/features/desktop/rofi/scripts.nix`, remove from `xsession.windowManager.i3.config.keybindings`:

```nix
        "${mod}+Shift+n" = "exec ${networkMenu}/bin/rofi-network-menu";
```

- [ ] **Step 6: Remove networkThemeRasi from rofi/default.nix**

In `home-modules/features/desktop/rofi/default.nix`, remove the `networkThemeRasi` let-binding (lines 281–367, the full `networkThemeRasi = '' ... '';` block).

- [ ] **Step 7: Remove network-theme.rasi xdg entry**

In `home-modules/features/desktop/rofi/default.nix`, remove from `xdg.configFile`:

```nix
      "rofi/network-theme.rasi".text = networkThemeRasi;
```

- [ ] **Step 8: Stage and verify**

```bash
git add -A
just qa
```

Expected: all checks pass.

- [ ] **Step 9: Commit**

```bash
git commit -m "chore: remove rofi network menu (using nm-applet tray icon instead)"
```

---

## Task 3: Replace clipmenu with copyq

**Files:**
- Delete: `home-modules/features/desktop/rofi/scripts/clipboard-menu.sh`
- Modify: `home-modules/features/desktop/rofi/scripts.nix`
- Modify: `home-modules/features/desktop/rofi/default.nix`
- Modify: `home-configurations/vino/hosts/bandit.nix`
- Modify: `home-modules/features/desktop/i3/keybindings.nix`
- Modify: `home-modules/features/desktop/i3/config.nix`

- [ ] **Step 1: Delete the clipboard menu shell script**

```bash
rm home-modules/features/desktop/rofi/scripts/clipboard-menu.sh
```

- [ ] **Step 2: Remove clipboardMenu derivation from scripts.nix**

In `home-modules/features/desktop/rofi/scripts.nix`, remove the `clipboardMenu` let-binding (lines 32–39):

```nix
# Remove this block:
  clipboardMenu = pkgs.writeShellApplication {
    name = "rofi-clipboard-menu";
    runtimeInputs = [
      pkgs.clipmenu
      pkgs.rofi
    ];
    text = builtins.readFile ./scripts/clipboard-menu.sh;
  };
```

- [ ] **Step 3: Remove clipboardMenu from home.packages**

In `home-modules/features/desktop/rofi/scripts.nix`, in the `home.packages` list, remove:

```nix
      clipboardMenu
```

- [ ] **Step 4: Remove the Mod+Shift+v keybinding from scripts.nix**

In `home-modules/features/desktop/rofi/scripts.nix`, remove from `xsession.windowManager.i3.config.keybindings`:

```nix
        "${mod}+Shift+v" = "exec ${clipboardMenu}/bin/rofi-clipboard-menu";
```

- [ ] **Step 5: Remove clipboardThemeRasi from rofi/default.nix**

In `home-modules/features/desktop/rofi/default.nix`, remove the `clipboardThemeRasi` let-binding (lines 369–455, the full `clipboardThemeRasi = '' ... '';` block).

- [ ] **Step 6: Remove clipboard-theme.rasi xdg entry**

In `home-modules/features/desktop/rofi/default.nix`, remove from `xdg.configFile`:

```nix
      "rofi/clipboard-theme.rasi".text = clipboardThemeRasi;
```

- [ ] **Step 7: Disable clipboard module in bandit host config**

In `home-configurations/vino/hosts/bandit.nix`, remove:

```nix
      clipboard.enable = true;
```

- [ ] **Step 8: Add copyq keybinding to i3**

In `home-modules/features/desktop/i3/keybindings.nix`, add to `systemBindings`:

```nix
    "${mod}+Shift+v" = "exec copyq toggle";
```

Place it near the other app-launch bindings (after `"${mod}+n"` for Joplin is a good spot).

- [ ] **Step 9: Add copyq float rule to i3 config**

In `home-modules/features/desktop/i3/config.nix`, add to `window.commands` list (after the Blueman entry, before the Thunar entry):

```nix
      {
        command = "floating enable, resize set 900 600";
        criteria = {
          class = "copyq";
        };
      }
```

- [ ] **Step 10: Stage and verify**

```bash
git add -A
just qa
```

Expected: all checks pass.

- [ ] **Step 11: Commit**

```bash
git commit -m "chore: replace clipmenu with copyq (Mod+Shift+v preserved, image support added)"
```

---

## Task 4: Remove Redundant desktopPkgs Entries

HM service/program modules auto-add their own package. These four entries in `desktopPkgs` (profiles.nix) are dead weight.

**Files:**
- Modify: `home-modules/profiles.nix`

- [ ] **Step 1: Remove the four redundant packages from desktopPkgs**

In `home-modules/profiles.nix`, within the `desktopPkgs` list, remove these four lines:

```nix
    pkgs.alacritty    # managed by programs.alacritty in terminal/alacritty.nix
    pkgs.dunst        # managed by services.dunst in services.nix
    pkgs.flameshot    # managed by services.flameshot in services.nix
    pkgs.picom        # managed by services.picom in services.nix
```

Note: `pkgs.autotiling` stays — it's needed in `home.packages` for the i3 autostart entry (the `runtimeInputs` in rofi scripts only makes it available inside those scripts, not on the session PATH).

- [ ] **Step 2: Stage and verify**

```bash
git add -A
just qa
```

Expected: all checks pass.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore: remove redundant desktopPkgs entries managed by HM services/programs"
```

---

## Task 5: Final Verification

- [ ] **Step 1: Full QA pass**

```bash
just qa
```

Expected: clean exit, no warnings treated as errors.

- [ ] **Step 2: Sanity-check the file list**

Confirm these files no longer exist:
```bash
ls home-modules/features/desktop/bitwarden.nix        # should error
ls home-modules/features/desktop/bitwarden-menu.sh    # should error
ls home-modules/features/desktop/rofi/scripts/network-menu.sh   # should error
ls home-modules/features/desktop/rofi/scripts/clipboard-menu.sh # should error
```

- [ ] **Step 3: Confirm copyq is still in desktopPkgs**

```bash
grep copyq home-modules/profiles.nix
```

Expected: `pkgs.copyq` present (it was not removed — it replaces clipmenu, not added fresh).
