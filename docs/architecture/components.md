# Component Map: Complete File Inventory

**Last Updated:** 2026-05-14  
**Total Files:** 128 .nix files

---

## Overview

This document provides a complete inventory of all 128 Nix configuration files in the nixos-config repository, organized by architectural layer. Each component is documented with its purpose and usage context.

### Layer Organization

The configuration is structured in 7 distinct layers, from high-level orchestration to low-level shared utilities:

1. **Flake Root (6 files)** — Entry point, overlays, pure library functions
2. **Flake Modules (8 files)** — Development infrastructure (apps, devshells, checks)
3. **NixOS Configurations (5 files)** — Host-specific system configuration
4. **NixOS Modules (36 files)** — Reusable system-level modules (core, features: desktop/services/storage/security/hardware/development/theme)
5. **Home Configurations (4 files)** — User-specific Home Manager entry points
6. **Home Modules (65 files)** — User environment (core infrastructure + features: desktop, editor, shell, terminal, ai)
7. **Shared Modules (4 files)** — Cross-layer utilities (theming, workspaces)

---

## Layer 1: Flake Root (6 files)

Top-level orchestration, overlays, and pure helper functions.

| File | Purpose | Imported By |
|------|---------|-------------|
| `flake.nix` | Root flake: inputs, ez-configs wiring, overlays, globalArgs, flake-parts orchestration | Nix flake CLI |
| `overlays/default.nix` | Nixpkgs overlay aggregator: imports additions.nix + modifications.nix; single `default` overlay applied to both NixOS and HM pkgs | `flake.nix` |
| `overlays/additions.nix` | Custom package additions: hermes-agent, mistral-vibe, opencode-bun (Bun-latest wrapper) | `overlays/default.nix` |
| `overlays/modifications.nix` | Nixpkgs package modifications and version pins: tree-sitter-cli pinned to 0.26.5 | `overlays/default.nix` |
| `overlays/custom-packages.nix` | Additional custom package definitions | `overlays/default.nix` |
| `lib/default.nix` | Pure helper functions: color/workspace/profile/polybar/validation/devshell utilities | `flake-modules/_common.nix`, `home-configurations/vino/default.nix`, various modules |

---

## Layer 2: Flake Modules (8 files)

Development infrastructure exposed via `nix run`, `nix develop`, and `nix flake check`.

| File | Purpose | Imported By |
|------|---------|-------------|
| `flake-modules/default.nix` | Aggregator: imports all flake-module parts | `flake.nix` |
| `flake-modules/_common.nix` | Shared perSystem args: cfgLib, commonDevPackages, mkApp helper, overlaid OpenCode packages | All flake-modules via perSystem |
| `flake-modules/apps.nix` | Nix run apps: update, clean, qa, commit, rebuild, deploy, sysinfo | `flake-modules/default.nix` |
| `flake-modules/checks.nix` | Flake checks: nixos-bandit, home-vino eval targets | `flake-modules/default.nix` |
| `flake-modules/devshells.nix` | Development shells: default, web, rust, go, python, ai | `flake-modules/default.nix` |
| `flake-modules/packages.nix` | Custom package definitions (placeholder for future packages) | `flake-modules/default.nix` |
| `flake-modules/pre-commit.nix` | Pre-commit hooks: treefmt, statix, deadnix, secret detection, large file warnings | `flake-modules/default.nix` |
| `flake-modules/treefmt.nix` | Code formatter: nixfmt configuration, flake check integration | `flake-modules/default.nix` |

---

## Layer 3: NixOS Configurations (5 files)

Host-specific NixOS system configuration (auto-discovered by ez-configs).

| File | Purpose | Imported By |
|------|---------|-------------|
| `nixos-configurations/bandit/default.nix` | Host config for Framework 13 AMD: features (desktop.i3, laptop, dev), filesystems, monitoring | ez-configs → `nixosConfigurations.bandit` |
| `nixos-configurations/bandit/hardware-configuration.nix` | Hardware scan output: filesystems, kernel modules, initrd, boot configuration | `nixos-configurations/bandit/default.nix` |
| `nixos-configurations/bandit/host-params.nix` | Composition boundary: host-specific parameter values (device names, feature flags) consumed by NixOS modules | `nixos-configurations/bandit/default.nix` |
| `nixos-configurations/homelab/default.nix` | Host config for Intel i9 headless server: SSH, Tailscale, Podman, BTRFS subvolumes | ez-configs → `nixosConfigurations.homelab` |
| `nixos-configurations/homelab/hardware-configuration.nix` | Hardware scan output: filesystems, kernel modules, initrd, boot configuration | `nixos-configurations/homelab/default.nix` |

