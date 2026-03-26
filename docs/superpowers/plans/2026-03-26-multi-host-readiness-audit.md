# Multi-Host Readiness Audit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Perform a layered structural analysis of the NixOS config repo to surface technical debt that must be addressed before adding a second host.

**Architecture:** Read each layer of the config in dependency order (flake → entrypoints → modules → cross-cutting), record findings in a standard format to scratch files, then compile into a final audit report. Tasks 2–6 (modules, shared, lib, overlays) are independent and can be dispatched in parallel.

**Tech Stack:** Read-only analysis. Tools: Read, Grep, Glob, Bash. Output: Markdown. No nix builds required.

---

## Finding Format

Every finding recorded in scratch files must use this exact format (one per line in a findings table):

```
| file | category | severity | description | recommendation |
```

Categories: `hardcoded-literal`, `structural-coupling`, `missing-abstraction`, `scaling-gap`, `good-pattern`
Severities: `blocker`, `moderate`, `minor` (use `n/a` for `good-pattern`)

---

## File Map

| Action | Path | Purpose |
|--------|------|---------|
| Create | `docs/superpowers/audit-scratch/layer-1-3-findings.md` | Findings from flake + entrypoints |
| Create | `docs/superpowers/audit-scratch/layer-4-findings.md` | Findings from nixos-modules |
| Create | `docs/superpowers/audit-scratch/layer-5-findings.md` | Findings from home-modules |
| Create | `docs/superpowers/audit-scratch/layer-6-findings.md` | Findings from shared-modules |
| Create | `docs/superpowers/audit-scratch/layer-7-findings.md` | Findings from lib |
| Create | `docs/superpowers/audit-scratch/layer-8-findings.md` | Findings from overlays |
| Create | `docs/superpowers/audit-scratch/layer-9-10-findings.md` | Findings from profiles + secrets |
| Create | `docs/superpowers/specs/2026-03-26-multi-host-readiness-audit.md` | Final compiled report |

---

## Task 1: Analyze Layers 1–3 (Flake + Entrypoints)

**Files:**
- Read: `flake.nix`
- Read: `nixos-configurations/bandit/default.nix`
- Read: `nixos-configurations/bandit/hardware-configuration.nix`
- Read: `home-configurations/vino/default.nix`
- Read: `home-configurations/vino/hosts/bandit.nix`
- Create: `docs/superpowers/audit-scratch/layer-1-3-findings.md`

- [ ] **Step 1: Read flake.nix and analyze host/user registration**

Read `flake.nix` in full. Answer these questions as you read:
- How are NixOS hosts registered? (look for `nixosConfigurations`, `ez-configs` settings, or equivalent)
- How are Home Manager users registered?
- Is the host name ("bandit") hardcoded in the flake, or derived from a variable?
- Is the username ("vino") hardcoded?
- What would adding a second host require in this file?

- [ ] **Step 2: Read NixOS host entrypoint and analyze feature toggles**

Read `nixos-configurations/bandit/default.nix` and `nixos-configurations/bandit/hardware-configuration.nix`. Answer:
- Which features are toggled per-host here vs. always-on in modules?
- Are there any values that would need to be different for a new host (hostname, hardware paths, UUIDs)?
- Is the structure clearly separating host-specific from shared config?
- Does `hardware-configuration.nix` contain anything that should live in a module instead?

- [ ] **Step 3: Read Home Manager entrypoints and analyze _module.args + host overrides**

Read `home-configurations/vino/default.nix` and `home-configurations/vino/hosts/bandit.nix`. Answer:
- What is injected via `_module.args`? Is any of it host-specific (e.g., a value sourced from bandit hardware)?
- Is the `hosts/<hostname>.nix` override pattern clearly defined and consistent?
- If a second user existed (e.g., `home-configurations/alice/`), what would need to be duplicated?
- Does the `_module.args` injection assume a single user context anywhere?

- [ ] **Step 4: Record findings to scratch file**

Create `docs/superpowers/audit-scratch/layer-1-3-findings.md` with this structure:

```markdown
# Layer 1–3 Findings: Flake + Entrypoints

## Layer 1: flake.nix

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
| flake.nix | ... | ... | ... | ... |

## Layer 2: nixos-configurations/bandit/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 3: home-configurations/vino/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
```

