# Copilot Instructions for nixos-config

Personal NixOS flake for a Framework 13 AMD laptop (`bandit`) with Home Manager user `vino`. The system uses i3 on top of XFCE services, themed via Stylix (Gruvbox dark), and ships a Nixvim-based editor.

---

## Repository Layout

```
flake.nix                       # Entry point: flake-parts + ez-configs wiring
flake-modules/                  # perSystem modules: devshells, apps, checks, treefmt, pre-commit
nixos-configurations/
  bandit/default.nix            # Host-specific NixOS config (features, storage, hardware, boot)
  bandit/hardware-configuration.nix
home-configurations/
  vino/default.nix              # User HM config: Stylix targets, git identity, _module.args injection
  vino/hosts/bandit.nix         # Host-specific HM overrides (features.* enable flags)
nixos-modules/
  core/                         # Always-imported: nix, users, networking, programs, packages, fonts
  features/                     # Opt-in per host: services, storage, desktop, hardware, security, theme, development
home-modules/
  core/                         # Always-imported: devices, nixpkgs, package-managers, secrets
  features/                     # Opt-in per user/host: shell, editor, terminal, desktop, ai
  profiles.nix                  # Package bundles toggled via profiles.{core,dev,desktop,extras,ai}
shared-modules/
  stylix-common.nix             # Stylix base16 scheme, wallpaper, fonts (used by both NixOS and HM)
  palette.nix                   # Semantic color aliases (accent, bg, text, warn, danger, …)
  workspaces.nix                # Shared i3 workspace list
overlays/                       # Nixpkgs overlays (custom package builds, version pins)
lib/default.nix                 # Pure helpers: mkWorkspaceName, mkSecretValidation, mkBtrfsOpts, mkPolybarTwoTone, …
secrets/                        # sops-encrypted YAML files (never plaintext)
docs/                           # Architecture docs, knowledge base, guides
justfile                        # Task runner (just fmt, just rebuild, just qa, …)
```

---

## Core Technologies

| Technology | Purpose |
|---|---|
| **flake-parts** | Composable flake structure (`mkFlake`, perSystem modules) |
| **ez-configs** | Auto-discovers `nixos-configurations/` and `home-configurations/` — no manual host wiring needed |
| **Home Manager** | User-level configuration (programs, dotfiles, packages) |
| **Stylix** | System-wide theming from a single base16 scheme (Gruvbox dark) |
| **sops-nix** | Encrypted secrets in Git, decrypted at activation |
| **nixvim** | Neovim configured entirely in Nix (HM module) |
| **treefmt + nixfmt-rfc-style** | Formatter — run `nix fmt` |
| **statix / deadnix** | Nix linter / dead-code scanner |

---

## How Auto-Discovery Works (ez-configs)

- `nixos-modules/default.nix` is **automatically imported** into every host — do **not** re-import it from host configs.
- `home-modules/default.nix` is **automatically imported** for every user.
- Host configs only need host-specific imports: `nixos-hardware` module, `hardware-configuration.nix`, `nixos-modules/home-manager.nix`.
- Host–user linkage: `ezConfigs.nixos.hosts.bandit.userHomeModules = [ "vino" ]` in `flake.nix`.

---

## Making Changes

### Add a system package
Edit `nixos-modules/core/packages.nix` → `environment.systemPackages`.

### Add a user package
Edit `home-configurations/vino/default.nix` → `home.packages`, or add it to a profile in `home-modules/profiles.nix` and toggle with `profiles.<name> = true`.

### Enable / disable a NixOS feature
Set `features.<category>.<name>.enable = true/false` in `nixos-configurations/bandit/default.nix`.

### Enable / disable a Home Manager feature
Set `features.<category>.<name>.enable = true/false` in `home-configurations/vino/hosts/bandit.nix`.

### Add a new NixOS feature module
1. Create `nixos-modules/features/<category>/<name>.nix` using the template below.
2. Import it in `nixos-modules/features/<category>/default.nix`.
3. Enable it in the host config.

### Add a new Home Manager feature module
1. Create `home-modules/features/<category>/<name>.nix` using the template below.
2. Import it in `home-modules/features/<category>/default.nix`.
3. Enable it in `home-configurations/vino/hosts/bandit.nix`.

### Feature module template (NixOS or HM)
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.features.<category>.<name>;
in
{
  options.features.<category>.<name> = {
    enable = lib.mkEnableOption "<description>";
  };

  config = lib.mkIf cfg.enable {
    # Configuration here
  };
}
```

---

## Color / Theming System

All new UI config should use **semantic palette names**, not raw base16 values:

```nix
# GOOD — module receives palette via _module.args
{ palette, ... }:
{ colors.focused.background = palette.accent; }

