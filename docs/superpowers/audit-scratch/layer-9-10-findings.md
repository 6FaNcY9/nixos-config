# Layer 9–10 Findings: Profiles + Secrets

## Layer 9: home-modules/profiles.nix

### Analysis

Profiles are a Home Manager module that exposes `options.profiles.<name>` boolean flags (using `cfgLib.mkProfile`) and maps each flag to a list of packages via `config.home.packages`. Five profiles exist: `core`, `dev`, `desktop`, `extras`, `ai`. `core`, `dev`, and `desktop` default to `true`; `extras` and `ai` default to `false`.

Activation is per-host: `home-configurations/vino/hosts/bandit.nix` overrides only `extras = true` and `ai = true`, relying on the defaults for the others. A second host can override any profile independently via its own `hosts/<hostname>.nix` file. A headless server would simply set `desktop = false` (and optionally `dev = false`) in its host override — the defaults would be suppressed cleanly.

There is no coupling to specific hardware names or NixOS options inside `profiles.nix` itself.

A second user would need their own `home-configurations/<user>/default.nix` that imports `home-modules/default.nix` (which includes `profiles.nix`). The module is fully reusable; no copying required.

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| `home-modules/profiles.nix` | `good-pattern` | `n/a` | Profile flags cleanly separate package sets; per-host activation via `hosts/<hostname>.nix` overrides works correctly for multi-host. | No change needed. |
| `home-modules/profiles.nix` | `good-pattern` | `n/a` | Defaults (`core=true`, `dev=true`, `desktop=true`) are reasonable for a desktop user and can be inverted per-host without touching the module. | No change needed. |
| `home-modules/profiles.nix` | `scaling-gap` | `minor` | `desktop` profile defaults to `true` globally. A headless server host must explicitly set `desktop = false` — no guard preventing GUI packages being installed silently if the host override is forgotten. | Document the `desktop = false` requirement for headless hosts; consider a NixOS-level assertion or derive the default from `features.desktop.*.enable`. |
| `home-modules/profiles.nix` | `structural-coupling` | `minor` | `desktopPkgs` list duplicates packages already declared individually in feature modules (e.g. `pkgs.alacritty`, `pkgs.rofi`, `pkgs.picom`, `pkgs.dunst`). The profile installs them unconditionally when `desktop = true`, regardless of whether the corresponding feature is enabled. | Either drive package installation from feature-module `enable` flags alone and remove the `desktopPkgs` list, or document that the profile is intentionally coarse-grained and the feature modules handle config. |
| `home-modules/profiles.nix` | `hardcoded-literal` | `minor` | `devPkgs` includes `pkgs.jetbrains.idea` (JetBrains Ultimate, requires paid license). This is a desktop-only, license-gated tool silently installed for every `dev = true` host. | Move `idea` to a dedicated `ide` profile or gate it behind `extras`/`ai`. |

## Layer 10: secrets/

### Analysis

Age keys are registered in `.sops.yaml` at the repo root. There are two age keys (one user-level, one host-level) plus one GPG key. The single `creation_rules` entry applies to all `secrets/*.yaml` files — there is no per-host or per-secret granularity.

The host age key (`&host`) is the auto-generated key at `/var/lib/sops-nix/key.txt` on `bandit`. There is no bandit-specific name in `.sops.yaml`; the anchor is simply `host`. Secret file paths in `secrets.nix` are generic (`secrets/github.yaml`) with no hostname in the path.

Enrolling a second host requires: (1) booting the new host and reading `/var/lib/sops-nix/key.txt` for its public key, (2) adding it to `.sops.yaml` under a new anchor, (3) adding it to the `creation_rules` group, and (4) running `sops updatekeys secrets/*.yaml` from a machine that already has access. Steps are documented in `secrets/README.md`.

All current secrets are user-scoped (GitHub SSH key, GPG signing key, API tokens) and shared across all hosts. There are no host-specific secrets yet, so the flat structure has not yet needed per-host routing.

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| `.sops.yaml` | `good-pattern` | `n/a` | Age key separation (user key vs. host key) allows independent key rotation. Auto-generated host key via `generateKey = true` means zero manual bootstrap for a new host until it needs to decrypt existing secrets. | No change needed. |
| `.sops.yaml` | `good-pattern` | `n/a` | GPG key provides backup decryption path independent of Age key availability. | No change needed. |
| `.sops.yaml` | `scaling-gap` | `moderate` | Single `creation_rules` entry encrypts every secret for every host key. As hosts multiply, each host can decrypt every secret even if it only needs a subset. Acceptable today with one host; becomes an overprivileged flat structure at 3+ hosts. | When adding a second host, consider introducing path-scoped rules (e.g. `secrets/host-bandit/` vs. `secrets/shared/`) so host keys decrypt only what they need. |
| `.sops.yaml` | `scaling-gap` | `moderate` | The `&host` anchor is unnamed/generic. Adding a second host requires a naming decision (`&host_bandit`, `&host_hostname2`) and a manual README update. The current single-host naming will be ambiguous at two hosts. | Rename `&host` to `&host_bandit` now to establish the per-host naming convention before a second host is added. |
| `nixos-modules/features/security/secrets.nix` | `good-pattern` | `n/a` | Secret file paths are generic (no hostname embedded); the `username` arg is parametric. Module is reusable across hosts unchanged. | No change needed. |
| `nixos-modules/features/security/secrets.nix` | `missing-abstraction` | `minor` | Only `github.yaml` is wired up in the NixOS secrets module. Other secrets (`cachix.yaml`, `context7-api.yaml`, `helicone.yaml`, `mistral.yaml`, `github-mcp.yaml`) exist in the `secrets/` directory but are not referenced by any module. It is unclear whether they are consumed elsewhere or orphaned. | Audit each `.yaml` in `secrets/` for active module references; remove or document orphaned entries. |
| `secrets/README.md` | `good-pattern` | `n/a` | The README documents the full add-new-machine workflow including `sops updatekeys`, recovery procedures, and key rotation. Operationally complete. | No change needed. |
