# AGENTS.md — flake-modules/

flake-parts perSystem pieces. All imported via `flake-modules/default.nix`.

## Files
| File | Provides |
|---|---|
| `_common.nix` | Shared helpers + package sets used by other modules |
| `apps.nix` | `nix run .#<name>` entries |
| `checks.nix` | NixOS + Home Manager build checks for `nix flake check` |
| `devshells.nix` | `nix develop .#<name>` |
| `packages.nix` | Custom packages + scripts (from `scripts/`) |
| `pre-commit.nix` | git-hooks.nix wiring; statix + deadnix toggled here (`:34-35`) |
| `treefmt.nix` | `nix fmt` formatter config; nixfmt-rfc-style (`:13-24`) |
| `scripts/` | Plain shell/nix scripts surfaced by `packages.nix` |

## Conventions
- `just qa` is the gate. Treats warnings as errors. Validate locally before commit.
- `statix.toml` (repo root) is statix's config; deadnix has no config file.
- `pre-commit.nix:156` comment intentionally keeps hooks **non-blocking** on commit — CI / `just qa` is the real gate.
- New flake-level concern → new file here + add to `default.nix` `imports`.
- Do not move host/user configurations into this tree; that lives under `nixos-configurations/` and `home-configurations/` (ez-configs handles discovery).
