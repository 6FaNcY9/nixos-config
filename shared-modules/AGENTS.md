# AGENTS.md — shared-modules/

Modules imported by **both** `nixos-modules/default.nix` and `home-modules/default.nix`. Anything here lands in both evaluation contexts — keep it option-only / declaration-only.

## Files
- `palette.nix` — declares `options.theme.colors` (raw base16 with Gruvbox-pale fallback) and `options.theme.palette` (semantic submodule). Fallback fires when Stylix hasn't populated `config.lib.stylix.colors.withHashtag`.
- `stylix-common.nix` — base Stylix wiring shared between sides.
- `workspaces.nix` — declares `options.workspaces` consumed by i3 + polybar.
- `default.nix` — directory marker / re-exporter.

## Dual Color Export
`palette.nix` only declares options. The **values** reach modules through `_module.args` at the composition roots:
- HM: `home-configurations/vino/default.nix:40-42` injects `palette = config.theme.palette` and `c = config.theme.colors`.
- NixOS: same shape via `nixos-modules/default.nix` chain.

Consumer rule lives in root `AGENTS.md`: prefer `palette.*`, fall to `c.baseXX` only when no semantic name fits.

## When Adding a Shared Module
1. New `.nix` file here.
2. Add to `imports` in **both** `nixos-modules/default.nix` AND `home-modules/default.nix`.
3. If it introduces a new `_module.args` value, inject it at `home-configurations/vino/default.nix` (HM side) and `nixos-modules/default.nix` (NixOS side).
