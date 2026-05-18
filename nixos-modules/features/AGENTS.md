# AGENTS.md — nixos-modules/features/

System-level opt-in features. Aggregator at `./default.nix` imports every category dir. Hosts enable via `features.<category>.<name>.enable = true`.

## Categories
| Dir | Scope |
|---|---|
| `desktop/` | X server, i3 system-side bits |
| `development/` | Language toolchains, build tools |
| `hardware/` | Framework 13 AMD, audio, GPU, peripherals |
| `security/` | sops, firewall, polkit, `secrets.nix` (system age key consumer) |
| `services/` | systemd services, daemons |
| `storage/` | BTRFS subvolumes (consumes `cfgLib.mkBtrfsOpts`), zram, mount points |
| `theme/` | System-level stylix wiring |

## Adding a Feature
1. Place file in matching category dir (or create one + wire into category's `default.nix`).
2. Follow the universal module pattern (`options.features.<category>.<name>.enable` + `config = lib.mkIf cfg.enable {...}`).
3. Enable per-host in `nixos-configurations/<host>/default.nix`.
4. Category dirs each have a local `default.nix` that imports siblings. New file → add to that local `default.nix`.

## Notes
- `nixos-modules/features/security/secrets.nix:34-67` defines system secrets `github_ssh_key`, `cloudflare_tunnel_token`. Line 45 comment forbids deriving host age key from SSH host key.
- HM is wired in via `../home-manager.nix`, not from here.
