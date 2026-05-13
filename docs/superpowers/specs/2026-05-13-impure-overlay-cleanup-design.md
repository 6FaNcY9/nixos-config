# Impure Overlay Cleanup — Design Spec

**Date:** 2026-05-13  
**Status:** Approved

## Problem

Three packages in `overlays/custom-packages.nix` use runtime network fetches (`npx --yes` or `bun install`), breaking NixOS reproducibility. One of these (`strip-json-comments-cli`) is installed unconditionally via `profiles.dev` (enabled by default). Additionally, `pkgs.opencode` and `opencode-bun` are both in `aiPkgs`, creating a redundant dual-source situation where the bun version shadows the Nix version silently if `$BUN_INSTALL/bin` is in PATH.

Three `.sisyphus/evidence/task-*.txt` files describe repo state that no longer exists and contradict the actual code.

## Decisions

- **`agentsys`** — remove. Not actively used. `npx --yes agentsys` at runtime is impure and no replacement is needed.
- **`strip-json-comments-cli`** — remove. Not actively used. Was quietly always installed via the default dev profile.
- **`opencode`** (anomalyco fork overlay) — remove. Superseded by `opencode-bun` as the authoritative opencode source.
- **`inputs.opencode`** (flake input) — remove. Only consumed by the overlay entry being removed.
- **`opencode-bun`** — keep. Intentionally impure; always installs latest upstream. Existing `# IMPURE` comment is sufficient.
- **All three `.sisyphus/evidence/task-*.txt` files** — delete. All describe a prior repo state; restic is gone, codexPkg was never in `_module.args`, vibe moved from `shell` to `desktop`.

## Changes

### 1. `overlays/custom-packages.nix`
Remove entries: `agentsys`, `strip-json-comments-cli`, `opencode`.  
Retain: `tree-sitter-cli`, `hermes-agent`, `mistral-vibe`, `opencode-bun`.

### 2. `flake.nix`
Remove the `inputs.opencode` block (url + comment, ~9 lines).  
Retain: all other inputs including `hermes-agent` and `mistral-vibe`.

### 3. `home-modules/profiles.nix`
- Remove `agentsysPkg` let-binding
- Remove `pkgs.opencode` from `aiPkgs`
- Remove `agentsysPkg` from `aiPkgs`
- Remove `pkgs.strip-json-comments-cli` from `devPkgs`
- Update `ai` profile description comment

### 4. `.sisyphus/evidence/`
`git rm` all three `task-*.txt` evidence files.

## Out of Scope

- `hermes.nix` dag key (`"sopsNix"`) — correct as-is; verify live with `nh home switch` manually.
- `opencode-bun` impurity — intentional and documented; no change.
- Any other overlays or profiles.

## QA

1. `just qa` — format + lint + flake check
2. `just rebuild-test` — dry-run NixOS build for bandit
