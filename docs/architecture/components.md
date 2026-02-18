# Component Map: Complete File Inventory

**Last Updated:** 2026-02-18  
**Total Files:** 83 .nix files

---

## Overview

This document provides a complete inventory of all 83 Nix configuration files in the nixos-config repository, organized by architectural layer. Each component is documented with its purpose and usage context.

### Layer Organization

The configuration is structured in 7 distinct layers, from high-level orchestration to low-level shared utilities:

1. **Flake Root (3 files)** — Entry point, overlays, pure library functions
2. **Flake Modules (9 files)** — Development infrastructure (apps, devshells, services, checks)
3. **NixOS Configurations (2 files)** — Host-specific system configuration
4. **NixOS Modules (16 files)** — Reusable system-level modules (roles, services, secrets)
5. **Home Configurations (2 files)** — User-specific Home Manager entry points
6. **Home Modules (48 files)** — User environment (desktop, editor, shell, terminal)
7. **Shared Modules (3 files)** — Cross-layer utilities (theming, workspaces)

---

## Layer 1: Flake Root (3 files)

Top-level orchestration, overlays, and pure helper functions.

| File | Purpose | Imported By |
|------|---------|-------------|
| `flake.nix` | Root flake: inputs, ez-configs wiring, overlays, globalArgs, flake-parts orchestration | Nix flake CLI |
| `overlays/default.nix` | Nixpkgs overlay: stable fallback, tree-sitter-cli v0.26.5, opencode bun patch | `flake.nix` |
| `lib/default.nix` | Pure helper functions: color/workspace/profile/polybar/validation/devshell utilities | `flake-modules/_common.nix`, `home-configurations/vino/default.nix`, various modules |

---

## Layer 2: Flake Modules (9 files)

Development infrastructure exposed via `nix run`, `nix develop`, and `nix flake check`.

| File | Purpose | Imported By |
|------|---------|-------------|
| `flake-modules/default.nix` | Aggregator: imports all flake-module parts | `flake.nix` |
| `flake-modules/_common.nix` | Shared perSystem args: cfgLib, commonDevPackages, mkApp helper, opencodePkg | All flake-modules via perSystem |
| `flake-modules/apps.nix` | Nix run apps: update, clean, qa, commit, rebuild, deploy, sysinfo | `flake-modules/default.nix` |
| `flake-modules/checks.nix` | Flake checks: nixos-bandit, home-vino eval targets | `flake-modules/default.nix` |
| `flake-modules/devshells.nix` | Development shells: default, web, rust, go, python, ai | `flake-modules/default.nix` |
| `flake-modules/packages.nix` | Custom package definitions (placeholder for future packages) | `flake-modules/default.nix` |
| `flake-modules/pre-commit.nix` | Pre-commit hooks: treefmt, statix, deadnix, secret detection, large file warnings | `flake-modules/default.nix` |
| `flake-modules/services.nix` | process-compose services: PostgreSQL (pg1), Redis (redis1) for local development | `flake-modules/default.nix` |
| `flake-modules/treefmt.nix` | Code formatter: nixfmt configuration, flake check integration | `flake-modules/default.nix` |

---

## Layer 3: NixOS Configurations (2 files)

Host-specific NixOS system configuration (auto-discovered by ez-configs).

| File | Purpose | Imported By |
|------|---------|-------------|
| `nixos-configurations/bandit/default.nix` | Host config for Framework 13 AMD: roles (desktop, laptop, dev), filesystems, backup, monitoring | ez-configs → `nixosConfigurations.bandit` |
| `nixos-configurations/bandit/hardware-configuration.nix` | Hardware scan output: filesystems, kernel modules, initrd, boot configuration | `nixos-configurations/bandit/default.nix` |

---

## Layer 4: NixOS Modules (16 files)

Reusable system-level configuration modules (auto-imported by ez-configs).

### Core System (7 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `nixos-modules/default.nix` | Aggregator: imports all NixOS modules + external inputs (stylix, sops, home-manager) | ez-configs (auto-imported for all hosts) |
| `nixos-modules/core.nix` | Base system: user accounts, nix settings, essential packages, binary caches, registry | `nixos-modules/default.nix` |
| `nixos-modules/storage.nix` | Storage & boot: GRUB, swap, btrfs snapshots (snapper), kernel packages | `nixos-modules/default.nix` |
| `nixos-modules/services.nix` | System services: acpid, logind, printing (CUPS), sound (pipewire) | `nixos-modules/default.nix` |
| `nixos-modules/secrets.nix` | sops-nix secrets: github_ssh_key, restic_password, key generation, validation | `nixos-modules/default.nix` |
| `nixos-modules/desktop.nix` | Desktop environment: i3-xfce stack (lightdm, xserver, pipewire, polkit) | `nixos-modules/default.nix` |
| `nixos-modules/home-manager.nix` | Home Manager bridge: extraSpecialArgs injection (inputs, username, repoRoot) | `nixos-modules/default.nix` |

