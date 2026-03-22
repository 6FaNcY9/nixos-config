# FileZilla Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Home Manager feature module that configures FileZilla with sensible defaults, security hardening, and a tiling-friendly layout, with theming delivered automatically via the existing Stylix GTK3 setup.

**Architecture:** A single feature module at `home-modules/features/desktop/filezilla.nix` manages two config files: `fzdefaults.xml` (read-only Nix store symlink at `~/.filezilla/`) for immutable password-save suppression, and `filezilla.xml` (copied first-run via `home.activation`) for comprehensive writable settings. FileZilla inherits theming from wxWidgets' GTK3 backend — no Stylix module needed.

**Tech Stack:** Nix, Home Manager (`home.file`, `home.activation`, `pkgs.writeText`, `lib.hm.dag.entryAfter`)

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `home-modules/features/desktop/filezilla.nix` | **Create** | Feature option, fzdefaults.xml symlink, filezilla.xml first-run activation |
| `home-modules/features/desktop/default.nix` | **Modify** | Register `./filezilla.nix` in imports |
| `home-configurations/vino/hosts/bandit.nix` | **Modify** | Enable `features.desktop.filezilla` |

---

## Key Background (read before touching any file)

- **ez-configs** auto-discovers modules from `home-modules/default.nix` chain — no manual wiring beyond the aggregator `default.nix`.
- **Feature module pattern**: every module in `home-modules/features/` declares `options.features.<cat>.<name>.enable = lib.mkEnableOption "..."` and gates its `config` block behind `lib.mkIf cfg.enable { ... }`.
- **`home.file`** creates read-only Nix store symlinks. Use it for files the app never writes to.
- **`xdg.configFile`** is `home.file` scoped to `~/.config/`. Do NOT use it here for `fzdefaults.xml` — FileZilla does not search `~/.config/filezilla/` for `fzdefaults.xml`. It searches `~/.filezilla/`, `/etc/filezilla/`, and the install-prefix `share/`.
- **`home.activation`** runs shell scripts during `home-manager switch`. Use `lib.hm.dag.entryAfter [ "writeBoundary" ]`. Prefix all effectful commands with `$DRY_RUN_CMD` (project convention, matches `qutebrowser.nix`).
- **`pkgs.writeText "name" "content"`** writes a string to the Nix store and returns its store path. Use this to embed the XML template.
- **`just qa`** runs `nix run .#qa` — treefmt (nixfmt-rfc-style), statix, deadnix, `nix flake check`. Errors on warnings. Run after every file change.
- New files must be **`git add`ed** before `nix flake check` sees them (the flake evaluator only reads git-tracked files).

---

## Task 1: Create `filezilla.nix`

**Files:**
- Create: `home-modules/features/desktop/filezilla.nix`

- [ ] **Step 1: Write the module**

Create `home-modules/features/desktop/filezilla.nix` with this exact content:

