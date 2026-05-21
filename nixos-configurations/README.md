# Hosts

Each host has its own entrypoint under `nixos-configurations/<hostname>/default.nix`.

To add a new host:
1. Create `nixos-configurations/<name>/default.nix` and the `hardware-configuration.nix` for that machine.
2. Add host-specific overrides there (feature toggles, swap/resume, etc.).
3. No need to import shared modules manually; ez-configs automatically imports `nixos-modules/default.nix` for every host.
4. If you want Home Manager on that host, add the user to `ezConfigs.nixos.hosts.<name>.userHomeModules` in `flake.nix`.

Features are opt-in per host using `features.<category>.<name>.enable`. For example:
- Laptop: `features.desktop.i3.enable = true; features.hardware.laptop.enable = true;`
- Server: `features.services.nginx.enable = true;`