Record every finding you identified in Steps 1–3. Include `good-pattern` rows for things done well. If a layer has no issues, write a single `good-pattern` row noting what is clean.

- [ ] **Step 5: Commit scratch file**

```bash
mkdir -p docs/superpowers/audit-scratch
git add docs/superpowers/audit-scratch/layer-1-3-findings.md
git commit -m "audit: layer 1-3 findings (flake + entrypoints)"
```

---

## Task 2: Analyze Layer 4 (NixOS Modules)

**Note: Can run in parallel with Tasks 3, 4, 5, 6.**

**Files:**
- Read: `nixos-modules/default.nix`
- Read: `nixos-modules/home-manager.nix`
- Read: `nixos-modules/core/` (all .nix files)
- Read: `nixos-modules/features/` (all .nix files recursively)
- Create: `docs/superpowers/audit-scratch/layer-4-findings.md`

- [ ] **Step 1: Read all NixOS modules**

Read every file under `nixos-modules/` (there are ~20 files). For each file, check:
- Does it reference "bandit" by name anywhere (hardcoded hostname)?
- Does it reference "vino" by name anywhere (hardcoded username)?
- Does it set options that should be per-host but are hardcoded (e.g., IP addresses, UUIDs, hardware paths)?
- Does any module import a file by absolute path that assumes a single-host structure?
- Does any `core/` module contain logic that should be in a feature toggle instead?

Also check `nixos-modules/home-manager.nix`:
- Is the home-manager user configured in a way that hardcodes "vino"?
- Would adding a second user require changes here?

Helpful grep to run before reading (to find literal references):
```bash
grep -r "bandit\|vino" nixos-modules/ --include="*.nix" -n
```

- [ ] **Step 2: Record findings**

Create `docs/superpowers/audit-scratch/layer-4-findings.md`:

```markdown
# Layer 4 Findings: nixos-modules/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
```

Fill in all findings. If clean, note what is well-structured.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/audit-scratch/layer-4-findings.md
git commit -m "audit: layer 4 findings (nixos-modules)"
```

---

## Task 3: Analyze Layer 5 (Home Modules)

**Note: Can run in parallel with Tasks 2, 4, 5, 6.**

**Files:**
- Read: `home-modules/default.nix`
- Read: `home-modules/core/` (all .nix files)
- Read: `home-modules/features/` (all .nix files recursively)
- Create: `docs/superpowers/audit-scratch/layer-5-findings.md`

- [ ] **Step 1: Grep for hardcoded references first**

```bash
grep -r "bandit\|vino\|/home/vino" home-modules/ --include="*.nix" -n
```

Note every hit — these are candidates for `hardcoded-literal` findings.

- [ ] **Step 2: Read home-modules/core/ files**

Read all files in `home-modules/core/`: `default.nix`, `devices.nix`, `nixpkgs.nix`, `package-managers.nix`, `secrets.nix`. Check:
- Does `devices.nix` or `secrets.nix` reference bandit-specific hardware or paths?
- Does `package-managers.nix` assume a specific user's home directory?
- Is there anything in core that should be a per-host option?

- [ ] **Step 3: Read home-modules/features/ files**

Read all files under `home-modules/features/` (covers desktop, editor, shell, terminal). This is the largest layer. Focus on:
- Any module using `config.networking.hostName` or a literal "bandit"
- Any module that reads a host-specific path (e.g., `/dev/input/...`, `/sys/...`)
- Any module where the option default is appropriate for bandit but not universally
- The `vibe/` module — is it clearly optional/feature-flagged?
- The `profiles.nix` cross-reference (note it, analyze fully in Task 7)

- [ ] **Step 4: Record findings**

Create `docs/superpowers/audit-scratch/layer-5-findings.md`:

```markdown
# Layer 5 Findings: home-modules/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
```

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/audit-scratch/layer-5-findings.md
git commit -m "audit: layer 5 findings (home-modules)"
```

---

## Task 4: Analyze Layer 6 (Shared Modules)

**Note: Can run in parallel with Tasks 2, 3, 5, 6.**