# BAD — brittle, breaks on theme change
{ colors.focused.background = "#b8bb26"; }
```

Semantic palette names: `bg`, `bgAlt`, `text`, `cream`, `accent`, `accent2`, `warn`, `danger`, `muted`, `orange`, `aqua`, `purple`.

Raw base16 (`c.base00`–`c.base0F`) is available as an escape hatch for hues without a semantic alias.

Both `palette` and `c` are injected via `_module.args` in `home-configurations/vino/default.nix` and are available as function arguments in any home module.

---

## Shared Module Arguments

Arguments available in **every Home Manager module** (via `_module.args`):

| Arg | Type | Description |
|---|---|---|
| `palette` | AttrSet | Semantic color names |
| `c` | AttrSet | Raw base16 colors (`c.base00`–`c.base0F`) |
| `stylixFonts` | AttrSet | Active Stylix font names (`.sansSerif.name`, `.monospace.name`) |
| `workspaces` | List | Shared i3 workspace definitions |
| `hostname` | String | Current host name |
| `cfgLib` | AttrSet | Pure helper functions from `lib/default.nix` |

Arguments available in **every NixOS and HM module** (via `ezConfigs.globalArgs`):

| Arg | Type | Description |
|---|---|---|
| `inputs` | AttrSet | All flake inputs |
| `username` | String | Auto-derived from `home-configurations/` directory |
| `repoRoot` | String | Absolute runtime path to the repo (`/home/vino/src/nixos-config`) |
| `nixpkgsConfig` | AttrSet | Shared nixpkgs config (`allowUnfree = true`, `allowAliases = false`) |

---

## Secrets (sops-nix)

- All secrets live in `secrets/*.yaml`, encrypted with `sops`.
- **Never commit plaintext** in `secrets/` — pre-commit hooks enforce this.
- Reference secrets via `config.sops.secrets.<name>.path` at runtime.
- Use `cfgLib.mkSecretValidation` to validate secret files at eval time (fail fast).
- Key configuration is in `.sops.yaml` (age + GPG keys).
- Workflow: `sops secrets/my-secret.yaml` to create/edit an encrypted file.

---

## Formatting, Linting & Validation

```bash
nix fmt                    # Format all Nix files (nixfmt-rfc-style)
nix flake check            # Run all checks including pre-commit hooks
statix check .             # Nix anti-pattern linter
deadnix -f .               # Dead code scan
nix run .#qa               # Format + lint + flake check combined
```

Pre-commit hooks (run automatically on commit):
- `treefmt` (nixfmt), `statix`, `deadnix`, `shellcheck`, `shfmt`, `typos`
- `detect-unencrypted-secrets`, `detect-secrets`, `check-large-files`

**IMPORTANT**: The Nix build environment is not available in the cloud agent (Nix is not installed). Format and lint checks run in CI (`check.yml`). After making changes, ensure files are formatted with `nixfmt-rfc-style` style (2-space indented, RFC 166 style).

---

## CI Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `check.yml` | push/PR to `main`, `claude/*` | Format check (`nix fmt --ci`) + `nix flake check` |
| `cachix.yml` | push to `main` | Pushes build outputs to Cachix (`vino-nixos-config`) |
| `update-flake.yml` | schedule | Auto-updates flake inputs |

---

## Build & Deploy (on the real machine)

```bash
# System rebuild
sudo nixos-rebuild switch --flake .#bandit
nh os switch -H bandit       # Same, using nh (recommended)

# Home Manager rebuild
home-manager switch --flake .#vino@bandit
nh home switch -c vino@bandit

# Test without switching
sudo nixos-rebuild test --flake .#bandit

# Convenience apps
nix run .#update             # Update all flake inputs
nix run .#qa                 # Format + lint + check
nix run .#clean              # Remove result symlinks
```

---

## Key Conventions

1. **Feature modules are opt-in**: All `features.*` options default to `false`; enable explicitly per host.
2. **Module aggregators**: Each `default.nix` is an aggregator — add new modules by importing them there, not by touching host configs.
3. **Prefer `palette.*` over `c.baseXX`** for colors in new code.
4. **Use `lib.mkIf cfg.enable { ... }`** — not `lib.optionalAttrs` — for config guarded by feature flags (lazy evaluation).
5. **Use `lib.mkForce`** only when overriding Stylix-set color options (Stylix uses priority 1000; `mkForce` is priority 50).
6. **Hardware config**: Do not edit `hardware-configuration.nix` manually; re-generate with `nixos-generate-config`.
7. **Secrets validation**: Always use `cfgLib.mkSecretValidation` when referencing secret files so build fails at eval time if files are missing or unencrypted.
8. **`inherit` shorthand**: Prefer `inherit (cfg.foo) bar` over `bar = cfg.foo.bar`.

---

## Known Issues & Workarounds

### GPG commit signing fails in cloud agent / SSH environments

**Symptom**: `gpg: signing failed: Timeout` when committing.

**Cause**: GPG requires a TTY for pinentry; cloud agent runs headless.

**Workaround** (already applied in local `.git/config`):
```bash
git config --local commit.gpgsign false
```
Commits from the agent will be unsigned. This is expected behavior — the local git config overrides the global HM-managed setting.

### `nix` is not available in the cloud agent environment

The cloud agent operates on a standard Ubuntu runner **without Nix installed**. You can:
- Read, edit, and create `.nix` files directly.
- Validate formatting visually using `nixfmt-rfc-style` conventions (2-space indent, no trailing semicolons on closing braces).
- CI will run `nix fmt --ci` and `nix flake check` on the PR.

### `repoRoot` is hardcoded to `/home/vino/src/nixos-config`

This is intentional — NixOS systemd units need the literal runtime path. Override per-host with `environment.variables.NIXOS_CONFIG_ROOT = "/custom/path"` if needed.

### `boot.initrd.systemd.enable = false` on `bandit`

Scripted initrd is required for correct BTRFS subvolume mounting on this host. Do not change this without re-testing hibernation and boot. Re-evaluate when upgrading past NixOS 26.11 (scripted initrd scheduled for removal).

---

## Development Shells

```bash
nix develop           # Default maintenance shell (statix, deadnix, treefmt, sops, age, …)
nix develop .#web     # Web development (Node, pnpm, PostgreSQL, Redis)
nix develop .#rust    # Rust toolchain
nix develop .#go      # Go toolchain
nix develop .#agents  # AI agent tools
nix develop .#nix-debug  # Nix debugging (nix-tree, nix-diff, …)
```

---

## Useful Exploration Commands (in devshell or on the real machine)

```bash
nix repl
> :lf .
> :t nixosConfigurations.bandit.config.features   # List all feature options

nixos-option features.desktop.i3-xfce.enable      # Inspect a specific option
nix flake show .                                    # List all flake outputs
```
