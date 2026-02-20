# AI Development Tools Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add AI development tools (Claude Code, OpenCode, Mistral Vibe, Codex) to NixOS configuration with direct GitHub fetching for bleeding-edge releases.

**Architecture:** Sequential implementation (one tool at a time). Each tool gets its own package in `overlays/ai-tools/`, direct GitHub input in flake, and feature flag in `features.development.tools.ai`. Verify each tool before proceeding to next.

**Tech Stack:** Nix, buildNpmPackage, flake-parts, ez-configs

---

## Phase 1: Infrastructure Setup

### Task 1.1: Create AI Tools Overlay Directory

**Files:**
- Create: `overlays/ai-tools/default.nix`

**Step 1: Create overlay directory**

```bash
mkdir -p overlays/ai-tools
```

**Step 2: Create aggregator overlay**

File: `overlays/ai-tools/default.nix`

```nix
# AI development tools overlay
# Direct GitHub fetching for bleeding-edge releases
inputs: final: prev: {
  # Tools will be added here as we implement them
  # claude-code = ...
  # opencode = ...
  # mistral-vibe = ...
  # codex = ...
}
```

**Step 3: Update main overlays to include AI tools**

File: `overlays/default.nix`

Find the overlay list and add after custom-packages:

```nix
overlays = [
  # ... existing overlays ...
  (import ./custom-packages.nix inputs)
  (import ./ai-tools inputs)  # NEW: AI development tools
];
```

**Step 4: Verify syntax**

```bash
nix flake check 2>&1 | head -20
```

Expected: No syntax errors (other warnings OK)

**Step 5: Commit**

```bash
git add overlays/ai-tools/default.nix overlays/default.nix
git commit -m "feat(overlays): add ai-tools overlay directory

Prepare infrastructure for AI development tools with direct GitHub
fetching. Tools will be added incrementally.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 1.2: Create Feature Module Skeleton

**Files:**
- Create: `nixos-modules/features/development/tools.nix`
- Modify: `nixos-modules/features/development/default.nix`

**Step 1: Create feature module**

File: `nixos-modules/features/development/tools.nix`

```nix
# Feature: Development Tools
# Provides: AI development tools (Claude Code, OpenCode, etc.)
# Dependencies: None
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.features.development.tools;
in
{
  options.features.development.tools = {
    ai = {
      claudeCode = {
        enable = lib.mkEnableOption "Claude Code CLI from Anthropic";
      };

      opencode = {
        enable = lib.mkEnableOption "OpenCode AI coding assistant";
      };

      mistralVibe = {
        enable = lib.mkEnableOption "Mistral Vibe CLI";
      };

      codex = {
        enable = lib.mkEnableOption "OpenAI Codex CLI";
      };
    };
  };

  config = {
    environment.systemPackages = lib.filter (p: p != null) [
      (lib.mkIf cfg.ai.claudeCode.enable (pkgs.claude-code or null))
      (lib.mkIf cfg.ai.opencode.enable (pkgs.opencode or null))
      (lib.mkIf cfg.ai.mistralVibe.enable (pkgs.mistral-vibe or null))
      (lib.mkIf cfg.ai.codex.enable (pkgs.codex or null))
    ];

    # Warnings for unavailable tools
    warnings =
      lib.optional (cfg.ai.claudeCode.enable && !(pkgs ? claude-code))
        "features.development.tools: claude-code package not available"
      ++ lib.optional (cfg.ai.mistralVibe.enable && !(pkgs ? mistral-vibe))
        "features.development.tools: mistral-vibe package not available"
      ++ lib.optional (cfg.ai.codex.enable && !(pkgs ? codex))
        "features.development.tools: codex package not available";
  };
}
```

**Step 2: Add to development features aggregator**

File: `nixos-modules/features/development/default.nix`

```nix
# Development feature modules
{ ... }:
{
  imports = [
    ./base.nix
    ./tools.nix  # NEW
  ];
}
```

**Step 3: Verify module loads**

```bash
nix flake check 2>&1 | grep -i "development\|error" | head -20
```

Expected: No errors related to development modules

**Step 4: Commit**

```bash
git add nixos-modules/features/development/tools.nix nixos-modules/features/development/default.nix
git commit -m "feat(development): add AI tools feature module skeleton