**Files:**
- Read: `shared-modules/palette.nix`
- Read: `shared-modules/workspaces.nix`
- Read: `shared-modules/stylix-common.nix`
- Create: `docs/superpowers/audit-scratch/layer-6-findings.md`

- [ ] **Step 1: Read all three shared modules**

Read each file. For each, check:
- Does it hardcode any host-specific value (font, wallpaper path, color that differs by host)?
- `stylix-common.nix`: Is the wallpaper path absolute or relative? Does it assume a specific path under `/home/vino`?
- `workspaces.nix`: Are the workspace definitions generic enough for any host, or are they tailored to bandit's hardware (e.g., number of monitors, specific app launchers)?
- `palette.nix`: Are color definitions purely aesthetic (fine) or do any reference host-specific things?

- [ ] **Step 2: Check how these modules are imported**

```bash
grep -r "shared-modules\|stylix-common\|palette\|workspaces" flake.nix nixos-configurations/ home-configurations/ --include="*.nix" -n
```

Verify the import paths don't hardcode host names.

- [ ] **Step 3: Record findings**

Create `docs/superpowers/audit-scratch/layer-6-findings.md`:

```markdown
# Layer 6 Findings: shared-modules/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/audit-scratch/layer-6-findings.md
git commit -m "audit: layer 6 findings (shared-modules)"
```

---

## Task 5: Analyze Layer 7 (Lib Helpers)

**Note: Can run in parallel with Tasks 2, 3, 4, 6.**

**Files:**
- Read: `lib/default.nix`
- Create: `docs/superpowers/audit-scratch/layer-7-findings.md`

- [ ] **Step 1: Read lib/default.nix in full**

Read the file. For each helper function, check:
- Does it accept all it needs as arguments, or does it close over hardcoded values?
- `mkWorkspaceBindings` / `mkWorkspaceName`: Are workspace counts or names configurable, or fixed for bandit's setup?
- `mkColorReplacer`: Is it purely functional (takes replacements as input), or does it reference a specific theme file path?
- `mkPolybarTwoTone` / `mkPolybarTwoToneState`: Do these close over any host-specific color assumptions?
- `mkBtrfsOpts`: Are the mount options generic or bandit-specific?
- `mkSecretValidation`: Does this assume a specific secrets file structure?

- [ ] **Step 2: Record findings**

Create `docs/superpowers/audit-scratch/layer-7-findings.md`:

```markdown
# Layer 7 Findings: lib/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/audit-scratch/layer-7-findings.md
git commit -m "audit: layer 7 findings (lib)"
```

---

## Task 6: Analyze Layer 8 (Overlays)

**Note: Can run in parallel with Tasks 2, 3, 4, 5.**

**Files:**
- Read: `overlays/default.nix`
- Read: `overlays/custom-packages.nix`
- Create: `docs/superpowers/audit-scratch/layer-8-findings.md`

- [ ] **Step 1: Read both overlay files**

Read each file. Check:
- Do any custom package derivations reference bandit-specific hardware (e.g., kernel modules, firmware)?
- Are overlays purely additive (adding packages) or do any conditionally modify based on hostname?
- Is `overlays/default.nix` generic enough to work for any host, or does it contain bandit-specific selections?

```bash
grep -n "bandit\|vino\|hostname\|hostName" overlays/ -r --include="*.nix"
```

- [ ] **Step 2: Record findings**

Create `docs/superpowers/audit-scratch/layer-8-findings.md`:

