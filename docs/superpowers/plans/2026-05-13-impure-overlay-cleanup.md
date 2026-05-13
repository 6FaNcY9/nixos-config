# Impure Overlay Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove two unused impure npx-wrapper packages and the dead opencode Nix overlay, leaving `opencode-bun` as the sole opencode source, and delete three stale `.sisyphus` evidence files.

**Architecture:** Pure deletion work across four files — no new code, no new modules. Each task is independent and can fail-safe: removing an unused package from an overlay and its profile reference cannot break anything that was working.

**Tech Stack:** Nix (nixfmt-rfc-style), flake-parts, Home Manager, git

---

### Task 1: Delete stale evidence files

**Files:**
- Delete: `.sisyphus/evidence/task-2-ai-wiring-map.txt`
- Delete: `.sisyphus/evidence/task-12-opencode-source.txt`
- Delete: `.sisyphus/evidence/task-3-restic-removal-checklist.txt`

- [ ] **Step 1: Confirm files exist**

```bash
ls .sisyphus/evidence/
```

Expected output includes all three `task-*.txt` files.

- [ ] **Step 2: Remove from git tracking**

```bash
git rm .sisyphus/evidence/task-2-ai-wiring-map.txt \
       .sisyphus/evidence/task-12-opencode-source.txt \
       .sisyphus/evidence/task-3-restic-removal-checklist.txt
```

Expected: three `rm` lines, no errors.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(sisyphus): delete stale evidence files

task-2 referenced codex-cli-nix input and codexPkg in _module.args — neither exists.
task-12 referenced opencodePkg in vino/default.nix — not there.
task-3 described restic removal — already done."
```

---

### Task 2: Remove agentsys and strip-json-comments-cli from the overlay

**Files:**
- Modify: `overlays/custom-packages.nix`

- [ ] **Step 1: Remove the `strip-json-comments-cli` block**

In `overlays/custom-packages.nix`, delete the entire block (including the comment):

```nix
  # strip-json-comments-cli: thin npx wrapper — avoids vendoring a package-lock.json.
  # IMPURE: `npx --yes` fetches from the npm registry at runtime (not sandboxed).
  # Accepted trade-off: vendoring would require a package-lock.json + FOD hash update on every bump.
  strip-json-comments-cli = prev.writeShellApplication {
    name = "strip-json-comments";
    runtimeInputs = [ prev.nodejs ];
    text = ''exec npx --yes strip-json-comments-cli "$@"'';
  };
```

- [ ] **Step 2: Remove the `agentsys` block**

In `overlays/custom-packages.nix`, delete the entire block (including the comment):

```nix
  # agentsys: thin npx wrapper — avoids vendoring a package-lock.json and EACCES patch.
  # IMPURE: `npx --yes` fetches from the npm registry at runtime (not sandboxed).
  # Accepted trade-off: vendoring would require a package-lock.json + FOD hash update on every bump.
  agentsys = prev.writeShellApplication {
    name = "agentsys";
    runtimeInputs = [ prev.nodejs ];
    text = ''exec npx --yes agentsys "$@"'';
  };
```

- [ ] **Step 3: Remove the `opencode` overlay block**

In `overlays/custom-packages.nix`, delete the entire block (including the comment):

```nix
  # opencode: anomalyco/opencode fork has correct hashes.json baked in for the current release.
  # prettier is a root devDep excluded by --filter '!./' in node_modules.nix; inject from nixpkgs.
  opencode =
    let
      inherit (final.stdenv.hostPlatform) system;
      base = inputs.opencode.packages.${system}.default;
    in
    base.overrideAttrs (old: {
      postConfigure = (old.postConfigure or "") + ''
        chmod -R u+w packages/opencode/node_modules
        mkdir -p packages/opencode/node_modules/prettier
        cp -r ${final.prettier}/lib/node_modules/prettier/. packages/opencode/node_modules/prettier/
      '';
    });
```

- [ ] **Step 4: Format**

```bash
nix fmt overlays/custom-packages.nix
```

Expected: no output (nixfmt-rfc-style is silent on success).

- [ ] **Step 5: Stage and verify diff looks clean**

```bash
git diff overlays/custom-packages.nix
```

Confirm only the three removed blocks appear in the diff — `tree-sitter-cli`, `hermes-agent`, `mistral-vibe`, and `opencode-bun` entries are untouched.

- [ ] **Step 6: Commit**

```bash
git add overlays/custom-packages.nix
git commit -m "refactor(overlays): remove agentsys, strip-json-comments-cli, opencode overlays

