# Tor Toggle + Polybar Redesign — Design Spec

**Date:** 2026-04-02
**Status:** Approved

## Overview

Two related changes delivered together:

1. **Polybar visual overhaul** — uniform dark segment backgrounds, color only in text/icons, rounded corners, edge padding, host icon fix
2. **Tor toggle** — `just tor` command that starts/stops transparent Tor routing; polybar network module switches to purple + 🧅 + Tor exit IP when active

## Goals

- All polybar modules share a single dark segment background (`#2d2d2d`); accent colors appear only in text and icons
- Bar has rounded corners (`radius = 8`), small gap from screen edges on all sides
- Cleaner separator: remove the `separator = "."` hack, use `module-margin` instead
- Host module: replace wide `󱩊` icon with compact `󰒋` to fix hostname clipping
- `just tor` toggles Tor routing on/off from any terminal; no reboot needed
- While Tor is active, the polybar network slot shows `🧅 <exit-ip>` in purple instead of SSID
- Tor routing does NOT start on boot — manual-only; cleared on shutdown via `/run` tmpfs
- WiFi interface: `wlp1s0`

## Non-Goals

- i3 keyboard shortcut for Tor toggle (terminal command only)
- Desktop notification on toggle
- Persistent Tor state across reboots

---

## Architecture

### 1. Polybar Visual Changes

**`lib/default.nix` — update `mkPolybarTwoTone` and `mkPolybarTwoToneState`**

Both helpers currently produce two differently-colored blocks (dark icon bg + bright label bg, black text). Change them to produce a single uniform dark background with colored foreground:

```nix
mkPolybarTwoTone = { icon, color, colorAlt ? "${color}-alt", fg ? "black" }:
{
  format-prefix = "  ${icon} ";
  format-prefix-foreground = "\${colors.${colorAlt}}";   # colored icon
  format-prefix-background = "\${colors.module-bg}";     # uniform dark
  label-foreground = "\${colors.${colorAlt}}";           # colored text
  label-background = "\${colors.module-bg}";             # uniform dark
  label-padding-left = 1;
  label-padding-right = 1;
};
```

Same pattern for `mkPolybarTwoToneState` (prefixed by state name).

**`home-modules/features/desktop/polybar/colors.nix` — add `module-bg`**

```nix
module-bg = "#2d2d2d";  # uniform segment background for all modules
```

**`home-modules/features/desktop/polybar/default.nix` — bar geometry**

```nix
"bar/top" = {
  width = "calc(100% - 10px)";
  offset-x = 5;
  offset-y = 5;
  radius = 8;
  module-margin = 2;
  # remove: separator, separator-foreground, border-size, border-color
  ...
};
```

**`home-modules/features/desktop/polybar/modules.nix` — module updates**

- `module/menu`: `format-background = module-bg`, `format-foreground = orange-alt`
- `module/i3`: focused label → `yellow-alt` text on `module-bg`; unfocused → `muted` text on `module-bg`
- `module/host`: change icon `󱩊` → `󰒋` (fixes clipping)
- `module/network`: replace `internal/network` with `custom/script` (see Tor section below)

---

### 2. Tor Toggle

**`nixos-modules/features/security/tor-routing.nix` — add `manualMode` option**

New option `features.security.tor-routing.manualMode` (default `false`). When `true`, removes `wantedBy = ["multi-user.target"]` from `nftables-tor-routing.service` so the service is not started at boot and is purely manual.

```nix
manualMode = lib.mkOption {
  type = lib.types.bool;
  default = false;
  description = "Do not start Tor routing at boot; enable manually with systemctl or just tor.";
};
```

Applied in the service definition:
```nix
systemd.services.nftables-tor-routing = {
  wantedBy = lib.mkIf (!cfg.manualMode) [ "multi-user.target" ];
  ...
};
```

**`nixos-configurations/bandit/default.nix` — enable tor-routing**

```nix
features.security.tor-routing = {
  enable = true;
  excludedUIDs = [ "vino" ];  # user's own traffic bypasses Tor
  manualMode = true;           # manual toggle only, not at boot
};
```

**`justfile` — `just tor` recipe**

```bash
tor:
    @if [ -f /run/tor-routing-active ]; then \
      echo "Stopping Tor routing..."; \
      sudo systemctl stop nftables-tor-routing.service; \
      sudo rm -f /run/tor-routing-active; \
    else \
      echo "Starting Tor routing..."; \
      sudo systemctl start nftables-tor-routing.service; \
      sudo touch /run/tor-routing-active; \
    fi
```

`/run/tor-routing-active` lives on tmpfs — automatically gone after shutdown. Starting `nftables-tor-routing.service` automatically starts `tor.service` (via `Requires=`). Stopping it removes the nftables table; tor daemon may remain running idle.

---

### 3. Polybar Network Module (Tor-aware)

Replace `internal/network` with a `custom/script` that checks the flag file:

```bash
#!/usr/bin/env bash
# polybar-network: shows SSID normally, Tor exit IP when routing is active
if [ -f /run/tor-routing-active ]; then
  IP=$(curl --socks5 127.0.0.1:9050 --max-time 5 -s https://api.ipify.org 2>/dev/null || echo "tor:?")
  echo "%{F#d3869b}🧅 ${IP}%{F-}"
else
  SSID=$(iwgetid -r wlp1s0 2>/dev/null || echo "off")
  if [ "$SSID" = "" ]; then
    echo "%{F#cc241d}󰖪 off%{F-}"
  else
    echo "%{F#b8bb26}󰖩 ${SSID}%{F-}"
  fi
fi
```

The script uses polybar inline color tags (`%{F#hex}...%{F-}`) since the module no longer uses the two-tone helper. Module definition:

```nix
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
```

`networkScript` is a `pkgs.writeShellScript` derivation defined in the `let` block of `modules.nix`.

---

## Files Changed

| File | Change |
|------|--------|
| `lib/default.nix` | Update `mkPolybarTwoTone` + `mkPolybarTwoToneState` to uniform dark bg + colored fg |
| `home-modules/features/desktop/polybar/colors.nix` | Add `module-bg = "#2d2d2d"` |
| `home-modules/features/desktop/polybar/default.nix` | Bar geometry: radius, width, offset, margin; remove separator/border |
| `home-modules/features/desktop/polybar/modules.nix` | Menu style, i3 style, host icon, network → custom/script |
| `nixos-modules/features/security/tor-routing.nix` | Add `manualMode` option |
| `nixos-configurations/bandit/default.nix` | Enable tor-routing with manualMode + excludedUIDs |
| `justfile` | Add `just tor` recipe |

---

## Bandit Configuration

```nix
features.security.tor-routing = {
  enable = true;
  excludedUIDs = [ "vino" ];
  manualMode = true;
};
```

---

## Shutdown Behaviour

`/run/tor-routing-active` is on tmpfs and is gone after every power cycle. If the machine is shut down while Tor is active, the flag disappears automatically — no manual cleanup needed. On next boot, Tor routing is off by default.