```nix
# FileZilla FTP/SFTP client configuration
#
# Manages two config files:
#   ~/.filezilla/fzdefaults.xml  — read-only Nix symlink; sets Kiosk mode 1
#                                  (no password saving) and disables update checks
#   ~/.config/filezilla/filezilla.xml — copied first-run via home.activation;
#                                       writable so FileZilla can save runtime state
#
# Theming: wxWidgets uses GTK3 as its backend, so Stylix's GTK theme applies automatically.
# No Stylix FileZilla target is needed.
#
# Reset to Nix defaults: rm ~/.config/filezilla/filezilla.xml && home-manager switch
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.features.desktop.filezilla;
in
{
  options.features.desktop.filezilla.enable = lib.mkEnableOption "FileZilla FTP/SFTP client configuration";

  config = lib.mkIf cfg.enable (
    let
      filezillaConfigFile = pkgs.writeText "filezilla.xml" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <FileZilla3 version="3.67.1" platform="linux">
          <Settings>
            <!-- Network -->
            <Setting name="Use Pasv mode">1</Setting>
            <Setting name="Timeout">20</Setting>
            <Setting name="Reconnect count">2</Setting>
            <Setting name="Reconnect delay">5</Setting>
            <Setting name="FTP Keep-alive commands">1</Setting>
            <!-- Transfers -->
            <Setting name="Number of Transfers">4</Setting>
            <Setting name="Concurrent download limit">4</Setting>
            <Setting name="Concurrent upload limit">2</Setting>
            <Setting name="Socket recv buffer size (v2)">4194304</Setting>
            <Setting name="Socket send buffer size (v2)">262144</Setting>
            <Setting name="Enable speed limits">0</Setting>
            <!-- File handling -->
            <Setting name="Ascii Binary mode">0</Setting>
            <Setting name="Auto Ascii no extension">1</Setting>
            <Setting name="Auto Ascii dotfiles">1</Setting>
            <Setting name="Allow transfermode fallback">1</Setting>
            <Setting name="Preserve timestamps">1</Setting>
            <Setting name="Enable invalid char filter">1</Setting>
            <Setting name="Invalid char replace">_</Setting>
            <Setting name="View hidden files">1</Setting>
            <!-- Interface -->
            <Setting name="File Pane Layout">0</Setting>
            <Setting name="File Pane Swap">0</Setting>
            <Setting name="Show Tree Local">1</Setting>
            <Setting name="Show Tree Remote">1</Setting>
            <Setting name="Show message log">1</Setting>
            <Setting name="Show queue">1</Setting>
            <Setting name="Show quickconnect bar">1</Setting>
            <Setting name="Filelist status bar">1</Setting>
            <Setting name="Queue successful autoclear">1</Setting>
            <Setting name="Minimize to tray">0</Setting>
            <Setting name="Show debug menu">0</Setting>
            <Setting name="Toolbar hidden">0</Setting>
            <!-- Column widths (local: name/size/type/modified, remote: +permissions/owner) -->
            <Setting name="Local filelist colwidths">220 80 110 130</Setting>
            <Setting name="Remote filelist colwidths">260 75 95 105 85 85</Setting>
            <Setting name="Queue column widths">200 65 200 90 65 160</Setting>
            <!-- Suppress first-run welcome dialog permanently (fake high version) -->
            <Setting name="Greeting version">9.9.9</Setting>
            <!-- Disable update check (belt-and-suspenders alongside fzdefaults.xml) -->
            <Setting name="Update Check">0</Setting>
          </Settings>
        </FileZilla3>
      '';
    in
    {
      # fzdefaults.xml — read-only administrative defaults.
      # FileZilla searches ~/.filezilla/ for this file (NOT ~/.config/filezilla/).
      # Kiosk mode 1: FileZilla saves all settings but never persists passwords.
      home.file.".filezilla/fzdefaults.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <FileZilla3>
          <Settings>
            <Setting name="Kiosk mode">1</Setting>
            <Setting name="Disable update check">1</Setting>
          </Settings>
        </FileZilla3>
      '';

      # filezilla.xml — main settings file, must be writable at runtime.
      # Copied once on first home-manager switch; never overwritten so runtime
      # state (trusted TLS certs, column widths, site manager entries) persists.
      home.activation.filezillaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.config/filezilla"
        if [ ! -f "$HOME/.config/filezilla/filezilla.xml" ]; then
          $DRY_RUN_CMD cp ${filezillaConfigFile} "$HOME/.config/filezilla/filezilla.xml"
          $DRY_RUN_CMD chmod 600 "$HOME/.config/filezilla/filezilla.xml"
        fi
      '';
    }
  );
}
```

- [ ] **Step 2: `git add` the new file** (required before `nix flake check` sees it)

```bash
git add home-modules/features/desktop/filezilla.nix
```

---

## Task 2: Register in the desktop aggregator

**Files:**
- Modify: `home-modules/features/desktop/default.nix`

- [ ] **Step 1: Add `./filezilla.nix` to the imports list**

Current content of `home-modules/features/desktop/default.nix`:

