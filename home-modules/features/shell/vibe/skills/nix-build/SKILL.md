---
name: nix-build
description: Build and validate Nix expressions, fix evaluation errors
license: MIT
user-invocable: true
allowed-tools:
  - read_file
  - grep
  - bash
---

Build a NixOS/home-manager configuration and fix any errors.

## Steps
1. Run `nix flake check` to validate the flake
2. Run `nix build .#nixosConfigurations.bandit.config.system.build.toplevel --no-link`
3. Parse error output and identify the failing Nix expression
4. Read the relevant files and understand the error
5. Apply minimal fix, re-run build to confirm
6. Report what was fixed and why