```markdown
# Layer 8 Findings: overlays/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
```

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/audit-scratch/layer-8-findings.md
git commit -m "audit: layer 8 findings (overlays)"
```

---

## Task 7: Analyze Layers 9–10 (Profiles + Secrets)

**Depends on: Tasks 1–6 complete (needs full picture of the module system)**

**Files:**
- Read: `home-modules/profiles.nix`
- Read: `nixos-modules/features/security/secrets.nix`
- Glob: `secrets/` directory
- Create: `docs/superpowers/audit-scratch/layer-9-10-findings.md`

- [ ] **Step 1: Analyze the profile system**

Read `home-modules/profiles.nix` in full. Answer:
- What is a "profile"? How are they defined and activated?
- Is profile activation per-host, per-user, or global?
- If a second host needed different profiles than bandit, how would that work?
- Is there any coupling between profiles and specific hardware/host assumptions?
- Would a second user need to copy this file or can they reuse it?

- [ ] **Step 2: Analyze secrets structure**

Run:
```bash
ls -la secrets/
find secrets/ -type f | sort
```

Read `nixos-modules/features/security/secrets.nix`. Answer:
- How are age keys registered? Is there one key per host, or a shared key?
- Are secret paths hardcoded with "bandit" in them, or parameterized?
- What would enrolling a second host's age key require? (Changes to which files?)
- Is there a clear pattern for per-host secrets vs. shared secrets?

- [ ] **Step 3: Record findings**

Create `docs/superpowers/audit-scratch/layer-9-10-findings.md`:

```markdown
# Layer 9–10 Findings: profiles + secrets

## Layer 9: home-modules/profiles.nix

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 10: secrets/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/audit-scratch/layer-9-10-findings.md
git commit -m "audit: layer 9-10 findings (profiles + secrets)"
```

---

## Task 8: Compile Final Audit Report

**Depends on: All previous tasks complete**

**Files:**
- Read: all `docs/superpowers/audit-scratch/*.md` files
- Create: `docs/superpowers/specs/2026-03-26-multi-host-readiness-audit.md`

- [ ] **Step 1: Read all scratch files**

Read every file in `docs/superpowers/audit-scratch/`. Collect all findings into a single mental list. Identify:
- All `blocker` findings (these become executive summary candidates)
- All `moderate` findings
- All `good-pattern` findings
- Recurring themes (e.g., "username vino appears in 3 layers")

- [ ] **Step 2: Draft executive summary**

Select the top 3–5 most impactful findings. Prioritize `blocker` severity, then `moderate`. Write 1–2 sentences per finding explaining: what it is, why it matters for multi-host, what category it falls into.

- [ ] **Step 3: Write the audit report**

Create `docs/superpowers/specs/2026-03-26-multi-host-readiness-audit.md` with this structure:

```markdown
# Multi-Host Readiness Audit

**Date:** 2026-03-26
**Scope:** Full repo structural analysis, excluding .direnv/.devenv
**Goal:** Identify technical debt before adding a second NixOS host

---

## Executive Summary

Top findings that must be addressed before a second host can be added:

1. **[Finding title]** (`blocker`|`moderate`) — [1-2 sentence description and impact]
2. ...

---

## Layer 1: flake.nix

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 2: nixos-configurations/bandit/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 3: home-configurations/vino/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 4: nixos-modules/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 5: home-modules/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 6: shared-modules/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 7: lib/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 8: overlays/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 9: home-modules/profiles.nix

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

## Layer 10: secrets/

| File | Category | Severity | Description | Recommendation |
|------|----------|----------|-------------|----------------|

---

## Good Patterns

Things done well that should be preserved or extended:

- **[Pattern name]:** [Description of what it does and why it's a good foundation]
- ...

---

## Refactor Priorities

Ordered list of what to address before adding a second host (blockers first, then moderates):

1. **[Priority title]** — [What to do, which files are involved]
2. ...
```

Fill in every section with real findings from the scratch files. Do not leave placeholder rows — if a layer has no issues, replace the table with a single sentence "No issues found."

- [ ] **Step 4: Verify the report**

Check the completed report:
- Every finding in the scratch files appears in exactly one layer table
- Every executive summary item is also in a layer table (no orphan findings)
- Every `blocker` finding appears in the refactor priorities list
- No rows contain "TBD", "TODO", or empty cells

- [ ] **Step 5: Commit report and clean up scratch**

```bash
git add docs/superpowers/specs/2026-03-26-multi-host-readiness-audit.md
git add docs/superpowers/audit-scratch/
git commit -m "audit: multi-host readiness report complete"
```

---

## Execution Notes

**Parallel dispatch:** Tasks 2–6 have no dependencies on each other and can be dispatched simultaneously by a subagent orchestrator after Task 1 completes.

**Dependency chain:**
```
Task 1 → Tasks 2–6 (parallel) → Task 7 → Task 8
```
