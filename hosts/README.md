# Hosts

Each host has its own entrypoint under `hosts/<hostname>/default.nix`.

To add a new host:
1. Create `hosts/<name>/default.nix`.
2. Import `../profiles/base.nix` and your `hardware-configuration.nix`.
3. Add any host-specific overrides there.
