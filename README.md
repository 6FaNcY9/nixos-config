# nixos-config

Personal NixOS flake for a Framework 13 AMD laptop (`bandit`) with Home Manager (`vino`). The system layers i3 on top of XFCE services, themed via Stylix (Gruvbox dark), and ships a Nixvim-based editor setup.

## Layout
- `flake.nix` – uses flake-parts + ez-configs to wire inputs and exports `nixosConfigurations.bandit`, `homeConfigurations."vino@bandit"`, formatter, and optional dev shells.
- `nixos-configurations/bandit/` – host entrypoint and hardware profile (`hardware-configuration.nix`).
- `nixos-configurations/README.md` – quick guide for adding hosts.
- `home-configurations/vino/default.nix` – Home Manager profile: Stylix targets (gtk, i3, xfce, rofi, starship, nixvim, firefox), Firefox userChrome override, package set (CLIs, dev tools, desktop utilities), fish setup with abbreviations, Atuin/Zoxide/direnv/fzf, i3 config, XFCE session XML, and detailed nixvim plugin stack.
- `home-configurations/vino/hosts/<name>.nix` – host-specific Home Manager overrides (profiles, device names, etc.).
- `shared-modules/` – shared stylix palette/fonts + i3 workspace list.
- `nixos-modules/` – NixOS modules organized as:
  - `core/` – Core system (always enabled): nix, users, networking, programs, packages, fonts
  - `features/` – Optional features (explicit enable): services, storage, desktop, hardware, security, theme, development
  - `profiles/` – Feature bundles (future use)
- `home-modules/` – Home Manager modules organized as:
  - `core/` – Always-on infrastructure: devices, nixpkgs, package managers, secrets
  - `features/` – Optional modules (explicit enable): shell, editor, terminal, desktop
  - `profiles.nix` – Package bundles (toggle with `profiles.*` flags)
- `overlays/` – overlays (includes `pkgs.stable` from nixpkgs-stable).
- `lib/` – helper functions shared across modules.

## Conventions
- Host entrypoints live under `nixos-configurations/<name>/default.nix` and import only hardware config + host overrides (ez-configs auto-imports `nixos-modules/default.nix`).
- Shared NixOS tweaks go in `nixos-modules/` or `shared-modules/`; Home Manager modules live under `home-modules/`.
- Home Manager modules should use `_module.args` from `home-configurations/vino/default.nix` for colors/fonts (`c`, `palette`, `stylixFonts`).
- Avoid editing `hardware-configuration.nix` unless re-generated.
- Run `nix fmt` (nixfmt-rfc-style) after changes.

## Host Matrix (intent)
| Host | Features | Desktop | Notes |
| --- | --- | --- | --- |
| bandit | desktop, laptop, dev, storage | i3-xfce | Framework 13 AMD laptop |
| server-<name> | server-hardening | (none) | Headless/server host example |
| droid-<name> | (nix-on-droid) | (none) | Termux/nix-on-droid host example |

## 🎯 Feature Modules

This configuration uses explicit feature modules for discoverability and clear dependencies.

**Discover features**:
```bash
nix repl
> :lf .
> :t config.features  # Shows all available features
```

**Enable features** in `nixos-configurations/<host>/default.nix`:
```nix
features = {
  desktop.i3-xfce.enable = true;
  hardware.laptop.enable = true;
  security.desktop-hardening.enable = true;
  storage.btrfs.enable = true;
};
```

See **[docs/FEATURE_MODULES.md](docs/FEATURE_MODULES.md)** for full guide.

## Editing Guide

Where to add new config:
- **System packages**: `nixos-modules/core/packages.nix` → `environment.systemPackages`
- **Desktop (i3/XFCE)**: `features.desktop.i3-xfce.*` in host config
- **Development tools**: `features.development.base.*` in host config
- **Laptop hardware**: `features.hardware.laptop.*` in host config
- **Server hardening**: `features.security.server-hardening.*` in host config
- **Desktop hardening**: `features.security.desktop-hardening.*` in host config
- **Boot/storage**: `features.storage.{boot,swap,btrfs,snapper}.*` in host config
- **Theme (system)**: `features.theme.stylix.*` + `shared-modules/stylix-common.nix`
- **Services**: `features.services.{tailscale,backup,monitoring,auto-update,openssh,trezord}.*`
- **User packages**: `home-configurations/vino/default.nix` → `home.packages`
- **Package groups**: `home-modules/profiles.nix` (toggle with `profiles.*` flags)
- **Device names**: `home-modules/core/devices.nix` (override via `devices.*` in host HM config)
- **User programs**: `home-configurations/vino/default.nix` → `programs = { ... }`
- **User features**: `home-modules/features/<category>/<name>.nix` (enable with `features.<category>.<name>.enable = true` in host HM config)
- **Shared helpers**: `lib/default.nix`
- **Workspaces list**: `shared-modules/workspaces.nix`
- **Overlays**: `overlays/default.nix`
- **Custom packages**: `flake-modules/packages.nix` (exposed via flake outputs)

How imports work (ez-configs):
- `nixos-modules/default.nix` and `home-modules/default.nix` are module aggregators that set `imports = [ ... ]`.
- ez-configs auto-imports `nixos-modules/default.nix` for every host (unless `importDefault = false`).
- ez-configs auto-imports `home-modules/default.nix` for every user (unless `importDefault = false`).
- `homeConfigurations` are generated per host when a user is listed under `ezConfigs.nixos.hosts.<host>.userHomeModules`.

