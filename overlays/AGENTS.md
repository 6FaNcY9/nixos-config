# AGENTS.md — overlays/

Composed by `overlays/default.nix` → `additions.nix` ∪ `modifications.nix`. Applied via `flake.nix` `pkgsFor`.

## Files
- `default.nix` — composes additions then modifications (modifications can reference added pkgs).
- `additions.nix` — packages **not** in nixpkgs upstream.
- `modifications.nix` — overrides of upstream packages.
- `custom-packages.nix` — **NOT imported**. Dead/staging file; either wire it in or delete.

## Current Additions (`additions.nix`)
- `hermes-agent` — pulled from upstream flake input.
- `mistral-vibe` — flake input (uv2nix wrapper).
- `opencode-bun` — `writeShellApplication` impure wrapper, `bun install -g opencode-ai@latest` on first run. Respects `BUN_INSTALL` from `home-modules/core/package-managers.nix`.

## Current Modifications
- `tree-sitter-cli` pinned to **0.26.5** for nixvim compatibility. Do not bump without checking nixvim breakage.

## When Adding a Package
- Genuinely missing upstream → `additions.nix`.
- Tweak/pin/patch of existing → `modifications.nix`. Use `final` + `prev` correctly: read from `prev`, expose under `final`.
- Impure runtime fetchers (like `opencode-bun`) are tolerated but documented in code comments.