Create features.development.tools.ai module with options for:
- Claude Code
- OpenCode
- Mistral Vibe
- Codex

Packages will be added incrementally. Graceful handling if package
doesn't exist (warning instead of error).

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 2: Tool 1 - Claude Code

### Task 2.1: Find Claude Code Repository

**Step 1: Search for official repo**

Manual research step - check:
- `github.com/anthropics/claude-code`
- `github.com/anthropics/anthropic-cli`
- Anthropic documentation

**Step 2: Verify repo structure**

Check for:
- `package.json` (npm/node based)
- Build instructions
- CLI executable name

**Step 3: Document findings**

Create note with:
- Exact GitHub URL
- Build system (npm/bun/etc)
- Executable name
- Any special build requirements

**If repo not found:** Skip to Task 3.1 (OpenCode), document how to add Claude Code later

---

### Task 2.2: Add Claude Code Flake Input

**Files:**
- Modify: `flake.nix`

**Step 1: Add GitHub input**

File: `flake.nix`

Find `inputs = {` section and add:

```nix
inputs = {
  # ... existing inputs ...

  # AI development tools (direct GitHub fetching)
  claude-code-src = {
    url = "github:anthropics/claude-code";  # UPDATE with actual repo
    flake = false;
  };
};
```

**Step 2: Pass input to overlays**

Find where overlays are imported and ensure inputs are passed:

```nix
overlays = import ./overlays { inherit inputs; };
```

**Step 3: Update flake lock**

```bash
nix flake update claude-code-src
```

Expected: Downloads and pins the repo

**Step 4: Verify input accessible**

```bash
nix flake metadata | grep claude-code-src
```

Expected: Shows the locked input

**Step 5: Commit**

```bash
git add flake.nix flake.lock
git commit -m "feat(flake): add claude-code GitHub input

Add direct GitHub source for Claude Code to enable bleeding-edge
releases via nix flake update.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 2.3: Create Claude Code Package

**Files:**
- Create: `overlays/ai-tools/claude-code/default.nix`
- Create: `overlays/ai-tools/claude-code/package.nix`

**Step 1: Create package directory**

```bash
mkdir -p overlays/ai-tools/claude-code
```

**Step 2: Create overlay definition**

File: `overlays/ai-tools/claude-code/default.nix`

```nix
# Claude Code overlay - AI coding assistant from Anthropic
final: prev: {
  claude-code = final.callPackage ./package.nix {
    src = inputs.claude-code-src;
  };
}
```

**Step 3: Create build recipe**

File: `overlays/ai-tools/claude-code/package.nix`

```nix
{
  lib,
  buildNpmPackage,
  nodejs,
  src,
}:

buildNpmPackage {
  pname = "claude-code";
  version = src.shortRev or (src.rev or "dirty");

  inherit src;

  npmDepsHash = lib.fakeHash;  # Will update after first build

  # If the tool needs special handling (like bun isolation), add here
  # buildPhase = ''
  #   npm run build
  # '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r dist/* $out/bin/
    runHook postInstall
  '';

  meta = {
    description = "Claude Code - AI coding assistant from Anthropic";
    homepage = "https://github.com/anthropics/claude-code";
    license = lib.licenses.mit;  # UPDATE based on actual license
    platforms = lib.platforms.all;
  };
}
```

**Step 4: Add to overlay aggregator**

File: `overlays/ai-tools/default.nix`

```nix
# AI development tools overlay
inputs: final: prev:
  (import ./claude-code final prev)
  # More tools will be added here
```

**Step 5: Attempt first build**

```bash
nix build .#claude-code 2>&1 | tee /tmp/claude-code-build.log
```

Expected: FAIL with hash mismatch (this is normal)

**Step 6: Update npmDepsHash**

From build output, copy the correct hash and update `package.nix`:

```nix
npmDepsHash = "sha256-CORRECT_HASH_HERE";
```

**Step 7: Build again**

```bash
nix build .#claude-code
```

Expected: SUCCESS, creates `./result` symlink

**Step 8: Test the binary**

```bash
./result/bin/claude-code --version
# OR
./result/bin/claude --version
# (check package.json for actual executable name)
```

Expected: Shows version or help output

**Step 9: Commit**

```bash
git add overlays/ai-tools/claude-code/ overlays/ai-tools/default.nix
git commit -m "feat(ai-tools): add Claude Code package