Home Manager shared args:
- `home-configurations/vino/default.nix` injects `_module.args`: `c`, `palette`, `stylixFonts`, `i3Pkg`, `workspaces`.
- Package groups are defined in `home-modules/profiles.nix` and controlled via `profiles` booleans (see below).
- Use these in HM modules for consistent theming.

Fish plugin src shorthand:
- `inherit (fifc) src` == `src = fifc.src` (pulls the plugin source from `pkgs.fishPlugins.fifc`).

Tooling:
- `treefmt` runs nixfmt-rfc-style for Nix formatting (configured via treefmt-nix in `flake-modules/treefmt.nix`).
- `statix` lints Nix files (see `statix.toml`).
- `deadnix` finds unused bindings.
- Pre-commit hooks run via `nix flake check`.
- `nh` provides a higher-level CLI for `nixos-rebuild` and Home Manager operations.
- `nix-output-monitor` (`nom`) prettifies build output for long Nix operations.
- `nvd` compares system closures after rebuilds.
- `qa`/`commit` run pre-commit using the generated config from the Nix store (no local `.pre-commit-config.yaml` file needed).
- If you previously installed git hooks, use `nix run .#commit` (it runs pre-commit manually and commits with `--no-verify`). If you prefer plain `git commit`, reinstall hooks or run `pre-commit uninstall`.

## 📖 Documentation

- **[Feature Modules Guide](docs/FEATURE_MODULES.md)** - How to use and create features
- **[Development Services](docs/DEVELOPMENT_SERVICES.md)** - PostgreSQL, Redis, etc.
- **[Architecture](docs/architecture/)** - System design and components

## Secrets (sops-nix)
- Config lives in `features.security.secrets.*` and `home-modules/core/secrets.nix`.
- Template config: `.sops.yaml` (replace the placeholder age key).
- Secrets live under `secrets/` and should be encrypted with `sops`.
- See `secrets/README.md` for the exact workflow.

## Usage
- System switch (classic): `sudo nixos-rebuild switch --flake .#bandit`
- System switch (nh): `nh os switch -H bandit`
- Home-only switch (classic): `home-manager switch --flake .#vino@bandit`
- Home-only switch (nh): `nh home switch -c vino@bandit`
- Convenience apps: `nix run .#update`, `nix run .#clean`, `nix run .#qa`, `nix run .#commit`
- Formatter: `nix fmt` (uses `nixfmt-rfc-style`).
- Dev shells: `nix develop` (maintenance), `nix develop .#flask`, `nix develop .#pentest`

## Package Profiles
Toggle package groups in `home-configurations/vino/default.nix` (or a host-specific HM override) by setting:
- `profiles.core` (CLI baseline)
- `profiles.dev` (compilers, language toolchains)
- `profiles.desktop` (GUI apps + desktop utilities)
- `profiles.extras` (nice-to-have tools like `neofetch`/`chafa`)
- `profiles.ai` (Codex CLI when available)

## Outputs
- List flake outputs: `nix flake show .`
- Reusable module exports: `nixosModules`, `homeModules`
- Apps: `update`, `clean`, `qa`, `commit`

## Maintenance
- Enter maintenance shell: `nix develop` (default) or `nix develop .#maintenance`
- Format: `treefmt` (runs nixfmt-rfc-style for .nix)
- Lint: `statix check .`
- Dead code scan: `deadnix -f .`
- Flake checks: `nix flake check` (includes pre-commit hooks)

## Automation
- Weekly systemd timer `nixos-config-update` runs `nix flake update` and `nixos-rebuild switch` for `bandit` (AC power only).

## Updates (Optional)
- Update all inputs: `nix flake update`
- Update one input: `nix flake lock --update-input nixpkgs`

Notes
- `allowUnfree = true` is enabled for packages like VS Code.
- Stylix auto-enables Gruvbox; Home Manager targets follow system theme (see `nixos-modules/stylix-nixos.nix`).
- Hibernate/suspend rely on the swap device/offset in `nixos-configurations/<host>/default.nix`—keep in sync if storage changes.
- If you want to suppress the dirty-tree warning for QA/commit, use the fish abbreviations `qa` / `gcommit` (they pass `--option warn-dirty false`).
- Bluetooth is only enabled when `roles.laptop = true` (defaults to off on new hosts).
- XFCE is used as a session manager only (`noDesktop = true`, `enableXfwm = false`); i3 handles window management.
- Roles are opt-in per host; enable `roles.desktop`/`roles.laptop` only where needed.
- Polybar hides battery/backlight/power modules when no device is configured and shows IP instead.

## Cheatsheet
- System rebuild: `sudo nixos-rebuild switch --flake .#bandit`
- Test rebuild: `sudo nixos-rebuild test --flake .#bandit`
- Home switch: `home-manager switch --flake .#vino@bandit`
- NH rebuild: `nh os switch -H bandit`
- NH home: `nh home switch -c vino@bandit`
- Flake check: `nix flake check`
- Format: `treefmt`
- Update inputs: `nix flake update`
- Clean artifacts: `nix run .#clean`
- Diff current vs booted system: `nvd diff /run/booted-system /run/current-system`