### Optional Features (4 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `nixos-modules/monitoring.nix` | Observability: Prometheus, Grafana, exporters, enhanced journald (opt-in) | `nixos-modules/default.nix` |
| `nixos-modules/backup.nix` | Restic automated backups: systemd timers, pruning, encryption (opt-in) | `nixos-modules/default.nix` |
| `nixos-modules/tailscale.nix` | Tailscale VPN configuration (opt-in) | `nixos-modules/default.nix` |
| `nixos-modules/stylix-nixos.nix` | NixOS-specific Stylix targets: GRUB theme, lightdm theme | `nixos-modules/default.nix` |

### Role System (5 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `nixos-modules/roles/default.nix` | Role option definitions: desktop, laptop, server, development | `nixos-modules/default.nix` |
| `nixos-modules/roles/laptop.nix` | Laptop features: power management, bluetooth, fingerprint, Framework 13 AMD quirks | `nixos-modules/roles/default.nix` |
| `nixos-modules/roles/server.nix` | Server hardening: fail2ban, sysctl, nftables, SSH restrictions (opt-in) | `nixos-modules/roles/default.nix` |
| `nixos-modules/roles/development.nix` | Development tools: docker/podman, build essentials, direnv, increased inotify limits | `nixos-modules/roles/default.nix` |
| `nixos-modules/roles/desktop-hardening.nix` | Desktop security: sudo timeout, restricted user actions, firewall baseline | `nixos-modules/roles/default.nix` |

---

## Layer 5: Home Configurations (2 files)

User-specific Home Manager configuration (auto-discovered by ez-configs).

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-configurations/vino/default.nix` | User entry point: imports home-modules, injects _module.args (palette, workspaces, cfgLib), stylix targets | ez-configs → `homeConfigurations."vino@bandit"` |
| `home-configurations/vino/hosts/bandit.nix` | Host-specific overrides: profile enablement (extras, ai), device names (battery, backlight, network) | `home-configurations/vino/default.nix` (via hostModules) |

---

## Layer 6: Home Modules (48 files)

User environment configuration: desktop, editor, shell, terminal, and infrastructure.

### Infrastructure (6 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/default.nix` | Aggregator: imports all HM modules + external inputs (nixvim, sops, stylix) | `home-configurations/vino/default.nix` |
| `home-modules/devices.nix` | Device option definitions: battery, backlight, networkInterface for status widgets | `home-modules/default.nix` |
| `home-modules/nixpkgs.nix` | XDG nixpkgs config: allowUnfree for CLI nix commands | `home-modules/default.nix` |
| `home-modules/package-managers.nix` | XDG compliance: npm, yarn, cargo, go, python paths to prevent home directory bloat | `home-modules/default.nix` |
| `home-modules/profiles.nix` | Package profile system: core, dev, desktop, extras, ai collections (opt-in) | `home-modules/default.nix` |
| `home-modules/secrets.nix` | sops-nix HM secrets: github_mcp_pat, gpg_signing_key, cachix, exa_api_key, context7 | `home-modules/default.nix` |

### Desktop (12 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/desktop/default.nix` | Aggregator: imports all desktop modules | `home-modules/default.nix` |
| `home-modules/desktop/clipboard.nix` | Clipmenu clipboard manager configuration | `home-modules/desktop/default.nix` |
| `home-modules/desktop/firefox.nix` | Firefox browser: bookmarks, search engines, extensions, privacy settings | `home-modules/desktop/default.nix` |
| `home-modules/desktop/services.nix` | Desktop services: dunst notifications, picom compositor, xfce4-notifyd | `home-modules/desktop/default.nix` |
| `home-modules/desktop/xfce-session.nix` | XFCE session services: xfconf, xfsettingsd for i3-xfce hybrid | `home-modules/desktop/default.nix` |