---

## Layer 4: NixOS Modules (36 files)

Reusable system-level configuration modules (auto-imported by ez-configs).

### Core System (10 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `nixos-modules/default.nix` | Aggregator: imports core + features (and external modules: stylix, sops-nix, stylix-common) | ez-configs (auto-imported for all hosts) |
| `nixos-modules/home-manager.nix` | Home Manager bridge: extraSpecialArgs injection (inputs, username, repoRoot) | host composition roots (e.g. `nixos-configurations/bandit/default.nix`) |
| `nixos-modules/core/default.nix` | Core aggregator: imports all core system modules | `nixos-modules/default.nix` |
| `nixos-modules/core/users.nix` | User accounts: vino user, shell, groups, sudo | `nixos-modules/core/default.nix` |
| `nixos-modules/core/nix.nix` | Nix settings: flakes, binary caches, registry, gc | `nixos-modules/core/default.nix` |
| `nixos-modules/core/networking.nix` | Network base: hostname, firewall, DNS | `nixos-modules/core/default.nix` |
| `nixos-modules/core/packages.nix` | Essential system packages | `nixos-modules/core/default.nix` |
| `nixos-modules/core/programs.nix` | System-level program settings | `nixos-modules/core/default.nix` |
| `nixos-modules/core/fonts.nix` | System fonts: Iosevka Term Nerd Font, nerd-fonts | `nixos-modules/core/default.nix` |
| `nixos-modules/core/oomd.nix` | systemd-oomd out-of-memory daemon configuration | `nixos-modules/core/default.nix` |

### Optional Features (28 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `nixos-modules/features/default.nix` | Features aggregator: imports all feature categories | `nixos-modules/default.nix` |
| `nixos-modules/features/desktop/default.nix` | Desktop features aggregator | `nixos-modules/features/default.nix` |
| `nixos-modules/features/desktop/i3.nix` | Desktop environment: greetd+tuigreet login, i3 window manager, PipeWire audio, polkit | `nixos-modules/features/desktop/default.nix` |
| `nixos-modules/features/development/default.nix` | Development features aggregator | `nixos-modules/features/default.nix` |
| `nixos-modules/features/development/base.nix` | Development tools: Docker, Podman, direnv, build essentials | `nixos-modules/features/development/default.nix` |
| `nixos-modules/features/hardware/default.nix` | Hardware features aggregator | `nixos-modules/features/default.nix` |
| `nixos-modules/features/hardware/laptop.nix` | Laptop hardware: power management, bluetooth, fingerprint, Framework 13 AMD quirks | `nixos-modules/features/hardware/default.nix` |
| `nixos-modules/features/security/default.nix` | Security features aggregator | `nixos-modules/features/default.nix` |
| `nixos-modules/features/security/secrets.nix` | sops-nix secrets: github_ssh_key, gpg-signing-key, validation | `nixos-modules/features/security/default.nix` |
| `nixos-modules/features/security/server-hardening.nix` | Server hardening: fail2ban, sysctl, nftables, SSH restrictions | `nixos-modules/features/security/default.nix` |
| `nixos-modules/features/security/desktop-hardening.nix` | Desktop security: sudo timeout, restricted user actions, firewall baseline | `nixos-modules/features/security/default.nix` |
| `nixos-modules/features/security/clamav.nix` | ClamAV antivirus (opt-in) | `nixos-modules/features/security/default.nix` |
| `nixos-modules/features/services/default.nix` | Services features aggregator | `nixos-modules/features/default.nix` |
| `nixos-modules/features/services/monitoring.nix` | Observability: Prometheus, Grafana, exporters, enhanced journald (opt-in) | `nixos-modules/features/services/default.nix` |
| `nixos-modules/features/services/tailscale.nix` | Tailscale VPN configuration (opt-in) | `nixos-modules/features/services/default.nix` |
| `nixos-modules/features/services/auto-update.nix` | Automated system updates (opt-in) | `nixos-modules/features/services/default.nix` |
| `nixos-modules/features/services/openssh.nix` | SSH server configuration | `nixos-modules/features/services/default.nix` |
| `nixos-modules/features/services/trezord.nix` | Trezor hardware wallet daemon | `nixos-modules/features/services/default.nix` |
| `nixos-modules/features/services/cloudflared.nix` | Cloudflare tunnel daemon (opt-in) | `nixos-modules/features/services/default.nix` |
| `nixos-modules/features/storage/default.nix` | Storage features aggregator | `nixos-modules/features/default.nix` |
| `nixos-modules/features/storage/boot.nix` | GRUB/systemd-boot bootloader | `nixos-modules/features/storage/default.nix` |
| `nixos-modules/features/storage/swap.nix` | Swap configuration | `nixos-modules/features/storage/default.nix` |
| `nixos-modules/features/storage/btrfs.nix` | BTRFS maintenance: fstrim, auto-scrub | `nixos-modules/features/storage/default.nix` |
| `nixos-modules/features/storage/snapper.nix` | BTRFS snapshots | `nixos-modules/features/storage/default.nix` |
| `nixos-modules/features/theme/default.nix` | Theme features aggregator | `nixos-modules/features/default.nix` |
| `nixos-modules/features/theme/stylix.nix` | NixOS-specific Stylix targets: GRUB theme, cursor theme | `nixos-modules/features/theme/default.nix` |
### Role System

