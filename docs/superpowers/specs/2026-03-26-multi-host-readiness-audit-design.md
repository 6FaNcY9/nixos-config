# Multi-Host Readiness Audit Design

**Date:** 2026-03-26
**Goal:** Pre-refactor scan to identify technical debt before adding a second NixOS host to this config repo.
**Approach:** Layered structural analysis — read each layer of the config, reason about what is host-specific vs. shared, hardcoded vs. parameterized, and what patterns would break or require duplication for a second host.

---

## Scope & Layers

The audit covers every layer of the config, excluding `.direnv` and `.devenv`, analyzed in this order:

| # | Layer | Path(s) | What we check |
|---|-------|---------|---------------|
| 1 | Flake entrypoint | `flake.nix` | How hosts/users are registered; how a second host would be added |
| 2 | NixOS host entrypoint | `nixos-configurations/bandit/` | What is hardcoded vs. feature-toggled per host |
| 3 | Home Manager entrypoint | `home-configurations/vino/` | `_module.args` injection; host overrides pattern in `hosts/bandit.nix` |
| 4 | NixOS modules | `nixos-modules/` | Core + features; host assumptions in shared modules |
| 5 | Home modules | `home-modules/` | Core + features; user/host-specific assumptions in shared modules |
| 6 | Shared modules | `shared-modules/` | palette, workspaces, stylix-common — single-host assumptions |
| 7 | Lib helpers | `lib/` | Helper functions — hardcoded values, single-host assumptions |
| 8 | Overlays | `overlays/` | Custom packages — host-specific derivations |
| 9 | Profile system | `home-modules/profiles.nix` | Does the profile system scale to multiple hosts/users? |
| 10 | Secrets | `secrets/` | Age key structure — per-host keys, how a second host would be enrolled |

---

## Finding Categories

| Category | Description |
|----------|-------------|
| `hardcoded-literal` | Hostname, username, path, or hardware value baked into a shared or reusable module |
| `structural-coupling` | A module that assumes single-host context (e.g., reads a sibling file that only exists for bandit) |
| `missing-abstraction` | Something that works for one host but would require copy-paste for a second (no option, no parameter, no profile hook) |
| `scaling-gap` | A pattern that works for one host but becomes unwieldy at 2+ (e.g., flat list needing per-host branching) |
| `good-pattern` | Something done well that should be preserved or extended in the refactor |

---

## Severity Levels

| Severity | Meaning |
|----------|---------|
| `blocker` | Would prevent a second host from building correctly without changes |
| `moderate` | Would require duplication or workarounds; not a build failure but bad practice |
| `minor` | Cosmetic, low-risk, or only a concern at 3+ hosts |

---

## Execution Approach

Analysis is performed as a single-pass read of each layer:

1. **Layers 1–3 first** (flake + entrypoints): establish the multi-host registration pattern, which informs interpretation of everything else.
2. **Layers 4–8 in parallel** (modules, shared, lib, overlays): independent of each other, can be analyzed concurrently.
3. **Layers 9–10 last** (profiles + secrets): cross-cut the module system and depend on understanding the earlier layers.

---

## Output

A single audit report at:
`docs/superpowers/specs/2026-03-26-multi-host-readiness-audit.md`

Structure:
- **Executive summary** — top 3–5 most impactful findings
- **Per-layer findings** — one table per layer (file, category, severity, description, recommendation)
- **Good patterns** — what is working well and should be preserved
- **Refactor priorities** — ordered list of what to address before adding a second host

The report feeds into a separate implementation plan for the actual refactor work.
