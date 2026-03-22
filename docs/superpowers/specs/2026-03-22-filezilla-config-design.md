# FileZilla Configuration Design

**Date:** 2026-03-22
**Status:** Approved

## Overview

Add a Home Manager feature module that configures FileZilla with sensible defaults, security hardening, and tiling-friendly layout. Theming is handled automatically via Stylix's GTK3 support. No new package installation is needed — FileZilla is already in `devPkgs`.

## Research Findings

- **Stylix**: No FileZilla target exists. FileZilla uses wxWidgets with a GTK3 backend, which inherits the system GTK3 theme automatically. Stylix's existing GTK configuration covers FileZilla fully.
- **fzdefaults.xml**: A read-only administrative defaults file FileZilla reads at startup but never writes. Suitable as a Nix store symlink. Supports only three settings: `Kiosk mode`, `Disable update check`, `Config Location`.
- **filezilla.xml**: The main settings file. FileZilla reads and writes it at runtime (column widths, last directory, trusted TLS certs, etc.). Cannot be a read-only Nix store symlink without breaking runtime saves. Must be managed via `home.activation` with a first-run copy strategy.
- **Keyboard shortcuts**: Not configurable via XML — hardcoded in FileZilla's source. GTK accelerator workaround exists but is unreliable and not scriptable. Not included in scope.
- **Password storage**: `Kiosk mode 1` in fzdefaults.xml instructs FileZilla to save all settings normally but never persist passwords to disk.

## Module Structure

**New file:** `home-modules/features/desktop/filezilla.nix`

**Option:**
```nix
options.features.desktop.filezilla.enable = lib.mkEnableOption "FileZilla FTP/SFTP client configuration";
```

**Register in:** `home-modules/features/desktop/default.nix` — add `./filezilla.nix` to the imports list.

**Enable in:** `home-configurations/vino/hosts/bandit.nix` — add `features.desktop.filezilla.enable = true` under the `features.desktop` block.

The module does not install FileZilla (already in `profiles.dev`). It is purely configuration.

## Theming

No Stylix FileZilla module is needed or created. FileZilla inherits the Gruvbox Dark Pale GTK3 theme from the existing `stylix.targets.gtk` configuration. No module action required.

## fzdefaults.xml

Managed via `xdg.configFile."filezilla/fzdefaults.xml"`, creating a read-only Nix store symlink at `~/.config/filezilla/fzdefaults.xml`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<FileZilla3>
  <Settings>
    <Setting name="Kiosk mode">1</Setting>
    <Setting name="Disable update check">1</Setting>
  </Settings>
</FileZilla3>
```

`Kiosk mode 1`: FileZilla saves all user preferences normally but never writes passwords to disk. Prompts for credentials on every connection. Matches the user's requirement to not save passwords.

## filezilla.xml Template (first-run activation)

A Nix string containing the full XML template is stored in the module and written to the Nix store via `pkgs.writeText`. A `home.activation` entry copies it on first run only:

```bash
mkdir -p "$HOME/.config/filezilla"
if [ ! -f "$HOME/.config/filezilla/filezilla.xml" ]; then
  cp ${filezillaConfigFile} "$HOME/.config/filezilla/filezilla.xml"
  chmod 600 "$HOME/.config/filezilla/filezilla.xml"
fi
```

After the first copy the file is fully writable. FileZilla accumulates runtime state (trusted TLS certs, column widths, last directories, site manager entries) naturally. To reset to Nix defaults: delete `~/.config/filezilla/filezilla.xml` and run `home-manager switch`.

### Template Settings

**Network & Transfers**

| Setting | Value | Rationale |
|---|---|---|
| `Use Pasv mode` | `1` | Passive mode works through NAT/firewalls |
| `Timeout` | `20` | 20s connection timeout |
| `Reconnect count` | `2` | Retry twice on disconnect |
| `Reconnect delay` | `5` | 5s between retries |
| `FTP Keep-alive commands` | `1` | Prevent idle disconnects |
| `Number of Transfers` | `4` | Up from default 2 |
| `Concurrent download limit` | `4` | Match Number of Transfers |
| `Concurrent upload limit` | `2` | Conservative on uploads |
| `Socket recv buffer size (v2)` | `4194304` | 4MB receive buffer |
| `Socket send buffer size (v2)` | `262144` | 256KB send buffer |
| `Enable speed limits` | `0` | No artificial throttling |

**File Handling**

| Setting | Value | Rationale |
|---|---|---|
| `Ascii Binary mode` | `0` | Auto-detect; safe for FTP and SFTP |
| `Auto Ascii no extension` | `1` | Extensionless files treated as text |
| `Auto Ascii dotfiles` | `1` | Dotfiles treated as text |
| `Preserve timestamps` | `1` | Keep original file mtimes on download |
| `Enable invalid char filter` | `1` | Sanitise filenames automatically |
| `Invalid char replace` | `_` | Replacement character |
| `View hidden files` | `1` | Show dotfiles on remote servers |
| `Allow transfermode fallback` | `1` | Fall back gracefully if binary fails |

**Interface & Layout**

| Setting | Value | Rationale |
|---|---|---|
| `File Pane Layout` | `0` | Side-by-side (local left, remote right) |
| `File Pane Swap` | `0` | Standard orientation |
| `Show Tree Local` | `1` | Directory tree on local side |
| `Show Tree Remote` | `1` | Directory tree on remote side |
| `Show message log` | `1` | Show protocol log pane |
| `Show queue` | `1` | Show transfer queue pane |
| `Show quickconnect bar` | `1` | Quick-connect bar visible |
| `Filelist status bar` | `1` | File count/size status bar |
| `Queue successful autoclear` | `1` | Auto-clear completed transfers |
| `Minimize to tray` | `0` | Do not minimise to tray |
| `Show debug menu` | `0` | Hide debug menu |
| `Toolbar hidden` | `0` | Toolbar visible |

**Column Widths** (sensible defaults for wide displays)

| Setting | Value |
|---|---|
| `Local filelist colwidths` | `220 80 110 130` |
| `Remote filelist colwidths` | `260 75 95 105 85 85` |
| `Queue column widths` | `200 65 200 90 65 160` |

**Greeting version** is set to suppress the first-launch welcome dialog. The exact version string must be read from `pkgs.filezilla.version` at evaluation time via Nix string interpolation.

## Files Changed

| File | Action |
|---|---|
| `home-modules/features/desktop/filezilla.nix` | Create |
| `home-modules/features/desktop/default.nix` | Add `./filezilla.nix` to imports |
| `home-configurations/vino/hosts/bandit.nix` | Add `features.desktop.filezilla.enable = true` |

## Out of Scope

- Keyboard shortcut remapping (not configurable via XML; hardcoded in FileZilla)
- Predefined server entries (user adds servers manually via Site Manager)
- sops-nix secret integration (no passwords saved)
- Custom icon theme