> **Note (historical):** The old `roles.*` flat modules (`nixos-modules/roles/`) were removed when the codebase migrated to the `features.*` namespace. The functionality is now split across `features/hardware/laptop.nix`, `features/security/desktop-hardening.nix`, `features/security/server-hardening.nix`, and `features/development/base.nix`.
---

## Layer 5: Home Configurations (4 files)

User-specific Home Manager configuration (auto-discovered by ez-configs).

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-configurations/vino/default.nix` | Composition root: wires import graph (home-modules + user.nix + host overrides), injects _module.args (palette, workspaces, cfgLib, stylixFonts, hostname) | ez-configs → `homeConfigurations."vino@bandit"` and `"vino@homelab"` |
| `home-configurations/vino/user.nix` | Implementation details: package lists, program settings, environment variables, HM options | `home-configurations/vino/default.nix` |
| `home-configurations/vino/hosts/bandit.nix` | Host-specific overrides: profile enablement (extras, ai), device names (battery, backlight, network), feature toggles | `home-configurations/vino/default.nix` (via hostModules) |
| `home-configurations/vino/hosts/homelab.nix` | Homelab host overrides (secondary host config) | `home-configurations/vino/default.nix` (via hostModules) |

---

## Layer 6: Home Modules (65 files)

User environment configuration: core infrastructure, and features (desktop, editor, shell, terminal, ai).

### Core Infrastructure (5 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/default.nix` | Aggregator: imports core + features + external inputs (nixvim, sops, stylix) | `home-configurations/vino/default.nix` |
| `home-modules/core/default.nix` | Core aggregator: imports all core HM modules | `home-modules/default.nix` |
| `home-modules/core/devices.nix` | Device option definitions: battery, backlight, networkInterface for status widgets | `home-modules/core/default.nix` |
| `home-modules/core/nixpkgs.nix` | XDG nixpkgs config: allowUnfree for CLI nix commands | `home-modules/core/default.nix` |
| `home-modules/core/package-managers.nix` | XDG compliance: npm, yarn, cargo, go, python paths to prevent home directory bloat | `home-modules/core/default.nix` |
| `home-modules/core/secrets.nix` | sops-nix HM secrets: github_mcp_pat, gpg_signing_key, cachix, exa_api_key, context7 | `home-modules/core/default.nix` |
| `home-modules/profiles.nix` | Package profile system: core, dev, desktop, extras, ai collections (opt-in) | `home-modules/default.nix` |

