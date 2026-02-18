# Copilot Instructions for nixos-config

Personal NixOS flake for Framework 13 AMD laptop with i3-XFCE desktop, Home Manager, Stylix theming (Gruvbox dark), and Nixvim editor.

## Build, Test, and Lint Commands

### Formatting
```bash
# Format all Nix files (nixfmt-rfc-style)
nix fmt
# Or via just
just fmt
```

### Quality Assurance
```bash
# Run full QA suite: format, lint (statix), dead code scan (deadnix), pre-commit hooks, flake checks
nix run .#qa
# Or via just
just qa

# Individual tools
statix check .              # Lint Nix files
deadnix -f .                # Find unused bindings
nix flake check             # Run flake checks (includes pre-commit hooks)
```

### System Operations
```bash
# NixOS rebuild (classic)
sudo nixos-rebuild switch --flake .#bandit
sudo nixos-rebuild test --flake .#bandit    # Test without switching

# NixOS rebuild (nh - preferred)
nh os switch -H bandit
nh os test -H bandit

# Home Manager switch (classic)
home-manager switch --flake .#vino@bandit

# Home Manager switch (nh - preferred)
nh home switch -c vino@bandit

# Via justfile (auto-derives host/user from env vars)
just rebuild            # System rebuild
just rebuild-test       # Test system rebuild
just home-switch        # Home Manager rebuild
```

### Updates
```bash
# Update all inputs
nix flake update
# Or
nix run .#update

# Update single input
nix flake lock --update-input nixpkgs

# Compare system generations
nvd diff /run/booted-system /run/current-system
```

### Utilities
```bash
nix run .#clean         # Remove result symlinks
nix run .#commit        # Commit with pre-commit hooks
nix run .#sysinfo       # System diagnostics
nix-tree                # Visualize dependency tree
```

## Architecture

### Flake Structure
- **flake-parts + ez-configs**: Automatically wires `nixosConfigurations` and `homeConfigurations` from directory structure
- **ez-configs auto-imports**: `nixos-modules/default.nix` for all NixOS hosts, `home-modules/default.nix` for all Home Manager users (unless `importDefault = false`)
- **perSystem modules**: Dev shells, apps, services, checks defined in `flake-modules/`

### Module Organization
```
nixos-configurations/<host>/
  ├── default.nix              # Host entrypoint (imports hardware + host overrides)
  └── hardware-configuration.nix  # Don't edit (auto-generated)

nixos-modules/
  ├── default.nix              # Aggregator (auto-imported by ez-configs)
  ├── core.nix                 # System packages, users, boot
  ├── services.nix             # System services
  ├── storage.nix              # Boot, filesystem, swap, zram
  ├── desktop.nix              # X11, i3, XFCE, display manager
  ├── stylix-nixos.nix         # System-level theming
  ├── secrets.nix              # sops-nix integration
  └── roles/                   # Opt-in roles (desktop, laptop, server)
      ├── default.nix
      ├── desktop.nix
      ├── laptop.nix
      ├── server.nix
      └── ...

home-configurations/<user>/
  ├── default.nix              # User profile (packages, programs, modules)
  └── hosts/<host>.nix         # Host-specific HM overrides

home-modules/
  ├── default.nix              # Aggregator (auto-imported by ez-configs)
  ├── profiles.nix             # Package groups (core, dev, desktop, extras, ai)
  ├── devices.nix              # Device name config (battery, backlight, network)
  ├── desktop/                 # i3, polybar, rofi, etc.
  ├── editor/                  # Nixvim configuration
  ├── shell/                   # Fish, starship, etc.
  └── terminal/                # Kitty, alacritty, etc.

shared-modules/               # Used by both NixOS and HM
  ├── stylix-common.nix        # Stylix palette/fonts
  └── workspaces.nix           # i3 workspace definitions

flake-modules/                # perSystem configuration
  ├── apps.nix                 # nix run .#<app>
  ├── devshells.nix            # nix develop .#<shell>
  ├── packages.nix             # Custom packages
  ├── services.nix             # Process Compose services
  ├── checks.nix               # CI checks
  ├── pre-commit.nix           # Pre-commit hooks
  └── treefmt.nix              # Treefmt formatter config

overlays/                     # Nixpkgs overlays
  └── default.nix              # Provides pkgs.stable from nixpkgs-stable

lib/                          # Pure helper functions
  └── default.nix              # Workspace, color, profile helpers
```

