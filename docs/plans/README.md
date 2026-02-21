# Implementation Plans

This directory contains detailed planning documents for major refactoring and feature work in the nixos-config repository.

## Status Overview

**Most work described in these plans is PARTIALLY COMPLETE or DEFERRED.**

The NixOS-side architecture (explicit features) is complete. Home-Manager features and profile bundles remain future work.

## Active Plans

None currently active. The repository is in a stable state with the explicit features architecture implemented for NixOS modules.

## Archived/Superseded Plans

### 2026-02-18: Explicit Modules Refactor
- **Design**: `2026-02-18-explicit-modules-design.md` (657 lines)
- **Implementation**: `2026-02-18-explicit-modules-implementation.md` (2109 lines)
- **Status**: ✅ NixOS features complete, ⏸️ home-modules features deferred
- **Outcome**: NixOS modules successfully refactored to explicit `features.*` structure

### 2026-02-20: Development Tools & AI Integration
- **Design**: `2026-02-20-development-tools-design.md` (336 lines)
- **Implementation (A)**: `2026-02-20-ai-dev-tools-implementation.md` (958 lines)
- **Implementation (B)**: `2026-02-20-dev-tools-sequential-implementation.md` (234 lines)
- **Status**: ⏸️ Deferred pending requirements clarification
- **Scope**: AI coding tools, dev environments, direnv integration

### 2026-02-10: Theme Unification
- **Plan**: `2026-02-10-theme-unification.md` (418 lines)
- **Status**: ⏸️ Superseded by Stylix integration
- **Note**: Stylix now handles theme management

## Next Steps

When resuming structured development work:

1. **Profiles Implementation** (deferred from Phase 3)
   - Create `nixos-modules/profiles/` bundles: desktop, development, server
   - Reduces per-host configuration verbosity
   - Ref: `2026-02-18-explicit-modules-implementation.md` Phase 3 section

2. **Home-Manager Features Migration** (deferred from Phase 4)
   - Port home-modules to explicit `features.*` structure
   - Currently uses flat category-based organization
   - Ref: `2026-02-18-explicit-modules-implementation.md` Phase 4 section

3. **Development Environment Optimization**
   - Assess value of specialized dev shells vs monolithic approach
   - Consider direnv+devenv integration if multi-project workflow emerges
   - Ref: `2026-02-20-development-tools-design.md`

4. **Cleanup Remaining Markers**
   - 100+ TODO/FIXME/Phase comments remain in codebase
   - Most are legitimate future work items, not scaffolding artifacts

## Philosophy

These plans represent **documentation of thought processes**, not binding roadmaps. The repository follows YAGNI (You Aren't Gonna Need It) - features are implemented when needed, not preemptively. Verbose plans are preserved for context, but execution should be lean and pragmatic.