### Desktop (14 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/desktop/default.nix` | Aggregator: imports all desktop modules | `home-modules/default.nix` |
| `home-modules/features/desktop/services.nix` | Desktop session services: dunst notifications, picom compositor, flameshot, network/BT tray applets | `home-modules/features/desktop/default.nix` |
| `home-modules/features/desktop/firefox.nix` | Firefox browser: bookmarks, search engines, extensions, privacy settings | `home-modules/features/desktop/default.nix` |
| `home-modules/features/desktop/qutebrowser.nix` | Qutebrowser keyboard-driven browser | `home-modules/features/desktop/default.nix` |
| `home-modules/features/desktop/filezilla.nix` | FileZilla FTP client configuration | `home-modules/features/desktop/default.nix` |
| `home-modules/features/desktop/notepad.nix` | Quick notepad application configuration | `home-modules/features/desktop/default.nix` |

#### i3 Window Manager (5 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/desktop/i3/default.nix` | i3 aggregator: imports config, keybindings, autostart, workspace | `home-modules/features/desktop/default.nix` |
| `home-modules/features/desktop/i3/config.nix` | i3 core config: fonts, colors, gaps, borders, floating rules, window modes | `home-modules/features/desktop/i3/default.nix` |
| `home-modules/features/desktop/i3/keybindings.nix` | i3 keybindings: workspace switching, window management, layout commands | `home-modules/features/desktop/i3/default.nix` |
| `home-modules/features/desktop/i3/autostart.nix` | i3 startup commands: flameshot, autotiling, unclutter, copyq, blueman-applet, polkit-gnome, xss-lock, xautolock; starts tray.target (systemd user target) to launch polybar and tray services | `home-modules/features/desktop/i3/default.nix` |
| `home-modules/features/desktop/i3/workspace.nix` | i3 workspace assignments: Firefox → WS1, etc. | `home-modules/features/desktop/i3/default.nix` |

#### Polybar Status Bar (7 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/desktop/polybar/default.nix` | Polybar config: bar layout, fonts (Iosevka + Nerd Font icons), module placement | `home-modules/features/desktop/default.nix` |
| `home-modules/features/desktop/polybar/colors.nix` | Polybar color scheme: derived from Stylix palette (semantic colors) | `home-modules/features/desktop/polybar/default.nix` |
| `home-modules/features/desktop/polybar/modules.nix` | Polybar modules aggregator | `home-modules/features/desktop/polybar/default.nix` |
| `home-modules/features/desktop/polybar/core-modules.nix` | Core status modules: cpu, memory, time | `home-modules/features/desktop/polybar/default.nix` |
| `home-modules/features/desktop/polybar/system-modules.nix` | System modules: battery, backlight, volume | `home-modules/features/desktop/polybar/default.nix` |
| `home-modules/features/desktop/polybar/connectivity-modules.nix` | Connectivity modules: network, VPN, bluetooth | `home-modules/features/desktop/polybar/default.nix` |
| `home-modules/features/desktop/polybar/icons.nix` | Nerd Font icon constants for polybar modules | `home-modules/features/desktop/polybar/default.nix` |

#### Rofi Launcher (7 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/desktop/rofi/default.nix` | Rofi launcher: theme, dmenu integration, window switching | `home-modules/features/desktop/default.nix` |
| `home-modules/features/desktop/rofi/scripts.nix` | Rofi scripts: calculator, power menu, clipboard manager, file browser | `home-modules/features/desktop/rofi/default.nix` |
| `home-modules/features/desktop/rofi/config.rasi.nix` | Rofi base config in rasi format | `home-modules/features/desktop/rofi/default.nix` |
| `home-modules/features/desktop/rofi/theme.rasi.nix` | Rofi main theme | `home-modules/features/desktop/rofi/default.nix` |
| `home-modules/features/desktop/rofi/powermenu-theme.rasi.nix` | Rofi power menu theme | `home-modules/features/desktop/rofi/default.nix` |
| `home-modules/features/desktop/rofi/dropdown-theme.rasi.nix` | Rofi dropdown theme | `home-modules/features/desktop/rofi/default.nix` |
| `home-modules/features/desktop/rofi/audio-switcher-theme.rasi.nix` | Rofi audio switcher theme | `home-modules/features/desktop/rofi/default.nix` |

