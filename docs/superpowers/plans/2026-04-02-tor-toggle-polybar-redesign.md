# Tor Toggle + Polybar Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign polybar to use uniform dark segments with colored text, add rounded corners and edge padding, and add a `just tor` command that toggles transparent Tor routing with a live polybar indicator.

**Architecture:** Update `mkPolybarTwoTone`/`mkPolybarTwoToneState` helpers in `lib/` to produce a uniform dark background with colored foreground instead of two differently-colored blocks. Replace the `internal/network` polybar module with a `custom/script` that switches between SSID display and Tor exit IP based on a tmpfs flag file at `/run/tor-routing-active`. Add a `manualMode` option to the existing `tor-routing` NixOS module so the service is not started at boot.

**Tech Stack:** Nix, Home Manager, Polybar, systemd, nftables, bash, curl, iwgetid

---

## Files

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/default.nix` | Modify | Update `mkPolybarTwoTone` + `mkPolybarTwoToneState` helpers |
| `home-modules/features/desktop/polybar/colors.nix` | Modify | Add `module-bg = "#2d2d2d"` |
| `home-modules/features/desktop/polybar/default.nix` | Modify | Bar geometry: rounded corners, edge gap, remove border/separator hack |
| `home-modules/features/desktop/polybar/modules.nix` | Modify | MENU style, i3 style, host icon fix, network → tor-aware script |
| `nixos-modules/features/security/tor-routing.nix` | Modify | Add `manualMode` option |
| `nixos-configurations/bandit/default.nix` | Modify | Enable tor-routing with manualMode + excludedUIDs |
| `justfile` | Modify | Add `just tor` toggle recipe |

---

## Task 1: Update mkPolybarTwoTone helpers + add module-bg color

**Files:**
- Modify: `lib/default.nix:177-215`
- Modify: `home-modules/features/desktop/polybar/colors.nix:11-49`

- [ ] **Step 1: Update `mkPolybarTwoTone` in `lib/default.nix`**

Replace lines 177–194 (the `mkPolybarTwoTone` function) with:

```nix
  # mkPolybarTwoTone :: { icon :: Str, color :: Str, colorAlt :: Str? } -> AttrSet
  # Uniform-background polybar module style: single dark segment, colored icon + text.
  # icon: the NerdFont/FA glyph to prefix
  # color: base color name (used to derive colorAlt default)
  # colorAlt: the bright accent color key for foreground text (default: "${color}-alt")
  mkPolybarTwoTone =
    {
      icon,
      color,
      colorAlt ? "${color}-alt",
    }:
    {
      format-prefix = "  ${icon} ";
      format-prefix-foreground = "\${colors.${colorAlt}}";
      format-prefix-background = "\${colors.module-bg}";
      label-foreground = "\${colors.${colorAlt}}";
      label-background = "\${colors.module-bg}";
      label-padding-left = 1;
      label-padding-right = 1;
    };
```

- [ ] **Step 2: Update `mkPolybarTwoToneState` in `lib/default.nix`**

Replace lines 196–215 (the `mkPolybarTwoToneState` function) with:

```nix
  # mkPolybarTwoToneState :: { state :: Str, icon :: Str, color :: Str, colorAlt :: Str? } -> AttrSet
  # Uniform-background style for a named state (e.g. format-volume, format-charging).
  mkPolybarTwoToneState =
    {
      state,
      icon,
      color,
      colorAlt ? "${color}-alt",
    }:
    {
      "format-${state}-prefix" = "  ${icon} ";
      "format-${state}-prefix-foreground" = "\${colors.${colorAlt}}";
      "format-${state}-prefix-background" = "\${colors.module-bg}";
      "format-${state}" = "<label-${state}>";
      "label-${state}-foreground" = "\${colors.${colorAlt}}";
      "label-${state}-background" = "\${colors.module-bg}";
      "label-${state}-padding-left" = 1;
      "label-${state}-padding-right" = 1;
    };
```

- [ ] **Step 3: Add `module-bg` to `colors.nix`**

In `home-modules/features/desktop/polybar/colors.nix`, add `module-bg` after the `transparent` line (line 17). The full colors attrset should include:

```nix
    module-bg = "#2d2d2d"; # uniform segment background — all modules use this
