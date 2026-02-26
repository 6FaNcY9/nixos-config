# Config Review Design — Targeted Duplication Fixes

**Date:** 2026-02-26
**Scope:** Approach A — fix concrete duplication and idiom issues; leave well-organized large files alone.

## Summary

Three targeted improvements across `fish.nix`, `rofi/default.nix`, and `i3/keybindings.nix`. No file splitting. No changes to files that are already well-organized. Exclude `.direnv` from all review scope.

---

## Change 1: `home-modules/features/shell/fish.nix` — secret loader helper

**Problem:** Three identical 3-line blocks for loading sops secrets into fish environment variables (lines 36–46).

**Fix:** Add a local `loadSecret` helper in the `let` block; replace 3 blocks with 3 interpolated calls.

```nix
let
  loadSecret = path: envVar: ''
    if test -r ${path}
      set -x ${envVar} (cat ${path})
    end
  '';
in
# in interactiveShellInit:
${loadSecret config.sops.secrets.github_mcp_pat.path "GITHUB_MCP_PAT"}
${loadSecret config.sops.secrets.exa_api_key.path "EXA_API_KEY"}
${loadSecret config.sops.secrets.context7_api_key.path "CONTEXT7_API_KEY"}
```

`vibe.nix` keeps its single instance as-is (one call does not warrant sharing).

---

## Change 2: `home-modules/features/desktop/rofi/default.nix` — map over theme filenames

**Problem:** 7 intermediate `let` bindings (`themeText`, `configText`, …) plus 7 parallel `xdg.configFile` assignments — two places to update when adding a new theme.

**Fix:** Collapse to a single `listToAttrs` + `map`, removing all intermediate variables.

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

Adding a new theme in future = one list entry instead of two lines in two places.

---

## Change 3: `home-modules/features/desktop/i3/keybindings.nix` — media key helper

**Problem:** 8 bindings each repeat `exec --no-startup-id` and full `${pkgs.X}/bin/X` paths, making each binding span 2 lines.

**Fix:** Add local package aliases and a one-line `execMediaKey` wrapper; extract bindings into a `mediaKeys` attrset merged at the end.

```nix
let
  execMediaKey  = cmd: "exec --no-startup-id ${cmd}";
  pactl         = "${pkgs.pulseaudio}/bin/pactl";
  brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
  playerctl     = "${pkgs.playerctl}/bin/playerctl";

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
in
xsession.windowManager.i3.config.keybindings = lib.mkOptionDefault (
  directionalFocus // directionalMove // layoutBindings // systemBindings // mediaKeys // workspaceSwitch // workspaceMove
);
```

---

## Out of Scope (Deliberately)

- `polybar/modules.nix` (284 lines) — well-organized, no splitting needed at current size
- `nixvim/plugins.nix` (244 lines) — single monolithic file is acceptable
- `fish.nix` `shellAbbrs` — inline is correct; abbreviations benefit from visibility
- `vibe.nix` single secret block — not duplication at 1 instance
- `.direnv/` — excluded from all review
