# Development Tools Integration - Design Document

**Created**: 2026-02-20
**Status**: Design Complete - Pending Implementation
**Priority**: After Phase 5 (Polish & Documentation) completion

---

## Overview

Integrate AI development tools (Claude Code, OpenCode, Mistral Vibe, Codex) and their package ecosystems (npm, bun, apm) into the NixOS configuration for complete declarative control.

## Goals

1. **Declarative Control** - All AI tools and global packages managed via Nix
2. **Version Pinning** - Reproducible development environment
3. **Latest AI Tools** - Always track bleeding-edge releases via direct GitHub fetching
4. **Project Isolation** - Per-project tool versions via direnv/nix-shell
5. **Hybrid Approach** - Global tools via Nix, project dependencies via package.json

## Requirements

### AI Tools to Integrate
- **Claude Code** (Anthropic CLI)
- **OpenCode** (already has custom package)
- **Mistral Vibe** (Mistral AI CLI)
- **Codex** (if available)

### Package Management
- **Global packages**: TypeScript, ESLint, Prettier, language servers → Nix-managed
- **Project packages**: Keep using package.json/bun.lockb for project dependencies
- **XDG paths**: Already configured in `home-modules/package-managers.nix`

### Update Strategy
- **AI tools**: Direct GitHub fetching (Option D from brainstorming)
  - `nix flake update` fetches latest releases immediately
  - No waiting for nixpkgs-unstable to package updates
  - Get new features within hours of release
- **Other packages**: Continue using nixpkgs-unstable

## Architecture (Approach 2: Feature-Based Tool Management)

### Module Structure
```nix
features.development.tools = {
  ai = {
    claudeCode.enable = true;
    opencode.enable = true;
    mistralVibe.enable = true;
    codex.enable = true;
  };

  globalPackages = {
    npm = [ "typescript" "eslint" "prettier" ];
    bun = [ "some-bun-tool" ];
  };
};
```

### File Organization
```
nixos-modules/features/development/
├── base.nix              # Existing: Docker, Podman, build essentials
└── tools.nix             # NEW: AI tools and global packages

overlays/
├── custom-packages.nix   # Extend: Add Mistral Vibe, enhance AI tool fetching
└── ai-tools/             # NEW: Separate overlay for AI tools
    ├── claude-code.nix
    ├── mistral-vibe.nix
    └── codex.nix

flake.nix
└── inputs                # Add GitHub sources for AI tools
    ├── claude-code-src
    ├── mistral-vibe-src
    └── codex-src (if available)
```

## Implementation Components

### 1. Feature Module: `features.development.tools`

**Location**: `nixos-modules/features/development/tools.nix`

**Responsibilities**:
- Declare options for each AI tool (enable, version override, etc.)
- Declare global npm/bun package lists
- Import packages from overlays
- Provide per-tool configuration options

**Example Structure**:
```nix
options.features.development.tools = {
  ai = {
    claudeCode = {
      enable = lib.mkEnableOption "Claude Code CLI";
      experimental = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable experimental features";
      };
    };

    mistralVibe = {
      enable = lib.mkEnableOption "Mistral Vibe CLI";
    };

    # ... other tools
  };

  globalPackages = {
    npm = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Global npm packages to install";
    };
  };
};

config = lib.mkIf cfg.enable {
  environment.systemPackages = lib.filter (p: p != null) [
    (lib.mkIf cfg.ai.claudeCode.enable pkgs.claude-code)
    (lib.mkIf cfg.ai.mistralVibe.enable pkgs.mistral-vibe)
    # ... build npm packages
  ];
};
```

### 2. Overlay: AI Tools Direct Fetching

**Location**: `overlays/ai-tools/`

**Pattern** (based on existing OpenCode):
```nix
# claude-code.nix
final: prev: {
  claude-code =
    let
      src = inputs.claude-code-src;  # Direct GitHub input
      rev = src.shortRev or (src.rev or "dirty");
    in
    final.callPackage ./claude-code-package.nix {
      inherit src rev;
    };
}
```

