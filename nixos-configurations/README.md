# Hosts

Each host has its own entrypoint under `nixos-configurations/<hostname>/default.nix`.

To add a new host:
1. Create `nixos-configurations/<name>/default.nix` and the `hardware-configuration.nix` for that machine.
2. Add host-specific overrides there (roles, desktop variant, swap/resume, etc.).
3. No need to import shared modules manually; ez-configs automatically imports `nixos-modules/default.nix` for every host.
4. If you want Home Manager on that host, add the user to `ezConfigs.nixos.hosts.<name>.userHomeModules` in `flake.nix`.

Roles are opt-in per host (desktop/laptop/server). For example:
- Laptop: `roles.desktop = true; roles.laptop = true;`
- Server: `roles.desktop = false; roles.server = true;`
