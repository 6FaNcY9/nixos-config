# Config Cleanup: Bitwarden, Network Menu, Clipboard, Redundant Packages

**Date:** 2026-04-30  
**Scope:** Remove unused rofi integrations, switch clipboard to copyq, trim redundant package declarations.

---

## 1. Bitwarden removal

Remove the entire bitwarden feature — replaced by Bitwarden desktop tray icon.

**Files to delete:**
- `home-modules/features/desktop/bitwarden.nix`
- `home-modules/features/desktop/bitwarden-menu.sh`

**Files to edit:**
- `home-modules/features/desktop/default.nix` — remove `./bitwarden.nix` import
- `home-configurations/vino/hosts/bandit.nix:51` — remove `bitwarden.enable = true`
- `home-modules/features/desktop/i3/keybindings.nix` — remove:
  - `${mod}+p` = `exec rofi-rbw`
  - `${mod}+Shift+b` = `exec qutebrowser vault.bitwarden.com`

**Packages removed:** `rofi-bitwarden-menu`, `bitwarden-cli`, `rbw`, `rofi-rbw`, `pinentry-rofi`, `xdotool`

---

## 2. Rofi network menu removal

Remove the network menu — replaced by nm-applet tray icon (already running via services.network-manager-applet).

**Files to delete:**
- `home-modules/features/desktop/rofi/scripts/network-menu.sh`

**Files to edit:**
- `home-modules/features/desktop/rofi/scripts.nix`:
  - Remove `networkMenu` derivation
  - Remove `networkMenu` from `home.packages`
  - Remove `"module/network".click-left` polybar binding
  - Remove `${mod}+Shift+n` i3 keybinding
- `home-modules/features/desktop/rofi/default.nix`:
  - Remove `networkThemeRasi` let-binding
  - Remove `"rofi/network-theme.rasi"` from `xdg.configFile`

---

## 3. Clipboard: clipmenu → copyq

Replace `clipmenu` (no image support) with `copyq` (already installed, handles images). Keep the same keybinding `Mod+Shift+v`.

**Files to delete:**
- `home-modules/features/desktop/rofi/scripts/clipboard-menu.sh`

**Files to edit:**
- `home-modules/features/desktop/rofi/scripts.nix`:
  - Remove `clipboardMenu` derivation
  - Remove `clipboardMenu` from `home.packages`
  - Remove `${mod}+Shift+v` clipboard keybinding
- `home-modules/features/desktop/rofi/default.nix`:
  - Remove `clipboardThemeRasi` let-binding
  - Remove `"rofi/clipboard-theme.rasi"` from `xdg.configFile`
- `home-configurations/vino/hosts/bandit.nix` — remove `clipboard.enable = true`
- `home-modules/features/desktop/i3/keybindings.nix` — add:
  - `${mod}+Shift+v` = `exec copyq toggle`
- `home-modules/features/desktop/i3/config.nix` — add float rule:
  ```nix
  { command = "floating enable, resize set 900 600"; criteria = { class = "copyq"; }; }
  ```

**copyq is already in `desktopPkgs` — no package change needed.**

---

## 4. Redundant package declarations in profiles.nix

HM service modules auto-add their package to `home.packages` when enabled. These entries in `desktopPkgs` are dead weight:

| Package | Managed by |
|---|---|
| `pkgs.dunst` | `services.dunst.enable = true` in services.nix |
| `pkgs.picom` | `services.picom.enable = true` in services.nix |
| `pkgs.flameshot` | `services.flameshot.enable = true` in services.nix |
| `pkgs.alacritty` | `programs.alacritty` in terminal/alacritty.nix |

Remove these four from `desktopPkgs` in `home-modules/profiles.nix`.

---

## Out of scope

- qutebrowser / firefox (both kept — different use cases)
- `hermes-agent` in aiPkgs vs hermes.nix (separate investigation needed)
- Remaining rofi scripts: power, audio, dropdown — all kept
