# nixos-config

Personal NixOS flake for a Framework 13 AMD laptop (`bandit`) with Home Manager (`vino`). Layers i3 on top of XFCE services, themed via Stylix (Gruvbox dark), with a Nixvim-based editor.

## Layout

```
flake.nix                    # flake-parts + ez-configs orchestration
nixos-configurations/bandit/ # host entrypoint + hardware-configuration.nix
home-configurations/vino/    # HM profile + hosts/<name>.nix overrides
nixos-modules/core/          # always-on system config (nix, users, networking, fonts)
nixos-modules/features/      # opt-in NixOS features (desktop, hardware, security, services, storage, theme)
home-modules/core/           # always-on HM config (devices, nixpkgs, package-managers, secrets)
home-modules/features/       # opt-in HM features (shell, editor, terminal, desktop, ai)
shared-modules/              # imported by both layers (palette, workspaces, stylix-common)
overlays/                    # custom package builds and version pins (available as pkgs.<name>)
lib/                         # pure helper functions (cfgLib)
secrets/                     # sops-encrypted secrets (see secrets/README.md)
flake-modules/               # perSystem devshells, apps, checks, packages
```

## Commands

```bash
just qa           # format + lint + flake check — run before every commit
just fmt          # format Nix files (nixfmt-rfc-style)
just rebuild      # NixOS switch via nh
just home-switch  # Home Manager switch via nh
just rebuild-test # dry-run NixOS build
just update       # update flake.lock
just agents       # enter AI tools devshell
just nix-debug    # enter Nix inspection devshell
just services     # dev services TUI (PostgreSQL + Redis)
```

## Adding Config

| What | Where |
|------|-------|
| System packages | `nixos-modules/core/packages.nix` |
| User packages | `home-configurations/vino/user.nix` → `home.packages` |
| New NixOS feature | `nixos-modules/features/<category>/<name>.nix` + aggregator `default.nix` |
| New HM feature | `home-modules/features/<category>/<name>.nix` + aggregator `default.nix` |
| Enable a feature | `nixos-configurations/bandit/default.nix` → `features.<category>.<name>.enable = true` |
| Workspaces | `shared-modules/workspaces.nix` |
| Custom packages | `overlays/` or `flake-modules/packages.nix` |
| Secrets | `secrets/README.md` |

Feature module pattern:
```nix
options.features.<category>.<name>.enable = lib.mkEnableOption "...";
config = lib.mkIf cfg.enable { ... };
```

## How ez-configs Works

`nixos-modules/default.nix` and `home-modules/default.nix` are auto-imported into every host/user by ez-configs — no manual `imports` needed. Add new modules to the relevant aggregator `default.nix`.

## Home Manager `_module.args`

Available in every HM module (injected by `home-configurations/vino/default.nix`):

| Arg | Use |
|-----|-----|
| `palette.*` | Semantic colors — prefer this (`bg`, `text`, `accent`, `warn`, `danger`, …) |
| `c.baseXX` | Raw base16 fallback when no semantic alias exists |
| `cfgLib` | Helper functions from `lib/` (polybar icons, workspace bindings, etc.) |
| `workspaces` | Shared i3/polybar workspace list |
| `stylixFonts` | Active Stylix font names |
| `hostname` | Current host name |

## Secrets

sops-nix + Age. Keys at `~/.config/sops/age/keys.txt` (user) and `/var/lib/sops-nix/key.txt` (host). See `secrets/README.md` for the full workflow. Never edit `secrets/*.yaml` directly.

## Notes

- `homelab` host is a stub — do not build (placeholder UUIDs in hardware config).
- Polybar FA6 icons must use `cfgLib.mkPolybarIcon <codepoint>` — editors strip PUA Unicode.
- Polybar color refs use `\${colors.X}` syntax (escaped for Nix interpolation).
- XFCE is session-manager only (`noDesktop = true`, `enableXfwm = false`); i3 handles windows.
- Bluetooth defaults to off — enable via `features.hardware.laptop.bluetooth.enable = true`.
- Hibernate/suspend depend on the swap device offset in `nixos-configurations/bandit/default.nix`.
