# nixos-config

Personal NixOS flake for a Framework 13 AMD laptop (`bandit`) with Home Manager (`vino`). The system layers i3 on top of XFCE services, themed via Stylix (Gruvbox dark), and ships a Nixvim-based editor setup.

## Layout
- `flake.nix` – pins NixOS 25.11, Home Manager, Stylix, nixvim; exports `nixosConfigurations.bandit`, `homeConfigurations."vino@bandit"`, formatter, and optional dev shells (maintenance, flask, pentest).
- `nixos/configuration.nix` – lightweight entrypoint that imports system modules.
- `nixos/hosts/bandit/` – host entrypoint and hardware profile (`hardware-configuration.nix`).
- `nixos/hosts/README.md` – quick guide for adding hosts.
- `home-manager/home.nix` – Home Manager profile: Stylix targets (gtk, i3, xfce, rofi, starship, nixvim, firefox), Firefox userChrome override, package set (CLIs, dev tools, desktop utilities), fish setup with abbreviations, Atuin/Zoxide/direnv/fzf, i3 config, XFCE session XML, and detailed nixvim plugin stack.
- `modules/shared/` – shared stylix palette/fonts + i3 workspace list.
- `modules/nixos/` – NixOS modules: `core.nix`, `storage.nix`, `services.nix`, `desktop.nix`, `stylix-nixos.nix`.
- `modules/home-manager/` – Home Manager modules (i3, polybar, nixvim, firefox, etc.).
- `overlays/` – overlays (includes `pkgs.unstable`).
- `pkgs/` – custom packages (exposed via `nix build .#pkgname`).
- `assets/firefox/` – userChrome.css + theme template.
- `lib/` – helper functions shared across modules.

## Conventions
- Host entrypoints live under `nixos/hosts/<name>/default.nix` and import `../../configuration.nix` + hardware config.
- Shared NixOS tweaks go in `modules/nixos/` or `modules/shared/`; Home Manager modules live under `modules/home-manager/`.
- Home Manager modules should use `_module.args` from `home-manager/home.nix` for colors/fonts (`c`, `palette`, `stylixFonts`).
- Avoid editing `hardware-configuration.nix` unless re-generated.
- Run `nix fmt` (alejandra) after changes.

## Editing Guide
Where to add new config:
- System packages: `modules/nixos/core.nix` → `environment.systemPackages`
- System services: `modules/nixos/services.nix`
- Desktop/X11/i3/XFCE: `modules/nixos/desktop.nix`
- Boot/storage/swap: `modules/nixos/storage.nix`
- Theme (system): `modules/nixos/stylix-nixos.nix` + `modules/shared/stylix-common.nix`
- User packages: `home-manager/home.nix` → `home.packages`
- User programs: `home-manager/home.nix` → `programs = { ... }`
- User modules: `modules/home-manager/<name>.nix` (add to `modules/home-manager/default.nix`)
- Shared helpers: `lib/default.nix`
- Workspaces list: `modules/shared/workspaces.nix`
- Overlays: `overlays/default.nix`
- Custom packages: `pkgs/default.nix`

How imports work:
- `modules/nixos/default.nix` and `modules/home-manager/default.nix` are module aggregators that set `imports = [ ... ]`.
- `home-manager/home.nix` imports `modules/home-manager/default.nix`.
- `nixos/configuration.nix` imports `modules/nixos/default.nix` + shared Stylix.

Home Manager shared args:
- `home-manager/home.nix` injects `_module.args`: `c`, `palette`, `stylixFonts`, `i3Pkg`, `workspaces`.
- Use these in HM modules for consistent theming.

Fish plugin src shorthand:
- `inherit (fifc) src` == `src = fifc.src` (pulls the plugin source from `pkgs.fishPlugins.fifc`).

Tooling:
- `treefmt` runs Alejandra for Nix formatting (see `.treefmt.toml`).
- `statix` lints Nix files (see `statix.toml`).
- `deadnix` finds unused bindings.
- Pre-commit hooks run via `nix flake check`.
- `nh` provides a higher-level CLI for `nixos-rebuild` and Home Manager operations.
- `nix-output-monitor` (`nom`) prettifies build output for long Nix operations.
- `nvd` compares system closures after rebuilds.

## Secrets (sops-nix)
- Config lives in `modules/nixos/secrets.nix` and `modules/home-manager/secrets.nix`.
- Template config: `.sops.yaml` (replace the placeholder age key).
- Secrets live under `secrets/` and should be encrypted with `sops`.
- See `secrets/README.md` for the exact workflow.

## Usage
- System switch (classic): `sudo nixos-rebuild switch --flake .#bandit`
- System switch (nh): `nh os switch . -H bandit`
- Home-only switch (classic): `home-manager switch --flake .#vino@bandit`
- Home-only switch (nh): `nh home switch . -c vino@bandit`
- Convenience apps: `nix run .#rebuild`, `nix run .#home`, `nix run .#update`, `nix run .#fmt`, `nix run .#check`, `nix run .#clean`, `nix run .#qa`, `nix run .#commit`
- Formatter: `nix fmt` (uses `alejandra`).
- Dev shells: `nix develop` (maintenance), `nix develop .#flask`, `nix develop .#pentest`

## Outputs
- List flake outputs: `nix flake show .`
- Reusable module exports: `nixosModules`, `homeModules`
- Apps: `rebuild`, `home`, `update`, `fmt`, `check`, `clean`, `qa`, `commit`

## Maintenance
- Enter maintenance shell: `nix develop` (default) or `nix develop .#maintenance`
- Format: `treefmt` (runs alejandra for .nix)
- Lint: `statix check .`
- Dead code scan: `deadnix -f .`
- Flake checks: `nix flake check` (includes pre-commit hooks)

## Automation
- Daily systemd timer `nixos-config-update` runs `nix flake update` and `nixos-rebuild switch` for `bandit`.

## Updates (Optional)
- Update all inputs: `nix flake update`
- Update one input: `nix flake lock --update-input nixpkgs`

Notes
- `allowUnfree = true` is enabled for packages like VS Code.
- Stylix auto-enables Gruvbox; Home Manager targets follow system theme (see `modules/nixos/stylix-nixos.nix`).
- `programs.i3blocks` is currently disabled in `modules/home-manager/i3blocks.nix`.
- Hibernate/suspend rely on the swap device/offset in `nixos/configuration.nix`—keep in sync if storage changes.

## Cheatsheet
- System rebuild: `sudo nixos-rebuild switch --flake .#bandit`
- Test rebuild: `sudo nixos-rebuild test --flake .#bandit`
- Home switch: `home-manager switch --flake .#vino@bandit`
- NH rebuild: `nh os switch . -H bandit`
- NH home: `nh home switch . -c vino@bandit`
- Flake check: `nix flake check`
- Format: `treefmt` or `nix run .#fmt`
- Update inputs: `nix flake update`
- Clean artifacts: `nix run .#clean`
- Diff current vs booted system: `nvd diff /run/booted-system /run/current-system`