```

Insert it right after:
```nix
    transparent = "#00000000";
```

- [ ] **Step 4: Run QA**

```bash
cd /home/vino/src/nixos-config && just qa
```

Expected: exits 0. If deadnix complains about unused `fg` parameter — it was already removed in the new signatures above, so this should pass cleanly.

- [ ] **Step 5: Commit**

```bash
git add lib/default.nix home-modules/features/desktop/polybar/colors.nix
git commit -m "refactor(polybar): switch to uniform dark segments in mkPolybarTwoTone helpers"
```

---

## Task 2: Update bar geometry and basic module styles

**Files:**
- Modify: `home-modules/features/desktop/polybar/default.nix:66-88`
- Modify: `home-modules/features/desktop/polybar/modules.nix:27-68`

- [ ] **Step 1: Update bar geometry in `default.nix`**

Replace the entire `"bar/top"` attrset (lines 66–88) with:

```nix
        "bar/top" = {
          width = "calc(100% - 10px)";
          offset-x = 5;
          offset-y = 5;
          height = "18pt";
          radius = 8;
          dpi = 100;
          background = "\${colors.dark}";
          foreground = "\${colors.muted}";
          padding = 0;
          module-margin = 2;
          line-size = "0pt";
          font-0 = "${stylixFonts.monospace.name}:size=14:weight=bold;2";
          font-1 = "Symbols Nerd Font Mono:size=14;3";
          modules-left = modulesLeft;
          modules-center = modulesCenter;
          modules-right = modulesRight;
          cursor-click = "pointer";
          enable-ipc = true;
          tray-position = "none";
        };
```

Removed: `border-size`, `border-color`, `separator`, `separator-foreground`
Added: `offset-x = 5`, `offset-y = 5`, `radius = 8`
Changed: `width`, `module-margin = 2`

- [ ] **Step 2: Update MENU module style in `modules.nix`**

Replace the `"module/menu"` attrset (lines 27–33) with:

```nix
      "module/menu" = {
        type = "custom/text";
        format = " MENU ";
        click-right = "exec ${pkgs.rofi}/bin/rofi -show drun -disable-history -show-icons &";
        format-foreground = "\${colors.orange-alt}";
        format-background = "\${colors.module-bg}";
      };
```

- [ ] **Step 3: Update i3 workspace module style in `modules.nix`**

Replace lines 49–65 (the label-focused through label-separator block) with:

```nix
        label-mode = " %mode% ";
        label-mode-padding = 1;
        label-mode-background = "\${colors.red}";
        label-mode-foreground = "\${colors.red-alt}";
        label-focused = " %icon% ";
        label-focused-foreground = "\${colors.yellow-alt}";
        label-focused-background = "\${colors.module-bg}";
        label-focused-underline = "\${colors.yellow-alt}";
        label-focused-padding = 0;
        label-unfocused = " %icon% ";
        label-unfocused-foreground = "\${colors.muted}";
        label-unfocused-background = "\${colors.module-bg}";
        label-unfocused-padding = 0;
        label-visible = " %icon% ";
        label-visible-foreground = "\${colors.yellow-alt}";
        label-visible-background = "\${colors.module-bg}";
        label-visible-underline = "\${colors.red}";
        label-visible-padding = 0;
        label-urgent = " %icon% ";
        label-urgent-foreground = "\${colors.red-alt}";
        label-urgent-background = "\${colors.module-bg}";
        label-urgent-padding = 0;
        label-separator = " ";
        label-separator-padding = 0;
```

- [ ] **Step 4: Fix host icon in `modules.nix`**

In the `"module/host"` block (lines 105–114), change the `mkPolybarTwoTone` call:

```nix
      // mkPolybarTwoTone {
        icon = "󰒋 ";
        color = "blue";
      };