Add Claude Code CLI from Anthropic with direct GitHub fetching.
Package built with buildNpmPackage and tested working.

Executable: claude-code (or claude)
Source: Direct from github:anthropics/claude-code

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 2.4: Enable Claude Code System-Wide

**Files:**
- Modify: `nixos-configurations/bandit/default.nix`

**Step 1: Add feature flag**

File: `nixos-configurations/bandit/default.nix`

Find `features = {` section and add:

```nix
features = {
  # ... existing features ...

  development = {
    base = {
      enable = config.roles.development;
      # ... existing config ...
    };

    tools.ai.claudeCode.enable = config.roles.development;  # NEW
  };

  # ... rest of features ...
};
```

**Step 2: Build system configuration**

```bash
nixos-rebuild build --flake .#bandit 2>&1 | tee /tmp/rebuild.log
```

Expected: Build succeeds, creates ./result symlink

**Step 3: Check Claude Code in closure**

```bash
ls -la result/sw/bin/ | grep claude
```

Expected: Shows claude-code binary (or claude)

**Step 4: Rebuild and switch (dry-run first)**

```bash
nixos-rebuild dry-run --flake .#bandit
```

Expected: Shows what would be installed/updated

**Step 5: Commit**

```bash
git add nixos-configurations/bandit/default.nix
git commit -m "feat(bandit): enable Claude Code

Enable Claude Code AI assistant system-wide when development role is
active. Binary available in PATH after rebuild.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Step 6: Apply the change (optional - user decides)**

```bash
# Only run if user wants to apply now
sudo nixos-rebuild switch --flake .#bandit
```

**Step 7: Verify installation (if applied)**

```bash
which claude-code  # or: which claude
claude-code --version
```

Expected: Shows path and version

---

## Phase 3: Tool 2 - OpenCode

### Task 3.1: Migrate OpenCode Package

**Files:**
- Create: `overlays/ai-tools/opencode/default.nix`
- Create: `overlays/ai-tools/opencode/package.nix`
- Modify: `overlays/custom-packages.nix`

**Step 1: Create package directory**

```bash
mkdir -p overlays/ai-tools/opencode
```

**Step 2: Extract OpenCode from custom-packages**

Read current implementation:

```bash
grep -A 50 "opencode" overlays/custom-packages.nix
```

**Step 3: Create overlay definition**

File: `overlays/ai-tools/opencode/default.nix`

```nix
# OpenCode overlay - AI coding assistant
final: prev: {
  opencode = final.callPackage ./package.nix {
    src = inputs.opencode-src;
  };
}
```

**Step 4: Create package file**

File: `overlays/ai-tools/opencode/package.nix`

Copy the exact implementation from `custom-packages.nix`, preserving:
- All build steps
- `bun --compile` with `--linker=isolated`
- `postInstall` chmod steps
- Meta information

```nix
{
  lib,
  stdenv,
  bun,
  src,
}:

stdenv.mkDerivation {
  pname = "opencode";
  version = src.shortRev or (src.rev or "dirty");

  inherit src;

  nativeBuildInputs = [ bun ];

  buildPhase = ''
    # Copy exact build steps from custom-packages.nix
    bun install --frozen-lockfile
    bun run build
    bun --compile --linker=isolated dist/index.js --outfile opencode
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp opencode $out/bin/
  '';

  postInstall = ''
    chmod +x $out/bin/opencode
  '';

  meta = {
    description = "OpenCode - AI coding assistant";
    homepage = "https://github.com/...";  # UPDATE
    platforms = lib.platforms.all;
  };
}
```

**Step 5: Update overlay aggregator**

File: `overlays/ai-tools/default.nix`

```nix
# AI development tools overlay
inputs: final: prev:
  (import ./claude-code final prev)
  // (import ./opencode final prev)
