# AGENTS.md — home-configurations/vino/

Composition root for user `vino`. ez-configs discovers this directory.

## Files
- `default.nix` — composition root. Imports `../../home-modules/default.nix` + `./user.nix`; conditionally appends `./hosts/<hostname>.nix` if it exists. Injects `_module.args`.
- `user.nix` — user-wide feature toggles and identity-independent settings.
- `hosts/bandit.nix` — host-specific HM overrides for `bandit`.

## `_module.args` Injection (`default.nix:32-48`)
```nix
{
  palette    = config.theme.palette;
  workspaces = config.workspaces;
  c          = config.theme.colors;
  stylixFonts;       # with Sans/Monospace fallback
  hostname;          # osConfig.networking.hostName, falls back to passed hostname
  cfgLib     = import ../../lib { inherit lib pkgs; };
}
```
`pkgs` is forwarded into `cfgLib` here — that is what enables `mkPolybarIcon` to run Python on the HM side.

## Hostname Resolution
`hostName = if osConfig != null then osConfig.networking.hostName else hostname` — supports both nixos-rebuild (HM via NixOS module) and standalone `home-manager` invocations.

## Adding a Host
1. Create `hosts/<newhost>.nix` with host-specific overrides only.
2. Existing logic auto-detects via `builtins.pathExists hostModulePath`.
3. NixOS side needs a matching `nixos-configurations/<newhost>/` for ez-configs discovery.

## Hands-off Areas
- Do not move feature opt-ins into `default.nix` — those belong in `user.nix` or `hosts/<host>.nix`.
- Do not duplicate `_module.args` here for values already exposed by `shared-modules/`; extend `palette.nix` / `workspaces.nix` instead.
