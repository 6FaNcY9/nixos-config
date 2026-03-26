# Layer 7 Findings: lib/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| `lib/default.nix` | `good-pattern` | `n/a` | `mkWorkspaceName` and `mkWorkspaceBindings` are fully parameterized — workspace list, modifier key, and command prefix are all caller-supplied; no counts or names are hardcoded | No action needed |
| `lib/default.nix` | `good-pattern` | `n/a` | `mkColorReplacer` is a pure higher-order function: takes a colors attrset and returns a string-to-string transformer; no reference to any theme file path or host-specific color | No action needed |
| `lib/default.nix` | `good-pattern` | `n/a` | `mkPolybarTwoTone` / `mkPolybarTwoToneState` accept `color`, `colorAlt`, and `fg` as arguments with sensible defaults; they close over no host-specific color values — callers supply polybar color-set names | No action needed |
| `lib/default.nix` | `good-pattern` | `n/a` | `mkSecretValidation` / `validateSecretEncrypted` / `validateSecretExists` operate purely on caller-supplied `Path` values; no hardcoded secrets directory or file structure is assumed | No action needed |
| `lib/default.nix` | `good-pattern` | `n/a` | `mkBoolOpt` and `mkProfile` are generic `lib.mkOption` shorthands with no host-specific defaults or types | No action needed |
| `lib/default.nix` | `hardcoded-literal` | `minor` | `mkBtrfsOpts` hardcodes SSD/battery-optimized options (`discard=async`, `compress-force=zstd:1`, `space_cache=v2`) — these are correct for bandit (Framework 13 SSD) but would be inappropriate for a spinner or NVMe on a desktop host | Accept an optional `extraOpts` list param, or document that callers on HDD hosts must not use this helper |
| `lib/default.nix` | `good-pattern` | `n/a` | `darkenColor` is a pure arithmetic function over a hex string; no theme coupling, no host state | No action needed |
| `lib/default.nix` | `good-pattern` | `n/a` | `mkShellScript` is a generic `pkgs.writeShellScriptBin` wrapper; `pkgs` is caller-supplied | No action needed |
| `lib/default.nix` | `good-pattern` | `n/a` | The whole lib is exposed as a single attrset taken by `{ lib }:` — no flake inputs, no host config leaked in; callers inject only what they need | No action needed |