```

**Step 6: Remove from custom-packages (or comment out)**

File: `overlays/custom-packages.nix`

Comment out or remove the opencode section:

```nix
# opencode - MIGRATED to overlays/ai-tools/opencode/
```

**Step 7: Build test**

```bash
nix build .#opencode
```

Expected: SUCCESS (should work same as before)

**Step 8: Test binary**

```bash
./result/bin/opencode --version
```

Expected: Same output as before migration

**Step 9: Commit**

```bash
git add overlays/ai-tools/opencode/ overlays/ai-tools/default.nix overlays/custom-packages.nix
git commit -m "refactor(ai-tools): migrate OpenCode to ai-tools overlay

Move OpenCode from custom-packages to new ai-tools overlay structure.
Preserves all build steps including bun isolation.

No functional changes - binary builds identically.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 3.2: Enable OpenCode in Feature Module

**Files:**
- Modify: `nixos-configurations/bandit/default.nix`

**Step 1: Add feature flag**

File: `nixos-configurations/bandit/default.nix`

```nix
tools.ai = {
  claudeCode.enable = config.roles.development;
  opencode.enable = config.roles.development;  # NEW
};
```

**Step 2: Build and verify**

```bash
nixos-rebuild build --flake .#bandit
ls -la result/sw/bin/ | grep opencode
```

Expected: Shows opencode binary

**Step 3: Commit**

```bash
git add nixos-configurations/bandit/default.nix
git commit -m "feat(bandit): enable OpenCode via feature module

Enable OpenCode through new features.development.tools.ai interface.
Replaces direct package installation.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Phase 4: Tool 3 - Mistral Vibe

### Task 4.1: Research Mistral Vibe Repository

**Step 1: Search for official repo**

Check:
- `github.com/mistralai/mistral-vibe`
- `github.com/mistralai/cli`
- `github.com/mistralai/mistral-cli`
- Mistral AI documentation

**Step 2: Document findings**

If found:
- Exact GitHub URL
- Build system
- Executable name
- Continue to Task 4.2

If not found:
- Document search attempts
- Add comment in feature module
- Skip to Phase 5 (Codex)

---

### Task 4.2: Add Mistral Vibe (if repo exists)

**Files:**
- Modify: `flake.nix`
- Create: `overlays/ai-tools/mistral-vibe/default.nix`
- Create: `overlays/ai-tools/mistral-vibe/package.nix`
- Modify: `overlays/ai-tools/default.nix`
- Modify: `nixos-configurations/bandit/default.nix`

**Follow same pattern as Claude Code (Tasks 2.2 - 2.4):**

1. Add flake input for `mistral-vibe-src`
2. Create package overlay
3. Build and test
4. Enable in bandit config
5. Commit each step

---

## Phase 5: Tool 4 - Codex

### Task 5.1: Research Codex Repository

**Step 1: Search for official repo**

Check:
- `github.com/openai/codex`
- `github.com/openai/codex-cli`
- OpenAI documentation
- Note: Codex API was deprecated, CLI might not exist

**Step 2: Document findings**

If found: Continue to Task 5.2
If not found: Document and mark as unavailable

---

### Task 5.2: Add Codex (if repo exists)

**Follow same pattern as Claude Code (Tasks 2.2 - 2.4)**

---

## Phase 6: Documentation & Cleanup

### Task 6.1: Document AI Tools Setup

**Files:**
- Create: `docs/AI_TOOLS.md`

**Step 1: Create documentation**

File: `docs/AI_TOOLS.md`

```markdown
# AI Development Tools

This configuration includes AI development tools with direct GitHub fetching for bleeding-edge releases.

## Available Tools

### Claude Code (Anthropic)
**Enabled:** Yes
**Source:** github:anthropics/claude-code (direct)
**Usage:** `claude-code --help`

### OpenCode
**Enabled:** Yes
**Source:** github:open-code-ai/opencode (direct)
**Usage:** `opencode --help`

### Mistral Vibe
**Enabled:** [Yes/No/Not Available]
**Source:** [URL or "Not found"]
**Usage:** [Command or "Not available"]

### Codex
**Enabled:** [Yes/No/Not Available]
**Source:** [URL or "Not found"]
**Usage:** [Command or "Not available"]

## Updating Tools

Get latest releases:
```bash
nix flake update  # Updates all AI tool sources
sudo nixos-rebuild switch --flake .#bandit
```