#### Screen Lock (1 file)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/desktop/lock/default.nix` | i3lock-color lockscreen: blur effect, ring colors from Stylix | `home-modules/features/desktop/default.nix` |

#### Vibe (2 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/desktop/vibe/default.nix` | Vibe desktop environment integration | `home-modules/features/desktop/default.nix` |
| `home-modules/features/desktop/vibe/devenv.nix` | Vibe devenv configuration | `home-modules/features/desktop/vibe/default.nix` |

### Editor (17 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/editor/default.nix` | Aggregator: imports nixvim | `home-modules/default.nix` |

#### Nixvim Neovim (16 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/editor/nixvim/default.nix` | Nixvim aggregator: imports options, autocmds, highlights, ui, plugins, keymaps, extra-config | `home-modules/features/editor/default.nix` |
| `home-modules/features/editor/nixvim/options.nix` | Neovim options: line numbers, indent, clipboard, search, split behavior | `home-modules/features/editor/nixvim/default.nix` |
| `home-modules/features/editor/nixvim/autocmds.nix` | Neovim autocommands: trim whitespace on save, highlight yank | `home-modules/features/editor/nixvim/default.nix` |
| `home-modules/features/editor/nixvim/highlights.nix` | Custom highlight groups for visual consistency | `home-modules/features/editor/nixvim/default.nix` |
| `home-modules/features/editor/nixvim/ui.nix` | UI plugins: mini.base16 theme, lualine statusline, indent-blankline, telescope | `home-modules/features/editor/nixvim/default.nix` |
| `home-modules/features/editor/nixvim/plugins.nix` | Core plugins: LSP, treesitter, copilot, oil file manager, harpoon, gitsigns | `home-modules/features/editor/nixvim/default.nix` |
| `home-modules/features/editor/nixvim/extra-config.nix` | Raw Lua config: LSP handlers, diagnostic configuration, custom functions | `home-modules/features/editor/nixvim/default.nix` |
| `home-modules/features/editor/nixvim/keymaps/default.nix` | Keymap aggregator: imports telescope, editor, copilot, navigation, terminal, lsp | `home-modules/features/editor/nixvim/default.nix` |
| `home-modules/features/editor/nixvim/keymaps/telescope.nix` | Telescope fuzzy finder keybindings: find files, grep, buffers, git | `home-modules/features/editor/nixvim/keymaps/default.nix` |
| `home-modules/features/editor/nixvim/keymaps/editor.nix` | General editor keybindings: save, quit, buffer navigation, splits | `home-modules/features/editor/nixvim/keymaps/default.nix` |
| `home-modules/features/editor/nixvim/keymaps/copilot.nix` | GitHub Copilot keybindings: accept suggestions, navigate | `home-modules/features/editor/nixvim/keymaps/default.nix` |
| `home-modules/features/editor/nixvim/keymaps/navigation.nix` | File navigation: oil file manager, harpoon quick marks | `home-modules/features/editor/nixvim/keymaps/default.nix` |
| `home-modules/features/editor/nixvim/keymaps/terminal.nix` | Terminal toggle keybindings: horizontal/vertical splits | `home-modules/features/editor/nixvim/keymaps/default.nix` |
| `home-modules/features/editor/nixvim/keymaps/lsp.nix` | LSP keybindings: goto definition, hover, rename, code actions | `home-modules/features/editor/nixvim/keymaps/default.nix` |

### Shell (6 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/shell/default.nix` | Aggregator: imports git, fish, starship, bat, eza | `home-modules/default.nix` |
| `home-modules/features/shell/git.nix` | Git config: delta diff viewer, aliases, commit signing settings | `home-modules/features/shell/default.nix` |
| `home-modules/features/shell/fish.nix` | Fish shell: atuin history, fzf, direnv, zoxide, abbreviations, environment variables | `home-modules/features/shell/default.nix` |
| `home-modules/features/shell/starship.nix` | Starship prompt: Nix-focused, git status, minimal design | `home-modules/features/shell/default.nix` |
| `home-modules/features/shell/bat.nix` | Bat syntax-highlighted pager configuration | `home-modules/features/shell/default.nix` |
| `home-modules/features/shell/eza.nix` | Eza modern ls replacement configuration | `home-modules/features/shell/default.nix` |