#### i3 Window Manager (5 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/desktop/i3/default.nix` | i3 aggregator: imports config, keybindings, autostart, workspace | `home-modules/desktop/default.nix` |
| `home-modules/desktop/i3/config.nix` | i3 core config: fonts, colors, gaps, borders, floating rules, window modes | `home-modules/desktop/i3/default.nix` |
| `home-modules/desktop/i3/keybindings.nix` | i3 keybindings: workspace switching, window management, layout commands | `home-modules/desktop/i3/default.nix` |
| `home-modules/desktop/i3/autostart.nix` | i3 startup commands: polybar, picom, dunst, clipmenud, autotiling | `home-modules/desktop/i3/default.nix` |
| `home-modules/desktop/i3/workspace.nix` | i3 workspace assignments: Firefox → WS1, etc. | `home-modules/desktop/i3/default.nix` |

#### Polybar Status Bar (3 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/desktop/polybar/default.nix` | Polybar config: bar layout, fonts (Iosevka + Nerd Font icons), module placement | `home-modules/desktop/default.nix` |
| `home-modules/desktop/polybar/colors.nix` | Polybar color scheme: derived from Stylix palette (semantic colors) | `home-modules/desktop/polybar/default.nix` |
| `home-modules/desktop/polybar/modules.nix` | Polybar modules: cpu, memory, battery, network, i3 workspaces, time, power menu | `home-modules/desktop/polybar/default.nix` |

#### Rofi Launcher (2 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/desktop/rofi/default.nix` | Rofi launcher: theme, dmenu integration, window switching | `home-modules/desktop/default.nix` |
| `home-modules/desktop/rofi/scripts.nix` | Rofi scripts: calculator, power menu, clipboard manager, file browser | `home-modules/desktop/rofi/default.nix` |

#### Screen Lock (1 file)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/desktop/lock/default.nix` | i3lock-color lockscreen: blur effect, ring colors from Stylix | `home-modules/desktop/default.nix` |

### Editor (16 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/editor/default.nix` | Aggregator: imports nixvim | `home-modules/default.nix` |

#### Nixvim Neovim (15 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/editor/nixvim/default.nix` | Nixvim aggregator: imports options, autocmds, highlights, ui, plugins, keymaps, extra-config | `home-modules/editor/default.nix` |
| `home-modules/editor/nixvim/options.nix` | Neovim options: line numbers, indent, clipboard, search, split behavior | `home-modules/editor/nixvim/default.nix` |
| `home-modules/editor/nixvim/autocmds.nix` | Neovim autocommands: trim whitespace on save, highlight yank | `home-modules/editor/nixvim/default.nix` |
| `home-modules/editor/nixvim/highlights.nix` | Custom highlight groups for visual consistency | `home-modules/editor/nixvim/default.nix` |
| `home-modules/editor/nixvim/ui.nix` | UI plugins: mini.base16 theme, lualine statusline, indent-blankline, telescope | `home-modules/editor/nixvim/default.nix` |
| `home-modules/editor/nixvim/plugins.nix` | Core plugins: LSP, treesitter, copilot, oil file manager, harpoon, gitsigns | `home-modules/editor/nixvim/default.nix` |
| `home-modules/editor/nixvim/extra-config.nix` | Raw Lua config: LSP handlers, diagnostic configuration, custom functions | `home-modules/editor/nixvim/default.nix` |

#### Nixvim Keymaps (7 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/editor/nixvim/keymaps/default.nix` | Keymap aggregator: imports telescope, editor, copilot, navigation, terminal, lsp | `home-modules/editor/nixvim/default.nix` |
| `home-modules/editor/nixvim/keymaps/telescope.nix` | Telescope fuzzy finder keybindings: find files, grep, buffers, git | `home-modules/editor/nixvim/keymaps/default.nix` |
| `home-modules/editor/nixvim/keymaps/editor.nix` | General editor keybindings: save, quit, buffer navigation, splits | `home-modules/editor/nixvim/keymaps/default.nix` |
| `home-modules/editor/nixvim/keymaps/copilot.nix` | GitHub Copilot keybindings: accept suggestions, navigate | `home-modules/editor/nixvim/keymaps/default.nix` |
| `home-modules/editor/nixvim/keymaps/navigation.nix` | File navigation: oil file manager, harpoon quick marks | `home-modules/editor/nixvim/keymaps/default.nix` |
| `home-modules/editor/nixvim/keymaps/terminal.nix` | Terminal toggle keybindings: horizontal/vertical splits | `home-modules/editor/nixvim/keymaps/default.nix` |
| `home-modules/editor/nixvim/keymaps/lsp.nix` | LSP keybindings: goto definition, hover, rename, code actions | `home-modules/editor/nixvim/keymaps/default.nix` |