### Roles System
Roles are **opt-in** per host via boolean flags:
- `roles.desktop = true;` → Enables GUI (X11, i3, XFCE)
- `roles.laptop = true;` → Enables laptop features (TLP, Bluetooth)
- `roles.server = true;` → Server base config (SSH hardening, fail2ban)
- `roles.development = true;` → Dev tools and services
- `desktop.variant = "i3-xfce";` → Desktop environment choice

Only enable roles where needed. Desktop is disabled by default on new hosts.

### Home Manager Integration
- **Shared args injection**: `home-configurations/vino/default.nix` injects `_module.args` for all HM modules:
  - `c` → Color helper functions
  - `palette` → Stylix color palette
  - `stylixFonts` → Font configuration
  - `i3Pkg` → i3 package
  - `workspaces` → Workspace definitions
- **Use these args** in HM modules for consistent theming without re-importing
- **Host overrides**: Place host-specific HM config in `home-configurations/vino/hosts/<host>.nix`

### Desktop Architecture
- **XFCE as session manager only**: `noDesktop = true`, `enableXfwm = false`
- **i3 handles window management**: XFCE provides services (thunar, panel-free setup)
- **Stylix auto-themes**: GTK, i3, rofi, starship, nixvim, Firefox via Gruvbox dark

## Key Conventions

### Where to Add New Configuration

#### System-Level
- **System packages**: `nixos-modules/core.nix` → `environment.systemPackages`
- **System services**: `nixos-modules/services.nix`
- **Boot/storage/swap**: `nixos-modules/storage.nix`
- **Desktop/X11**: `nixos-modules/desktop.nix`
- **Server config**: `nixos-modules/roles/server.nix` (SSH, fail2ban, hardening)
- **Theme (system)**: `nixos-modules/stylix-nixos.nix` + `shared-modules/stylix-common.nix`

#### User-Level (Home Manager)
- **User packages**: `home-configurations/vino/default.nix` → `home.packages`
- **Package groups**: Toggle via `profiles.*` flags in `home-configurations/vino/default.nix`:
  - `profiles.core` → CLI baseline
  - `profiles.dev` → Compilers, language toolchains
  - `profiles.desktop` → GUI apps + desktop utilities
  - `profiles.extras` → Nice-to-have tools (neofetch, chafa)
  - `profiles.ai` → AI CLI tools (Codex when available)
- **User programs**: `home-configurations/vino/default.nix` → `programs = { ... }`
- **User modules**: Create in `home-modules/<name>.nix`, add to `home-modules/default.nix` imports
- **Device names**: Override via `devices.*` in host-specific HM module (`home-configurations/vino/hosts/<host>.nix`)

#### Shared
- **Helper functions**: `lib/default.nix`
- **Workspaces**: `shared-modules/workspaces.nix`
- **Overlays**: `overlays/default.nix`
- **Custom packages**: `flake-modules/packages.nix` (exposed via flake outputs)

### Import Patterns
- **NixOS**: ez-configs auto-imports `nixos-modules/default.nix` for every host
- **Home Manager**: ez-configs auto-imports `home-modules/default.nix` for every user
- **Host entrypoints**: Import only hardware config + host overrides (base modules come via ez-configs)
- **Module aggregators**: `nixos-modules/default.nix` and `home-modules/default.nix` set `imports = [ ... ]`

### Naming Conventions
- **Hosts**: `nixos-configurations/<hostname>/default.nix`
- **Users**: `home-configurations/<username>/default.nix`
- **Host-specific HM config**: `home-configurations/<username>/hosts/<hostname>.nix`
- **Flake outputs**: `nixosConfigurations.<hostname>`, `homeConfigurations."<user>@<host>"`

### Formatting and Style
- **Formatter**: `nixfmt-rfc-style` (via treefmt)
- **Always run** `nix fmt` after changes
- **Linting**: statix (see `statix.toml` for config)
- **Pre-commit hooks**: Auto-run via `nix flake check` or `nix run .#commit`

### Secrets (sops-nix)
- **Location**: `secrets/` directory (encrypted with sops)
- **Config**: `nixos-modules/secrets.nix`, `home-modules/secrets.nix`
- **Template**: `.sops.yaml` (replace placeholder age key)
- **Never commit plaintext secrets**
- See `secrets/README.md` for workflow