Update specific tool:
```bash
nix flake update claude-code-src
sudo nixos-rebuild switch --flake .#bandit
```

## Adding New Tools

1. Add flake input: `flake.nix`
2. Create package: `overlays/ai-tools/<tool>/`
3. Add overlay import: `overlays/ai-tools/default.nix`
4. Add option: `nixos-modules/features/development/tools.nix`
5. Enable: `nixos-configurations/bandit/default.nix`

## Configuration

Location: `features.development.tools.ai.*`

```nix
features.development.tools.ai = {
  claudeCode.enable = true;
  opencode.enable = true;
  mistralVibe.enable = true;  # if available
  codex.enable = true;        # if available
};
```
```

**Step 2: Commit**

```bash
git add docs/AI_TOOLS.md
git commit -m "docs: add AI development tools guide

Document available AI tools, update process, and how to add new tools.
Includes usage examples and configuration reference.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

### Task 6.2: Update Main README

**Files:**
- Modify: `README.md`

**Step 1: Add AI tools section**

File: `README.md`

Find the "Editing Guide" section and add:

```markdown
- **AI development tools**: `features.development.tools.ai.*` in host config
  - See `docs/AI_TOOLS.md` for available tools and usage
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: reference AI tools in README

Add pointer to AI_TOOLS.md documentation in editing guide.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Verification Checklist

After completing all phases, verify:

**Infrastructure:**
- [ ] `overlays/ai-tools/` directory exists
- [ ] `features.development.tools` module exists
- [ ] Flake inputs for all available tools

**Claude Code (minimum requirement):**
- [ ] Package builds: `nix build .#claude-code`
- [ ] Binary works: `./result/bin/claude-code --version`
- [ ] In system: `which claude-code` (after rebuild)
- [ ] Feature flag works: Enable/disable in bandit config

**OpenCode (minimum requirement):**
- [ ] Migrated from custom-packages
- [ ] Builds identically to before
- [ ] Feature flag works

**Optional Tools:**
- [ ] Mistral Vibe: [Built / Not Available / Documented]
- [ ] Codex: [Built / Not Available / Documented]

**Documentation:**
- [ ] `docs/AI_TOOLS.md` exists
- [ ] README updated
- [ ] All commits follow conventional commits format
- [ ] Each commit builds successfully

**Flake Update Test:**
- [ ] `nix flake update` updates AI tool sources
- [ ] Rebuild picks up new versions
- [ ] Tools still work after update

---

## Success Criteria

**Minimum (Phase 2-3 complete):**
- ✅ Claude Code working
- ✅ OpenCode migrated and working
- ✅ Feature module controlling both
- ✅ Documentation complete

**Full Success (All phases):**
- ✅ All 4 tools attempted
- ✅ Available tools working
- ✅ Unavailable tools documented
- ✅ Pattern established for adding more

**Quality:**
- ✅ Each commit builds independently
- ✅ No breaking changes to existing features
- ✅ Clean git history
- ✅ Comprehensive documentation

---

## Rollback Procedures

**Per Tool:**
```nix
# Disable in config
features.development.tools.ai.claudeCode.enable = false;
```

**Remove Tool Entirely:**
```bash
# Remove package
rm -rf overlays/ai-tools/claude-code/

# Remove from overlay aggregator
# Edit overlays/ai-tools/default.nix

# Remove flake input
# Edit flake.nix

# Rebuild
nix flake update
sudo nixos-rebuild switch --flake .#bandit
```

**Revert All Changes:**
```bash
# Find first commit of this work
git log --oneline | grep "ai-tools\|claude-code"

# Revert to before that commit
git revert <commit-hash>..HEAD
```

---

## Time Estimates

- **Phase 1** (Infrastructure): 15-20 minutes
- **Phase 2** (Claude Code): 60-90 minutes
- **Phase 3** (OpenCode): 30-45 minutes
- **Phase 4** (Mistral Vibe): 45-60 minutes (if exists)
- **Phase 5** (Codex): 45-60 minutes (if exists)
- **Phase 6** (Documentation): 20-30 minutes

**Total:** 3.5-6 hours depending on tool availability

**Minimum (just Claude Code + OpenCode):** ~2.5 hours