**For each AI tool**:
1. Create flake input pointing to GitHub repo
2. Create package definition that builds from latest source
3. Handle any special build requirements (like OpenCode's bun --linker=isolated)

### 3. Global Package Management

**Approach**: Use `buildNpmPackage` or similar for declarative npm globals

```nix
globalNpmPackages = map (pkg:
  pkgs.buildNpmPackage {
    pname = pkg;
    version = "latest";  # or pin specific versions
    # ... fetch from npm registry
  }
) cfg.globalPackages.npm;
```

**Alternative**: Use `nodePackages` from nixpkgs for well-known packages:
```nix
globalNpmPackages = map (pkg:
  pkgs.nodePackages.${pkg}
) cfg.globalPackages.npm;
```

### 4. Flake Inputs

**Add to `flake.nix`**:
```nix
inputs = {
  # Existing inputs...

  # AI tool sources (direct GitHub tracking)
  claude-code-src = {
    url = "github:anthropics/claude-code";
    flake = false;
  };

  mistral-vibe-src = {
    url = "github:mistralai/mistral-vibe";  # Verify correct repo
    flake = false;
  };

  codex-src = {
    url = "github:openai/codex-cli";  # Verify if exists
    flake = false;
  };
};
```

## Integration Points

### NixOS Level (`nixos-modules/features/development/tools.nix`)
- System-wide AI tool installation
- Global package management
- Binary availability in PATH

### Home Manager Level (Future Enhancement)
- Per-user tool configurations
- Tool-specific settings (Claude Code config, Mistral Vibe settings)
- User-level global packages

### Project Level (Via devShells)
- Already supported via existing devshells
- Can override tool versions per-project if needed

## Migration Path

### Phase 1: Core Infrastructure
1. Create `features.development.tools` module skeleton
2. Add flake inputs for AI tool sources
3. Create base overlays for direct GitHub fetching

### Phase 2: AI Tool Integration
1. Migrate existing OpenCode package to new structure
2. Add Claude Code package (if not in nixpkgs-unstable already)
3. Add Mistral Vibe package
4. Add Codex package (if available)
5. Test each tool builds and runs

### Phase 3: Global Package Management
1. Implement npm global package builder
2. Add common global packages (TypeScript, ESLint, Prettier)
3. Add bun global package support
4. Test package installation and PATH

### Phase 4: Host Configuration
1. Enable in `bandit/default.nix`:
   ```nix
   features.development.tools = {
     ai = {
       claudeCode.enable = true;
       opencode.enable = true;
       mistralVibe.enable = true;
     };
     globalPackages.npm = [
       "typescript"
       "eslint"
       "prettier"
       "typescript-language-server"
     ];
   };
   ```

### Phase 5: Verification & Polish
1. Verify tools update on `nix flake update`
2. Test global package installation
3. Document usage in README
4. Add to `docs/using-devshells.md`

## Benefits

### Reproducibility
- Entire development environment defined in code
- `nix flake update` gets latest AI tools
- No more "works on my machine" - same tools everywhere

### Simplicity
- One place to manage all development tools
- No scattered `npm install -g` commands
- No manual tool updates

### Consistency
- Follows established feature-based pattern
- Same structure as other features (storage, services, etc.)
- Clear enable/disable per host

### Flexibility
- Can pin specific versions if needed
- Can override per-project via devshells
- Hybrid approach: Nix for globals, package.json for projects

## Trade-offs & Considerations

### Pros
- Complete declarative control
- Always latest AI tools
- Reproducible environment
- Follows NixOS philosophy

### Cons
- Initial setup effort (~4-6 hours)
- Need to maintain package definitions for AI tools
- Slightly more complex than `npm install -g`
- AI tools may need special handling (like OpenCode's bun isolation)

### Mitigations
- OpenCode package already exists as template
- Can start with just AI tools, add globals later
- Community nixpkgs may package tools over time
- Clear documentation makes maintenance easier

## Success Criteria

1. ✅ All AI tools installable via `features.development.tools.ai.*`
2. ✅ `nix flake update` fetches latest AI tool releases
3. ✅ Global npm/bun packages declaratively managed
4. ✅ Tools available in PATH system-wide
5. ✅ Configuration works on rebuild
6. ✅ Documentation updated

## Future Enhancements (Out of Scope)

- Home Manager integration for per-user configs
- Tool extension/plugin management
- Per-project devShell templates
- Automatic tool config file generation
- Tool version pinning UI

## References

- Existing: `home-modules/profiles.nix` (ai profile)
- Existing: `overlays/custom-packages.nix` (OpenCode package)
- Existing: `home-modules/package-managers.nix` (XDG paths)
- Pattern: `features/services/tailscale.nix` (feature module template)
- Pattern: `features/storage/boot.nix` (feature module with options)

---

## Next Steps

1. Complete Phase 5 of the original refactor (polish & documentation)
2. Return to this design for implementation
3. Create implementation plan using writing-plans skill
4. Execute implementation in phases

**Implementation Readiness**: ✅ Design approved, ready for implementation planning
