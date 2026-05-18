# NixOS Config Refactor Reference Study

**Date:** 2026-05-13  
**Status:** Draft research baseline

## Problem

This repository has grown into a capable but dense NixOS/Home Manager setup with several strong abstractions already in place:

- `ez-configs` auto-imported module registries
- separate `nixos-modules/`, `home-modules/`, `shared-modules/`, and `lib/`
- host-specific Home Manager overrides
- profile-based package grouping
- feature-toggle modules using `options.features.<category>.<name>.enable`

The next large refactor should improve structure and maintainability without flattening away the parts that are already better than typical public starter repos.

To guide that work, this document studies two public references:

1. `dustinlyons/nixos-config`
2. `Misterio77/nix-starter-configs`

The goal is not to copy either repo directly. The goal is to extract the patterns that transfer well, identify the ones that do not, and turn that into a refactor direction for this codebase.

## Decisions

### 1. Keep the current high-level separation model

Do **not** simplify this repo down to a generic starter layout.

Current strengths worth preserving:

- `shared-modules/` for cross-layer reuse
- `lib/` for project-specific helper functions
- `flake-modules/` for flake composition
- host-specific HM overrides in `home-configurations/vino/hosts/`
- multi-host growth path
- feature-toggle modules on both NixOS and Home Manager sides

Both reference repos are useful, but this repo is already more modular than `nix-starter-configs` and more feature-flag driven than `dustinlyons/nixos-config`.

### 2. Borrow from `dustinlyons/nixos-config` selectively

Patterns worth studying/adapting:

- **clear platform/domain separation** (`shared/`, `nixos/`, `darwin/`)
- **isolated secrets module** instead of mixing secret concerns into unrelated modules
- **overlay auto-discovery** from the filesystem to reduce manual flake wiring
- **composition-first Home Manager assembly** instead of overly large monolithic module files

Patterns to avoid copying directly:

- hardcoded user or host assumptions
- hostname-based implicit behavior
- large monolithic modules
- architecture designed around Darwin support if this repo does not need it yet

### 3. Borrow from `nix-starter-configs` selectively

Patterns worth studying/adapting:

- **three-overlay convention** (`additions`, `modifications`, `unstable-packages`)
- **simple hardware separation** where machine-specific hardware stays isolated from broader host intent
- **clean unstable package access pattern** such as `pkgs.unstablePkgs.*` when justified
- **small, obvious module registries** that are easy to scan

Patterns to avoid copying directly:

- single-host assumptions
- single-user assumptions
- removing current shared abstractions just to resemble a starter repo
- losing current feature-module flexibility

### 4. Refactor toward clearer boundaries, not fewer files

The better direction is:

- smaller modules with sharper ownership
- clearer system vs user vs shared boundaries
- less incidental coupling between desktop/theme/host/profile concerns
- simpler overlay and secrets organization

It is **not**:

- collapsing modules into one large `configuration.nix`
- replacing feature toggles with hostname conditionals
- discarding current layering because a starter repo is smaller

## Reference Repo Summary

### A. `dustinlyons/nixos-config`

#### What it does well

- separates shared, NixOS-only, and Darwin-only concerns cleanly
- keeps secrets in dedicated modules
- uses composition patterns that make the Home Manager layer easier to reason about
- supports multiple target configurations from one flake
- reduces some flake boilerplate through overlay loading patterns

#### What to learn from it

- platform/domain boundaries should be obvious from directory structure
- secrets and infrastructure concerns should have dedicated homes
- overlay loading can be made more automatic and less manual
- large modules should be split before they become ownership bottlenecks

#### What does **not** transfer cleanly here

- hardcoded-user ergonomics
- repo decisions driven by Darwin support
- weaker feature-flag ergonomics than this repo already has

### B. `Misterio77/nix-starter-configs`

#### What it does well

- keeps starter structure approachable
- makes overlays easy to understand via explicit categories
- separates hardware concerns from broader host intent
- keeps module registry files simple and predictable
- demonstrates a clean unstable-package access pattern

#### What to learn from it

- overlays should communicate intent by structure
- hardware-specific state should stay isolated
- starter-friendly clarity is valuable even in advanced repos

#### What does **not** transfer cleanly here

- single-host starter assumptions
- fewer abstractions at the expense of reuse
- no equivalent to this repo's `shared-modules/`, `lib/`, or flake modularization depth

## Current Repo Assessment Against Both References

### Current strengths to keep

1. **Feature module pattern**
   - `options.features.<category>.<name>.enable`
   - `config = lib.mkIf cfg.enable { ... }`
   - This is stronger than ad-hoc host logic.