### Environment Variables for Tooling
- **NIXOS_CONFIG_HOST**: Override target host (default: `hostname`)
- **NIXOS_CONFIG_USER**: Override target user (default: `$USER`)
- Used by justfile recipes for portability across forks

### Hardware Configuration
- **Don't edit** `hardware-configuration.nix` unless regenerating
- **Hibernate/suspend**: Keep swap device/offset in sync with `nixos-configurations/<host>/default.nix` if storage changes

### Fish Plugin Source Shorthand
```nix
# This pattern is used throughout home-modules/shell/fish.nix
inherit (fifc) src;  # Equivalent to: src = fifc.src;
# Pulls plugin source from pkgs.fishPlugins.fifc
```

### Home Manager Module Args Pattern
Instead of re-importing shared modules, use `_module.args`:
```nix
# In home-modules/<module>.nix
{ config, lib, pkgs, c, palette, stylixFonts, ... }:
# c, palette, stylixFonts are injected via home-configurations/vino/default.nix
```

## Development Shells

Enter with `nix develop .#<name>` or `just <name>`:

- **maintenance** (default): treefmt, statix, deadnix, pre-commit, nh, nom, nvd
- **web**: Node.js, pnpm, PostgreSQL tools
- **rust**: Rust toolchain (stable + nightly)
- **go**: Go toolchain
- **agents**: AI agent tools (Codex, OpenCode)
- **nix-debug**: Nix analysis tools (nix-tree, nix-diff, nix-output-monitor)

## Apps

Run with `nix run .#<name>`:

- **update**: Update flake inputs (`nix flake update`)
- **clean**: Remove result symlinks
- **qa**: Full QA suite (format + lint + checks)
- **commit**: Commit with pre-commit hooks
- **sysinfo**: System diagnostics
- **generate-age-key**: Generate sops-nix age key
- **cachix-push**: Push to Cachix
- **dev-services**: TUI for PostgreSQL + Redis (start with F7)
- **web-db**: Project-local PostgreSQL (data in `./data/pg1/`)

## Common Workflows

### Adding a New Host
1. Create `nixos-configurations/<hostname>/default.nix`
2. Generate hardware config: `nixos-generate-config --show-hardware-config > nixos-configurations/<hostname>/hardware-configuration.nix`
3. Import hardware config and set roles in `default.nix`
4. Create `home-configurations/vino/hosts/<hostname>.nix` for HM overrides
5. Test: `sudo nixos-rebuild test --flake .#<hostname>`

### Adding a New NixOS Module
1. Create `nixos-modules/<name>.nix`
2. Add to `nixos-modules/default.nix` imports
3. Module is now available to all hosts

### Adding a New Home Manager Module
1. Create `home-modules/<category>/<name>.nix`
2. Add to `home-modules/default.nix` imports
3. Module is now available to all users

### Updating a Single Package
```bash
# Update input
nix flake lock --update-input nixpkgs

# Test rebuild
nh os test -H bandit

# Switch if good
nh os switch -H bandit
```

### Debugging Build Issues
```bash
# Verbose build output
nom build .#nixosConfigurations.bandit.config.system.build.toplevel

# Dependency tree
nix-tree

# Compare closures
nvd diff /run/booted-system /run/current-system
```

### Working with Secrets
See `secrets/README.md` for the sops-nix workflow.

## Statix Lints
- Ignores: `nixos-configurations/**/hardware-configuration.nix` (see `statix.toml`)

## Automation
- **Weekly systemd timer**: `nixos-config-update` runs `nix flake update` + rebuild for `bandit` (AC power only)

## Notes
- `allowUnfree = true` is enabled (for VS Code, etc.)
- Polybar hides battery/backlight/power modules when no device configured
- Bluetooth only enabled when `roles.laptop = true`
- XFCE noDesktop mode: session manager only, i3 handles WM
- To suppress dirty-tree warnings in QA: use fish abbreviations `qa` / `gcommit` (pass `--option warn-dirty false`)
- `programs.i3blocks` currently disabled in `home-modules/i3blocks.nix`
- Use `pkgs.stable.<package>` to access nixpkgs-stable (via overlays)