agentsys and strip-json-comments-cli were unused impure npx wrappers.
opencode nix package superseded by opencode-bun as the authoritative source."
```

---

### Task 3: Remove inputs.opencode from flake.nix

**Files:**
- Modify: `flake.nix`

- [ ] **Step 1: Remove the opencode input block**

In `flake.nix`, delete these lines (around line 105–110):

```nix
    # opencode: Using anomalyco/opencode fork which has correct nix/hashes.json baked in.
    # This fork tracks sst/opencode HEAD and has a simpler flake (nixpkgs-only inputs).
    # models-dev is available in nixpkgs, so no extra inputs needed.
    opencode = {
      url = "github:anomalyco/opencode/33b2795cc84c79e91e15549609713567eb08348a";
    };
```

The blank line before the `# Hermes Agent` comment can stay or be removed — either is fine.

- [ ] **Step 2: Format**

```bash
nix fmt flake.nix
```

- [ ] **Step 3: Regenerate flake.lock to drop the stale opencode entry**

```bash
just update
```

This runs `nix flake update` and rewrites `flake.lock`. The `opencode` entry will disappear since it's no longer declared in `flake.nix`.

- [ ] **Step 4: Commit**

```bash
git add flake.nix flake.lock
git commit -m "refactor(flake): remove inputs.opencode

No longer referenced after opencode overlay removal. opencode-bun is the sole opencode source."
```

---

### Task 4: Clean up profiles.nix

**Files:**
- Modify: `home-modules/profiles.nix`

- [ ] **Step 1: Remove `agentsysPkg` let-binding**

In the `let` block, delete this line:

```nix
  agentsysPkg = lib.attrByPath [ "agentsys" ] null pkgs;
```

- [ ] **Step 2: Remove `pkgs.opencode` and `agentsysPkg` from `aiPkgs`**

The current `aiPkgs` list:

```nix
  aiPkgs = lib.filter (p: p != null) [
    claudeCodePkg
    pkgs.opencode
    opencodeBunPkg
    githubCopilotPkg
    pkgs.mistral-vibe
    agentsysPkg
    (lib.attrByPath [ "hermes-agent" ] null pkgs)
  ];
```

Replace with:

```nix
  aiPkgs = lib.filter (p: p != null) [
    claudeCodePkg
    opencodeBunPkg
    githubCopilotPkg
    pkgs.mistral-vibe
    (lib.attrByPath [ "hermes-agent" ] null pkgs)
  ];
```

- [ ] **Step 3: Remove `pkgs.strip-json-comments-cli` from `devPkgs`**

In `devPkgs`, delete this line:

```nix
    pkgs.strip-json-comments-cli
```

- [ ] **Step 4: Update the `ai` profile description comment**

Find:

```nix
    ai = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AI tools package set.";
    }; # AI/LLM: claude-code, codex, opencode, github-copilot-cli
```

Replace the trailing comment:

```nix
    ai = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AI tools package set.";
    }; # AI/LLM: claude-code (nix), opencode (bun/latest), mistral-vibe, github-copilot-cli, hermes-agent
```

- [ ] **Step 5: Format**

```bash
nix fmt home-modules/profiles.nix
```

- [ ] **Step 6: Stage and verify diff**

```bash
git diff home-modules/profiles.nix
```

Confirm `opencodeBunPkg` let-binding and its `aiPkgs` entry are untouched.

- [ ] **Step 7: Commit**

```bash
git add home-modules/profiles.nix
git commit -m "refactor(profiles): remove agentsys, opencode-nix, strip-json-comments-cli

opencode-bun is now the sole opencode source (always latest).
agentsys and strip-json-comments-cli were unused impure wrappers."
```

---

### Task 5: QA gate

- [ ] **Step 1: Run full QA**

```bash
just qa
```

Expected: treefmt, statix, deadnix, and `nix flake check` all pass with no errors. Xorg deprecation warnings are harmless and expected.

- [ ] **Step 2: Dry-run NixOS build**

```bash
just rebuild-test
```

Expected: build completes (or shows nothing to rebuild). No evaluation errors.

- [ ] **Step 3: Verify opencode-bun is the only opencode in the activation package**

```bash
nix build .#homeConfigurations."vino@bandit".activationPackage --dry-run 2>&1 | grep -i opencode
```

Expected: only `opencode-bun` appears, no reference to `anomalyco/opencode`.
