# Hosts

Each host has its own entrypoint under `nixos/hosts/<hostname>/default.nix`.

To add a new host:
1. Create `nixos/hosts/<name>/default.nix`.
2. Import `../../configuration.nix` and your `hardware-configuration.nix`.
3. Add any host-specific overrides there.

Roles are opt-in per host (desktop/laptop/server). For example:
- Laptop: `roles.desktop = true; roles.laptop = true;`
- Server: `roles.desktop = false; roles.server = true;`