2. **System/Home separation**
   - `nixos-configurations/` and `home-configurations/` are already distinct.
   - This should remain a core design principle.

3. **Shared utility layer**
   - `shared-modules/` and `lib/` are meaningful advantages.
   - Neither reference repo provides the same combined depth.

4. **Host override layer**
   - `home-configurations/vino/hosts/` gives precise host-local control without collapsing common logic.

5. **Flake modularization**
   - `flake-modules/` is already a strong maintainability tool and should be treated as a foundation, not a problem.

### Current refactor opportunities

1. **Overlay structure**
   - Current `overlays/custom-packages.nix` centralizes unrelated concerns.
   - Strong candidate for a split into intent-based overlay files.

2. **Secrets structure**
   - Secrets are present and functional, but dedicated structure could become more explicit and easier to audit.

3. **Host vs hardware split**
   - Host intent and hardware-specific state should be evaluated for cleaner separation where still mixed.

4. **Desktop/service boundary clarity**
   - Recent LightDM/XFCE → greetd/i3 cleanup shows why desktop/login ownership must stay explicit.
   - Future refactors should keep display manager logic in NixOS modules and user session composition in Home Manager.

5. **Documentation drift**
   - Architecture docs still contain outdated `i3-xfce` / LightDM references.
   - Refactor work should include doc synchronization as a first-class task.

## Proposed Refactor Direction

### Phase 1 — Structural cleanup without behavior change

- split overlay responsibilities into multiple files/directories
- audit large modules for single-responsibility splits
- isolate hardware-only state from broader host configuration
- tighten documentation so architecture docs match actual code

### Phase 2 — Boundary cleanup

- review whether every concern lives in the correct layer:
  - NixOS module
  - Home Manager module
  - shared module
  - helper library
  - host override
- reduce places where a feature requires jumping across too many files to understand ownership

### Phase 3 — Configuration ergonomics

- standardize overlay conventions
- standardize secrets conventions
- standardize unstable-package access if needed
- reduce implicit coupling between profiles, hosts, and feature modules

### Phase 4 — Optional future enhancements

- consider more automation/discovery for overlays or module registration where it improves clarity
- consider extracting especially complex feature families into tighter subtrees with clearer READMEs
- only consider Darwin-style cross-platform expansion if that becomes a real project requirement

## Concrete Recommendations

### Adopt soon

1. **Intent-based overlay split**
   - Suggested shape:
     - `overlays/additions.nix`
     - `overlays/modifications.nix`
     - `overlays/unstable-packages.nix`
     - optional `overlays/default.nix` aggregator

2. **Dedicated refactor of stale architecture docs**
   - Update `docs/FEATURE_MODULES.md`
   - Update `docs/architecture/components.md`
   - Update `docs/architecture/README.md`
   - Remove LightDM/XFCE-era descriptions that no longer match code

3. **Review host/hardware separation for `bandit` and future hosts**
   - keep machine-specific hardware state isolated
   - keep host intent readable at the entrypoint level

### Consider later

1. **More explicit secrets module boundaries**
2. **Overlay auto-discovery if it reduces flake boilerplate without obscuring behavior**
3. **Module size budget for especially large feature files**

### Do not do

1. **Do not flatten the repo into a starter-template structure**
2. **Do not replace feature flags with hostname-driven conditionals**
3. **Do not remove `shared-modules/`, `lib/`, or `flake-modules/` just for symmetry with other repos**
4. **Do not treat smaller public repos as inherently cleaner if they solve fewer problems**

## Suggested Follow-up Tasks

1. Create a dedicated overlay refactor plan.
2. Run a docs sync pass for architecture documentation.
3. Identify the top 5 largest or most cross-cutting modules and decide which should be split.
4. Audit secrets/hardware/host boundaries for `bandit` and any planned additional hosts.
5. Produce a target-state architecture diagram after the first structural cleanup phase.

## Out of Scope

- immediate behavioral rewrites
- changing secret backend technology
- introducing Darwin support
- replacing `ez-configs`
- broad renaming of existing module trees without a separate migration plan

## QA

Research sources used for this document:

- local architecture documentation under `docs/architecture/`
- local module structure review of:
  - `nixos-configurations/`
  - `home-configurations/`
  - `nixos-modules/`
  - `home-modules/`
  - `shared-modules/`
  - `lib/`
  - `overlays/`
- external study summaries for:
  - `dustinlyons/nixos-config`
  - `Misterio77/nix-starter-configs`

This document is intended to be the canonical planning baseline for a later large refactor. It should be updated when the architecture docs are synchronized or when a concrete refactor plan is approved.