### Shell (4 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/shell/default.nix` | Aggregator: imports git, shell, starship | `home-modules/default.nix` |
| `home-modules/shell/git.nix` | Git config: delta diff viewer, aliases, commit signing settings | `home-modules/shell/default.nix` |
| `home-modules/shell/shell.nix` | Fish shell: atuin history, fzf, direnv, zoxide, abbreviations, environment variables | `home-modules/shell/default.nix` |
| `home-modules/shell/starship.nix` | Starship prompt: Nix-focused, git status, minimal design | `home-modules/shell/default.nix` |

### Terminal (6 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/terminal/default.nix` | Aggregator: imports alacritty, tmux, yazi | `home-modules/default.nix` |
| `home-modules/terminal/alacritty.nix` | Alacritty terminal: font, cursor, scrollback (styled by Stylix) | `home-modules/terminal/default.nix` |

#### Tmux (4 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/terminal/tmux/default.nix` | Tmux aggregator: imports keybindings, plugins, statusbar | `home-modules/terminal/default.nix` |
| `home-modules/terminal/tmux/keybindings.nix` | Tmux keybindings: pane navigation, window management, copy mode | `home-modules/terminal/tmux/default.nix` |
| `home-modules/terminal/tmux/plugins.nix` | Tmux plugins: sensible defaults, yank, fzf integration | `home-modules/terminal/tmux/default.nix` |
| `home-modules/terminal/tmux/statusbar.nix` | Tmux status bar styling: colors, layout (styled by Stylix) | `home-modules/terminal/tmux/default.nix` |

#### Yazi (1 file)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/terminal/yazi/default.nix` | Yazi file manager: keybindings, preview, theme | `home-modules/terminal/default.nix` |

---

## Layer 7: Shared Modules (3 files)

Cross-layer utilities used by both NixOS and Home Manager.

| File | Purpose | Imported By |
|------|---------|-------------|
| `shared-modules/stylix-common.nix` | Shared Stylix config: base16 theme (Gruvbox Dark Pale), fonts (Iosevka Term Nerd Font), wallpaper, icons | `nixos-modules/default.nix`, `home-modules/default.nix` |
| `shared-modules/palette.nix` | Semantic color system: derives bg, text, accent, warn, danger from base16 scheme | `home-modules/default.nix` |
| `shared-modules/workspaces.nix` | i3 workspace definitions: 10 workspaces with icons for polybar + i3 | `home-modules/default.nix` |

---

## Statistics

- **Total .nix files:** 83
- **Average file depth:** 3.2 levels
- **Deepest nesting:** 5 levels (`home-modules/editor/nixvim/keymaps/*.nix`)
- **Aggregator files:** 15 (default.nix files that import collections)
- **External inputs:** 15 (nixpkgs, home-manager, stylix, sops-nix, nixvim, etc.)

### Files per Layer

| Layer | File Count | Purpose |
|-------|------------|---------|
| Flake Root | 3 | Entry point and foundational utilities |
| Flake Modules | 9 | Development infrastructure |
| NixOS Configurations | 2 | Host-specific system settings |
| NixOS Modules | 16 | Reusable system modules |
| Home Configurations | 2 | User-specific entry points |
| Home Modules | 48 | User environment (largest layer) |
| Shared Modules | 3 | Cross-layer utilities |

### Deepest Nesting by Category

- **Home Modules (Desktop):** 4 levels deep (e.g., `home-modules/desktop/i3/keybindings.nix`)
- **Home Modules (Editor):** 5 levels deep (e.g., `home-modules/editor/nixvim/keymaps/lsp.nix`)
- **Home Modules (Terminal):** 4 levels deep (e.g., `home-modules/terminal/tmux/plugins.nix`)

### Role Distribution

- **System-level roles:** 5 (laptop, server, development, desktop-hardening, role options)
- **User-level profiles:** 5 (core, dev, desktop, extras, ai)

---

## Related Documentation

- [Wiring Diagram](./wiring.md) — Data flow from flake.nix through configurations
- [Architecture Overview](../README.md) — High-level system design principles
- [Configuration Guide](../guides/configuration.md) — How to modify settings

---

**Last Updated:** 2026-02-18  
**Maintained by:** vino  
**Repository:** `/home/vino/src/nixos-config`