### Terminal (5 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/terminal/default.nix` | Aggregator: imports alacritty, tmux | `home-modules/default.nix` |
| `home-modules/features/terminal/alacritty.nix` | Alacritty terminal: font, cursor, scrollback (styled by Stylix) | `home-modules/features/terminal/default.nix` |
| `home-modules/features/terminal/tmux/default.nix` | Tmux aggregator: imports keybindings, plugins, statusbar | `home-modules/features/terminal/default.nix` |
| `home-modules/features/terminal/tmux/keybindings.nix` | Tmux keybindings: pane navigation, window management, copy mode | `home-modules/features/terminal/tmux/default.nix` |
| `home-modules/features/terminal/tmux/plugins.nix` | Tmux plugins: sensible defaults, yank, fzf integration | `home-modules/features/terminal/tmux/default.nix` |
| `home-modules/features/terminal/tmux/statusbar.nix` | Tmux status bar styling: colors, layout (styled by Stylix) | `home-modules/features/terminal/tmux/default.nix` |

### AI (2 files)

| File | Purpose | Imported By |
|------|---------|-------------|
| `home-modules/features/ai/default.nix` | AI features aggregator | `home-modules/default.nix` |
| `home-modules/features/ai/hermes.nix` | Hermes AI assistant configuration | `home-modules/features/ai/default.nix` |

---

## Layer 7: Shared Modules (4 files)

Cross-layer utilities used by both NixOS and Home Manager.

| File | Purpose | Imported By |
|------|---------|-------------|
| `shared-modules/stylix-common.nix` | Shared Stylix config: base16 theme (Gruvbox Dark Pale), fonts (Iosevka Term Nerd Font), wallpaper, icons | `nixos-modules/default.nix`, `home-modules/default.nix` |
| `shared-modules/palette.nix` | Semantic color system: derives bg, text, accent, warn, danger from base16 scheme | `home-modules/default.nix` |
| `shared-modules/workspaces.nix` | i3 workspace definitions: 10 workspaces with icons for polybar + i3 | `home-modules/default.nix` |
| `shared-modules/default.nix` | Shared modules aggregator: imports stylix-common, palette, workspaces | `nixos-modules/default.nix`, `home-modules/default.nix` |

---

## Statistics

- **Total .nix files:** 128
- **Average file depth:** 3.2 levels
- **Deepest nesting:** 5 levels (`home-modules/features/editor/nixvim/keymaps/*.nix`)
- **Aggregator files:** 22 (default.nix files that import collections)
- **External inputs:** 15 (nixpkgs, home-manager, stylix, sops-nix, nixvim, etc.)

### Files per Layer

| Layer | File Count | Purpose |
|-------|------------|---------|
| Flake Root | 6 | Entry point and foundational utilities |
| Flake Modules | 8 | Development infrastructure |
| NixOS Configurations | 5 | Host-specific system settings |
| NixOS Modules | 36 | Reusable system modules (core + features) |
| Home Configurations | 4 | User-specific entry points |
| Home Modules | 65 | User environment (largest layer) |
| Shared Modules | 4 | Cross-layer utilities |

### Deepest Nesting by Category

- **Home Modules (Desktop):** 4 levels deep (e.g., `home-modules/features/desktop/i3/keybindings.nix`)
- **Home Modules (Editor):** 5 levels deep (e.g., `home-modules/features/editor/nixvim/keymaps/lsp.nix`)
- **Home Modules (Terminal):** 4 levels deep (e.g., `home-modules/features/terminal/tmux/plugins.nix`)

### Role Distribution

- **System-level feature categories:** 7 (desktop, development, hardware, security, services, storage, theme)
- **User-level profiles:** 5 (core, dev, desktop, extras, ai)

---

## Related Documentation

- [Architecture Overview](./README.md) — High-level system design principles
- [Patterns](./patterns.md) — Design conventions and anti-patterns
- [Refactor Contract](./refactor-contract.md) — Layer ownership and migration guardrails

---

**Last Updated:** 2026-05-14  
**Maintained by:** vino  
**Repository:** `/home/vino/src/nixos-config`
