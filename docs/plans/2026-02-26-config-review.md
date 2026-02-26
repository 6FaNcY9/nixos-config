# Config Review — Targeted Duplication Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix three concrete duplication/idiom issues identified in the config review without changing any behavior.

**Architecture:** Pure refactors — no behavioral change. Each task touches exactly one file. Verification is `nix fmt` + `nix flake check`.

**Tech Stack:** Nix, Home Manager, NixOS. No unit tests (declarative config). Verification via `nix flake check --option warn-dirty false`.

---

### Task 1: `fish.nix` — secret loader helper

**Files:**
- Modify: `home-modules/features/shell/fish.nix:11-60`

**Step 1: Add `loadSecret` to the `let` block**

In `fish.nix`, the `let` block currently reads:
```nix
let
  cfg = config.features.shell.fish;
in
```

Replace with:
```nix
let
  cfg = config.features.shell.fish;
  loadSecret = path: envVar: ''
    if test -r ${path}
      set -x ${envVar} (cat ${path})
    end
  '';
in
```

**Step 2: Replace the three inline secret blocks in `interactiveShellInit`**

Remove lines 36–46 (the three `if test -r ... end` blocks):
```nix
          if test -r ${config.sops.secrets.github_mcp_pat.path}
            set -x GITHUB_MCP_PAT (cat ${config.sops.secrets.github_mcp_pat.path})
          end

          if test -r ${config.sops.secrets.exa_api_key.path}
            set -x EXA_API_KEY (cat ${config.sops.secrets.exa_api_key.path})
          end

          if test -r ${config.sops.secrets.context7_api_key.path}
            set -x CONTEXT7_API_KEY (cat ${config.sops.secrets.context7_api_key.path})
          end
```

Replace with:
```nix
          ${loadSecret config.sops.secrets.github_mcp_pat.path "GITHUB_MCP_PAT"}
          ${loadSecret config.sops.secrets.exa_api_key.path "EXA_API_KEY"}
          ${loadSecret config.sops.secrets.context7_api_key.path "CONTEXT7_API_KEY"}
```

**Step 3: Format**

```bash
nix fmt
```
Expected: exits 0, no output.

**Step 4: Verify**

```bash
nix flake check --option warn-dirty false
```
Expected: exits 0. If it errors, check that string interpolation is correct — `${loadSecret ...}` must be inside a Nix string (`''...''`), not outside.

**Step 5: Commit**

```bash
git add home-modules/features/shell/fish.nix
git commit -m "refactor(shell): extract secret loader helper in fish.nix"
```

---

### Task 2: `rofi/default.nix` — map over theme filenames

**Files:**
- Modify: `home-modules/features/desktop/rofi/default.nix:46-75`

**Step 1: Remove the 7 intermediate `let` bindings**

Remove lines 46–52 from the `let` block:
```nix
  themeText        = replace (builtins.readFile ./theme.rasi);
  configText       = replace (builtins.readFile ./config.rasi);
  powermenuText    = replace (builtins.readFile ./powermenu-theme.rasi);
  networkText      = replace (builtins.readFile ./network-theme.rasi);
  clipboardText    = replace (builtins.readFile ./clipboard-theme.rasi);
  audioSwitcherText = replace (builtins.readFile ./audio-switcher-theme.rasi);
  dropdownText     = replace (builtins.readFile ./dropdown-theme.rasi);
```

**Step 2: Replace the `xdg.configFile` block**

Remove the current block (lines 65–75):
```nix
    xdg = {
      configFile = {
        "rofi/theme.rasi".text          = themeText;
        "rofi/config.rasi".text         = configText;
        "rofi/powermenu-theme.rasi".text = powermenuText;
        "rofi/network-theme.rasi".text  = networkText;
        "rofi/clipboard-theme.rasi".text = clipboardText;
        "rofi/audio-switcher-theme.rasi".text = audioSwitcherText;
        "rofi/dropdown-theme.rasi".text = dropdownText;
      };
    };
```

Replace with:
```nix
    xdg.configFile = builtins.listToAttrs (
      map (name: {
        name = "rofi/${name}.rasi";
        value.text = replace (builtins.readFile ./${name}.rasi);
      }) [
        "theme"
        "config"
        "powermenu-theme"
        "network-theme"
        "clipboard-theme"
        "audio-switcher-theme"
        "dropdown-theme"
      ]
    );
```

Note: `builtins.readFile ./${name}.rasi` — the `./${name}.rasi` path is resolved at evaluation time relative to the file's directory. This is valid Nix.

**Step 3: Format**

```bash
nix fmt
```
Expected: exits 0.

**Step 4: Verify**

```bash
nix flake check --option warn-dirty false
```
Expected: exits 0. If it errors with "path does not exist", check that the filename strings in the list exactly match the `.rasi` filenames on disk:
```bash
ls home-modules/features/desktop/rofi/*.rasi
```

**Step 5: Commit**

```bash
git add home-modules/features/desktop/rofi/default.nix
git commit -m "refactor(rofi): map over theme filenames instead of parallel let bindings"
```

---

### Task 3: `i3/keybindings.nix` — media key helper

**Files:**
- Modify: `home-modules/features/desktop/i3/keybindings.nix:1-101`

**Step 1: Add helper aliases and `mediaKeys` attrset to the `let` block**

After line 9 (`mod = "Mod4";`), add:
```nix
  execMediaKey  = cmd: "exec --no-startup-id ${cmd}";
  pactl         = "${pkgs.pulseaudio}/bin/pactl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  playerctl     = "${pkgs.playerctl}/bin/playerctl";
```

After the existing `directionalFocus`, `directionalMove`, `layoutBindings`, `systemBindings` attrsets, add:
```nix
  mediaKeys = {
    "XF86AudioRaiseVolume"  = execMediaKey "${pactl} set-sink-volume @DEFAULT_SINK@ +5%";
    "XF86AudioLowerVolume"  = execMediaKey "${pactl} set-sink-volume @DEFAULT_SINK@ -5%";
    "XF86AudioMute"         = execMediaKey "${pactl} set-sink-mute @DEFAULT_SINK@ toggle";
    "XF86MonBrightnessUp"   = execMediaKey "${brightnessctl} set +10%";
    "XF86MonBrightnessDown" = execMediaKey "${brightnessctl} set 10%-";
    "XF86AudioPlay"         = execMediaKey "${playerctl} play-pause";
    "XF86AudioNext"         = execMediaKey "${playerctl} next";
    "XF86AudioPrev"         = execMediaKey "${playerctl} previous";
  };
```

**Step 2: Remove the inline bindings from `systemBindings` and add `mediaKeys` to the merge**

Remove lines 61–73 from `systemBindings` (the 8 media/brightness bindings).

Update the final merge at line 93 to include `mediaKeys`:
```nix
  xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault (
    directionalFocus
    // directionalMove
    // layoutBindings
    // systemBindings
    // mediaKeys
    // workspaceSwitch
    // workspaceMove
  );
```

**Step 3: Format**

```bash
nix fmt
```
Expected: exits 0.

**Step 4: Verify**

```bash
nix flake check --option warn-dirty false
```
Expected: exits 0.

**Step 5: Commit**

```bash
git add home-modules/features/desktop/i3/keybindings.nix
git commit -m "refactor(i3): extract media key helper and package aliases in keybindings.nix"
```

---

## Verification Reminder

- `nix fmt` produces no output on success (exit 0, "0 changed")
- `nix flake check` builds derivations and runs pre-commit hooks — can take a while
- New files must be `git add`ed before `nix flake check` (flake only sees git-tracked files)
- xorg deprecation warnings are expected and harmless