```nix
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
  ];
}
```

Add `./filezilla.nix` after `./vibe`:

```nix
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
  ];
}
```

---

## Task 3: Enable the feature on bandit

**Files:**
- Modify: `home-configurations/vino/hosts/bandit.nix`

- [ ] **Step 1: Add `filezilla.enable = true` to the `features.desktop` block**

Current `features.desktop` block in `home-configurations/vino/hosts/bandit.nix`:

```nix
features = {
  ...
  desktop = {
    services.enable = true;
    clipboard.enable = true;
    lock.enable = true;
    qutebrowser.enable = true;
    firefox.enable = true;
    xfce-session.enable = true;
    i3.enable = true;
    polybar.enable = true;
    rofi.enable = true;
    vibe.enable = true;
  };
};
```

Add `filezilla.enable = true;` at the end of the `desktop` block:

```nix
features = {
  ...
  desktop = {
    services.enable = true;
    clipboard.enable = true;
    lock.enable = true;
    qutebrowser.enable = true;
    firefox.enable = true;
    xfce-session.enable = true;
    i3.enable = true;
    polybar.enable = true;
    rofi.enable = true;
    vibe.enable = true;
    filezilla.enable = true;
  };
};
```

---

## Task 4: QA and apply

- [ ] **Step 1: Run QA**

```bash
just qa
```

Expected: all formatters and linters pass, `nix flake check` succeeds. If `statix` reports repeated-keys or `deadnix` finds unused bindings in `filezilla.nix`, fix them before continuing.

- [ ] **Step 2: Apply with home-manager**

```bash
just home-switch
```

Expected: activation script prints the `cp` and `chmod` commands (or executes them silently). Check that the file was created:

```bash
ls -la ~/.config/filezilla/filezilla.xml
ls -la ~/.filezilla/fzdefaults.xml
```

`filezilla.xml` should be a regular file (mode `600`). `fzdefaults.xml` should be a symlink into the Nix store.

- [ ] **Step 3: Verify FileZilla starts correctly**

```bash
filezilla
```

Expected:
- No first-run welcome dialog (suppressed by `Greeting version 9.9.9`)
- No update-check network request on launch
- Side-by-side local/remote panes with directory trees on both sides
- Message log and transfer queue panes visible
- Quick-connect bar visible
- UI colours match the Gruvbox Dark Pale theme (dark background, warm text) — this comes from Stylix's GTK3 theme automatically

- [ ] **Step 4: Verify password suppression**

Attempt to connect to any server via Quick Connect or Site Manager. FileZilla should prompt for a password and have no "Remember password" checkbox (or it should be unavailable/greyed out due to Kiosk mode 1).

- [ ] **Step 5: Commit**

```bash
git add home-modules/features/desktop/filezilla.nix \
        home-modules/features/desktop/default.nix \
        home-configurations/vino/hosts/bandit.nix
git commit -m "feat(filezilla): add Home Manager configuration module"
```

---

## Troubleshooting

**`nix flake check` fails with "file not found"**
You forgot `git add home-modules/features/desktop/filezilla.nix`. The flake evaluator only sees git-tracked files.

**`statix` warns about repeated keys**
Check that there are no duplicate attribute names in the Nix attrset. `lib.hm.dag.entryAfter` takes a list — verify the brackets.

**`filezilla.xml` not created after `home-manager switch`**
The file may already exist from a previous FileZilla session. The activation script only copies if the file is absent. Delete it and re-run: `rm ~/.config/filezilla/filezilla.xml && just home-switch`.

**FileZilla shows welcome dialog on first launch**
The `Greeting version` setting in `filezilla.xml` may not have been applied (file already existed). Delete `~/.config/filezilla/filezilla.xml` and re-run `just home-switch` to get the fresh template.

**Theme looks wrong / unstyled**
Ensure Stylix's GTK target is enabled. Check `stylix.targets.gtk.enable` in the NixOS config. FileZilla's theming is entirely dependent on the GTK3 system theme.
