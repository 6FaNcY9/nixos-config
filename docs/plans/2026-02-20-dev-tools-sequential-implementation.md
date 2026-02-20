# AI Development Tools - Sequential Implementation Design

**Created**: 2026-02-20
**Status**: Approved - Ready for Implementation
**Approach**: Sequential (one tool at a time)

---

## Overview

Integrate AI development tools (Claude Code, OpenCode, Mistral Vibe, Codex) into NixOS configuration using direct GitHub fetching for bleeding-edge releases. Tools are installed system-wide via feature module, not globally managed packages.

## Key Decisions

### ✅ Approved Scope
- **AI tools only** - No global npm/bun package management
- **Direct GitHub fetching** - AI tools always on latest commits
- **Sequential implementation** - One tool at a time for validation
- **Skip if unavailable** - Gracefully handle missing repos

### ❌ Out of Scope
- Global npm/bun package management (keep project-local via package.json)
- Per-project tool overrides (use devshells if needed)
- Tool configuration management (can add later via Home Manager)

## Architecture

### Module Structure
```nix
# nixos-configurations/bandit/default.nix
features.development.tools.ai = {
  claudeCode.enable = true;
  opencode.enable = true;
  mistralVibe.enable = true;  # if repo exists
  codex.enable = true;        # if repo exists
};
```

### File Organization
```
nixos-modules/features/development/
├── base.nix        # Existing: containers, build tools, direnv
└── tools.nix       # NEW: AI tool management

overlays/ai-tools/  # NEW directory
├── default.nix     # Aggregator overlay
├── claude-code/
│   ├── default.nix        # Overlay definition
│   └── package.nix        # Build recipe
├── opencode/       # Migrated from custom-packages.nix
│   ├── default.nix
│   └── package.nix
├── mistral-vibe/   # If repo exists
│   ├── default.nix
│   └── package.nix
└── codex/          # If repo exists
    ├── default.nix
    └── package.nix

flake.nix
└── inputs          # Direct GitHub sources
    ├── claude-code-src = { url = "github:anthropics/claude-code"; flake = false; }
    ├── mistral-vibe-src = { url = "github:mistralai/???"; flake = false; }
    └── codex-src = { url = "github:openai/???"; flake = false; }
```

## Package Building Pattern

### Direct GitHub Fetching
Each tool uses this pattern (based on existing OpenCode):

```nix
# overlays/ai-tools/claude-code/default.nix
final: prev: {
  claude-code = final.callPackage ./package.nix {
    src = inputs.claude-code-src;
  };
}
```

### Build Recipe
```nix
# overlays/ai-tools/claude-code/package.nix
{ lib, buildNpmPackage, nodejs, src }:

buildNpmPackage {
  pname = "claude-code";
  version = src.shortRev or "dirty";
  inherit src;

  npmDepsHash = lib.fakeHash;  # Replace after first build

  # Special handling if needed (like OpenCode's bun isolation)
  # buildPhase, installPhase, etc.
}
```

### Update Workflow
```bash
nix flake update                    # Fetches latest commits
nixos-rebuild switch --flake .#bandit  # Rebuilds with new versions
```

## Sequential Implementation Order

### Tool 1: Claude Code (~90 minutes)
**Goal**: Establish the pattern

1. Find official Anthropic repo (likely `github:anthropics/claude-code`)
2. Add flake input
3. Create `overlays/ai-tools/claude-code/` package
4. Add to `overlays/ai-tools/default.nix`
5. Create `features.development.tools` module
6. Enable in bandit config
7. Build, test, commit

**Verification**:
- `which claude-code` shows path
- `claude-code --version` works
- Available after rebuild

---

### Tool 2: OpenCode (~45 minutes)
**Goal**: Validate pattern with existing code

1. Migrate from `overlays/custom-packages.nix`
2. Move to `overlays/ai-tools/opencode/`
3. Update overlay references
4. Add to feature module
5. Build, test, commit

**Benefit**: Proves migration path works, validates overlay structure

---

### Tool 3: Mistral Vibe (~60 minutes, if exists)
**Goal**: Apply pattern to new tool

1. Search for official Mistral AI CLI repo
2. If found: Clone Claude Code pattern
3. If not found: Document for later, skip
4. Build, test, commit

---

### Tool 4: Codex (~60 minutes, if exists)
**Goal**: Complete the set

1. Search for official OpenAI CLI repo
2. If found: Clone Claude Code pattern
3. If not found: Document for later, skip
4. Build, test, commit

---

## Error Handling & Edge Cases

### Verification Steps (per tool)
- ✅ Package builds successfully
- ✅ Binary runs and shows version
- ✅ Available in PATH after rebuild
- ✅ `nix flake update` fetches new commits
- ✅ No conflicts with other packages

### Edge Cases
1. **Repo doesn't exist**: Skip tool, add comment in code on how to add later
2. **Build needs special handling**: Follow OpenCode pattern (uses `bun --compile`)
3. **Hash mismatch**: Update with `nix-prefetch-url` or build with `--impure` first
4. **Tool breaks on update**: Pin to working commit, file issue upstream

### Rollback Strategy
Each tool is independent:
- Disable in feature module: `claudeCode.enable = false;`
- Remove overlay if problematic
- Pin flake input to working commit

## Benefits

### Immediate Value
- Get Claude Code working in 90 minutes
- Use it while building remaining tools
- Stop at any point if satisfied

### Risk Mitigation
- One variable at a time (easier debugging)
- Unknown repos won't block known tools
- Learn from each implementation

### Clean Evolution
- Git history shows clear progression
- Each commit is independently useful
- Easy to review and understand

## Success Criteria

**Per Tool**:
- ✅ Package builds without errors
- ✅ Tool available in PATH
- ✅ `--version` or `--help` works
- ✅ Rebuild completes successfully
- ✅ Clean commit with working code

**Overall**:
- ✅ At least 2 tools working (Claude Code + OpenCode minimum)
- ✅ Pattern established for adding more tools
- ✅ Documentation on adding new tools
- ✅ `nix flake update` workflow validated

## Future Enhancements (Not Now)

- Home Manager integration for per-user tool configs
- Tool plugin/extension management
- Global package management (if evidence shows it's needed)
- Per-project tool version overrides via devshells
- Automatic tool configuration file generation

## References

- Existing: `overlays/custom-packages.nix` (OpenCode implementation)
- Pattern: `features/services/tailscale.nix` (feature module template)
- Pattern: Direct GitHub fetching in other flakes

---

## Next Steps

1. ✅ Design approved
2. ➡️ Create implementation plan with `writing-plans` skill
3. Execute plan sequentially (Tool 1 → Tool 2 → Tool 3 → Tool 4)
4. Verify each step before proceeding
5. Document final setup

**Ready for implementation planning.**
