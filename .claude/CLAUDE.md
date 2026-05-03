# nixos-config — Claude Code Context

## Architecture
- flake-parts + ez-configs auto-discovers hosts under `nixos-configurations/`
- Home Manager users auto-discovered under `home-configurations/`
- NixOS modules: `nixos-modules/core/` (always-on) + `nixos-modules/features/` (opt-in)
- HM modules: `home-modules/core/` (always-on) + `home-modules/features/` (opt-in)
- Shared: `shared-modules/` (stylix, palette, workspaces — imported by both layers)

## Active hosts
- `bandit` — Framework 13 AMD, DEPLOYED. Only host to build/test against.
- `homelab` — Headless server, STUB (placeholder UUIDs). DO NOT build.

## Key conventions
- Feature modules use `features.<category>.<name>.enable` — the ONLY option namespace
- Old `roles.*` system is GONE — do not reference it
- Colors: `palette.*` (semantic) preferred over `c.baseXX` (raw base16)
- Theme: Gruvbox Dark Pale via Stylix
- Shell: fish everywhere — use fish syntax, not bash patterns
- Formatter: `nix fmt` (nixfmt-rfc-style) — run before committing
- Task runner: `just` — see `justfile` for all recipes

## Critical helpers in `lib/default.nix`
- `mkWorkspaceBindings` — i3 keybindings from workspace list
- `mkPolybarTwoTone` / `mkPolybarTwoToneState` — polybar module style
- `mkPolybarIcon` — FA6 glyph from codepoint (requires `pkgs`)
- `mkBtrfsOpts` — BTRFS mount options for SSD
- `mkSecretValidation` — sops-nix pre-build assertions

## Secrets
- All in `secrets/*.yaml` — sops-encrypted, NEVER edit directly
- NixOS system secrets: `features.security.secrets.enable = true`
- HM secrets: `home-modules/core/secrets.nix` (pathExists-gated per secret)
- Age keys: user (`~/.config/sops/age/keys.txt`) + host (`/var/lib/sops-nix/key.txt`)

## Never do
- `rm -rf` anything
- Edit `secrets/*.yaml` directly
- Push to `main` without QA passing
- Run `nixos-rebuild switch` without explicit approval
- Build `homelab` (placeholder UUIDs will fail)

## QA workflow
```bash
just qa          # format + lint + flake check
just rebuild-test  # dry-run NixOS build for bandit
```