```

(was `icon = "󱩊 "` — the laptop icon renders wide and clips "bandit")

- [ ] **Step 5: Run QA**

```bash
just qa
```

Expected: exits 0.

- [ ] **Step 6: Commit**

```bash
git add home-modules/features/desktop/polybar/default.nix home-modules/features/desktop/polybar/modules.nix
git commit -m "feat(polybar): rounded corners, edge padding, uniform module colors, fix host icon"
```

---

## Task 3: Replace network module with tor-aware script

**Files:**
- Modify: `home-modules/features/desktop/polybar/modules.nix:1-22` (let block) and `lines 236-256` (network module)

- [ ] **Step 1: Add `palette` to module args and define `networkScript` in the `let` block**

In `modules.nix`, the function header currently is:
```nix
{
  config,
  pkgs,
  lib,
  workspaces,
  hostname,
  cfgLib,
  ...
}:
```

Change it to:
```nix
{
  config,
  pkgs,
  lib,
  workspaces,
  hostname,
  cfgLib,
  palette,
  ...
}:
```

Then in the `let` block (after line 22), add `networkScript`:

```nix
  networkScript = pkgs.writeShellScript "polybar-network" ''
    if [ -f /run/tor-routing-active ]; then
      IP=$(${pkgs.curl}/bin/curl --socks5 127.0.0.1:9050 --max-time 5 -s https://api.ipify.org 2>/dev/null || echo "tor:?")
      echo "%{F#d3869b}🧅 $IP%{F-}"
    else
      SSID=$(${pkgs.wirelesstools}/bin/iwgetid -r ${config.devices.networkInterface} 2>/dev/null || echo "")
      if [ -z "$SSID" ]; then
        echo "%{F#fb4934}󰖪 off%{F-}"
      else
        echo "%{F#b8bb26}󰖩 $SSID%{F-}"
      fi
    fi
  '';
```

Note: `#d3869b` = Gruvbox purple (Tor active), `#b8bb26` = bright green (connected), `#fb4934` = bright red (disconnected). These are stable Gruvbox Dark Pale values.

- [ ] **Step 2: Replace `module/network` with `custom/script`**

Replace the entire `(lib.optionalAttrs hasNetwork { ... })` block (lines 236–256) with:

```nix
    (lib.optionalAttrs hasNetwork {
      "module/network" = {
        type = "custom/script";
        exec = "${networkScript}";
        interval = 3;
        click-right = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor &";
        format = "<output>";
        format-background = "\${colors.module-bg}";
        label-padding-left = 1;
        label-padding-right = 1;
      };
    })
```

- [ ] **Step 3: Run QA**

```bash
just qa
```

Expected: exits 0. If statix warns about unused `palette` arg — `palette` is available via `_module.args` injection and is used in the future (or you can use it in the script via Nix interpolation to avoid deadnix/statix complaints). If deadnix flags `palette` as unused, use it in the networkScript by replacing the hardcoded hex values:

```nix
  networkScript = pkgs.writeShellScript "polybar-network" ''
    TOR_COLOR="${palette.accent2 or "#d3869b"}"
    ...
  '';
```

Or simply add `_` to suppress: this is a module arg, not a let binding, so deadnix should not flag it.

- [ ] **Step 4: Commit**

```bash
git add home-modules/features/desktop/polybar/modules.nix
git commit -m "feat(polybar): replace network module with tor-aware custom script"
```

---

## Task 4: Add manualMode to tor-routing + enable in bandit

**Files:**
- Modify: `nixos-modules/features/security/tor-routing.nix:33-54` (options block)
- Modify: `nixos-modules/features/security/tor-routing.nix:112-127` (service wantedBy)
- Modify: `nixos-configurations/bandit/default.nix:135-147` (security block)

- [ ] **Step 1: Add `manualMode` option to `tor-routing.nix`**

In the options block of `nixos-modules/features/security/tor-routing.nix`, after the `excludedUIDs` option (line 53), add:

```nix
    manualMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        When true, the nftables-tor-routing service is not started at boot.
        Use `systemctl start nftables-tor-routing` or `just tor` to activate manually.
      '';
    };
```

- [ ] **Step 2: Apply `manualMode` to the service `wantedBy`**

In the `systemd.services.nftables-tor-routing` block (around line 114), change:

```nix
      wantedBy = [ "multi-user.target" ];
```

to:

```nix
      wantedBy = lib.mkIf (!cfg.manualMode) [ "multi-user.target" ];
```

- [ ] **Step 3: Enable tor-routing in `bandit/default.nix`**

In the `security` block (lines 135–147), add the `tor-routing` entry:

```nix
    security = {
      secrets.enable = true;

      desktop-hardening = {
        enable = true;
        protectKernelImage = false;
        firewall.allowedTCPPorts = [ 8181 ];
      };

      clamav = {
        enable = true;
        excludePaths = [ "/home/vino/Documents/Projekts/mrijaPage" ];
      };

      tor-routing = {
        enable = true;
        excludedUIDs = [ "vino" ];
        manualMode = true;
      };
    };
```

`excludedUIDs = ["vino"]` is critical — without it, ALL traffic including Nix substituter downloads and home-manager switches would be routed through Tor when active.

- [ ] **Step 4: Run QA**

```bash
just qa
```

Expected: exits 0.

- [ ] **Step 5: Commit**

```bash
git add nixos-modules/features/security/tor-routing.nix nixos-configurations/bandit/default.nix
git commit -m "feat(security): add manualMode to tor-routing, enable on bandit with user UID bypass"
```

---

## Task 5: Add `just tor` recipe

**Files:**
- Modify: `justfile`

- [ ] **Step 1: Add the Security section with the tor recipe**

Append to `justfile` after the existing Security section (which has scan-home, scan-system, scan):

```just
# Toggle transparent Tor routing on/off
# Active state persists until toggled off or machine reboots (/run is tmpfs)
tor:
    #!/usr/bin/env bash
    if [ -f /run/tor-routing-active ]; then
      echo "Stopping Tor routing..."
      sudo systemctl stop nftables-tor-routing.service
      sudo rm -f /run/tor-routing-active
      echo "Done. Traffic is no longer routed through Tor."
    else
      echo "Starting Tor routing..."
      sudo systemctl start nftables-tor-routing.service
      sudo touch /run/tor-routing-active
      echo "Done. All TCP and DNS traffic is now routed through Tor."
      echo "Polybar will show the Tor exit IP within 3 seconds."
    fi
```

- [ ] **Step 2: Run QA**

```bash
just qa
```

Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add justfile
git commit -m "feat(justfile): add just tor toggle command"
```

---

## Task 6: Validate and push to PR branch

- [ ] **Step 1: Full dry-run NixOS build**

```bash
just rebuild-test
```

Expected: build completes without errors. This validates:
- `mkPolybarTwoTone` changes evaluate correctly against all modules that use them
- `module/network` custom script derivation builds (curl + wirelesstools deps resolve)
- `nftables-tor-routing` service with `manualMode` evaluates correctly
- `module-bg` color key is defined before it's referenced

- [ ] **Step 2: Create feature branch and push**

```bash
git checkout -b feat/tor-toggle-polybar-redesign
git push -u origin feat/tor-toggle-polybar-redesign
```

- [ ] **Step 3: Open PR**

```bash
gh pr create \
  --title "feat: Tor toggle + polybar visual redesign" \
  --body "$(cat <<'EOF'
## Summary
- Polybar: uniform dark segment backgrounds, color in text/icons only
- Bar: rounded corners (radius=8), 5px edge gap all sides, module-margin spacing
- Host module: fix icon clipping (󱩊 → 󰒋)
- Network module: tor-aware script — shows SSID normally, 🧅 + Tor exit IP when active
- `just tor`: toggle transparent Tor routing on/off from any terminal
- Tor routing: manual-only (manualMode=true), cleared on reboot via /run tmpfs
- User UID (vino) excluded from Tor routing so nix/sudo traffic is unaffected

## Test plan
- [ ] `just qa` passes
- [ ] `just rebuild-test` builds without errors
- [ ] After `just rebuild`: polybar shows new style with rounded corners and dark segments
- [ ] `just tor` starts Tor; polybar network slot switches to 🧅 + exit IP within 3s
- [ ] `just tor` again stops Tor; network slot returns to SSID
- [ ] Reboot: Tor routing is off, `/run/tor-routing-active` is gone

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```
