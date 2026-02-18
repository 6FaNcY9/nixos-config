# NixOS Configuration: Issues and Recommendations

**Purpose:** Prioritized issue analysis with evidence-based findings and actionable recommendations.

**Last Updated:** 2026-02-18

---

## 📊 Top 5 Critical Issues

| # | Issue | Severity | Impact | Effort |
|---|-------|----------|--------|--------|
| 1 | Hardcoded repoRoot breaks portability | **Critical** | Prevents config reuse across machines/users | Low (2h) |
| 2 | Non-interactive hazards in apps.nix | **High** | Automation/CI failures with blocking prompts | Medium (4h) |
| 3 | Update automation creates dirty tree | **High** | Service fails after successful update | Low (1h) |
| 4 | HM isolation fragility (osConfig usage) | **High** | Tight coupling, breaks standalone HM deployments | Medium (3h) |
| 5 | GPG key split-brain configuration | **Medium** | Inconsistent key management across modules | Low (2h) |

---

## 🔍 Issues by Category

### 1. Portability Issues

#### 1.1 Hardcoded repoRoot Path
**Severity:** 🔴 **Critical**  
**File:Line:** `flake.nix:116`

**Evidence:**
```nix
# flake.nix:116
repoRoot = "/home/${username}/src/nixos-config";
```

**Impact:**
- Configuration assumes fixed directory structure: `/home/<username>/src/nixos-config`
- Breaks when:
  - Different user clones to different path (e.g., `/home/alice/repos/nixos`)
  - Multi-user environments (server with multiple admins)
  - Container/CI environments with non-standard paths
- Used in 3 places: `nixos-modules/core.nix:131` (nh.flake), `nixos-modules/services.nix:25,33,36,41` (update service)

**Root Cause:**
Comment in flake.nix:113-115 explains: "Must be a string (not a Nix path) because NixOS systemd units and nh need the literal runtime path; builtins.getEnv 'HOME' is empty during pure evaluation."

**Recommendation:**
1. Use `builtins.getEnv "PWD"` or `self.outPath` for runtime path discovery
2. Make `repoRoot` configurable per-host in `nixos-configurations/<host>/default.nix`
3. Document setup requirement: symlink convention or environment variable
4. Alternative: detect path at activation time via activation script

**Effort:** Low (2 hours)  
**Priority:** Fix before sharing config publicly

---

#### 1.2 Username Hardcoded in Multiple Locations
**Severity:** 🟡 **Medium**  
**Files:** Multiple

**Evidence:**
```nix
# flake.nix:112
username = "vino";

# home-configurations/vino/default.nix:156-159
git.settings.user = {
  name = "6FaNcY9";
  email = "29282675+6FaNcY9@users.noreply.github.com";
  signingkey = "FC8B68693AF4E0D9DC84A4D3B872E229ADE55151";
};
```

**Impact:**
- Username "vino" is hardcoded in top-level flake, limiting multi-user setups
- Git identity is user-specific but mixed with general home configuration
- New users must modify flake.nix directly

**Recommendation:**
1. Move user-specific settings to per-user home configs
2. Create `home-configurations/<username>/identity.nix` for git/email/GPG
3. Current structure is reasonable for single-user laptop; document pattern for multi-user setups

**Effort:** Low (1 hour)  
**Priority:** Document as known limitation

---

### 2. Operational Issues

#### 2.1 Update Automation Creates Dirty Tree
**Severity:** 🔴 **High**  
**File:Line:** `nixos-modules/services.nix:28-42`

**Evidence:**
```nix
# nixos-modules/services.nix:31-33
# Abort if repoRoot is dirty (KISS safety)
${pkgs.util-linux}/bin/runuser -u ${username} -- \
  ${pkgs.git}/bin/git -C ${repoRoot} diff --quiet

# nixos-modules/services.nix:35-37
# Update flake.lock as the user
${pkgs.util-linux}/bin/runuser -u ${username} -- \
  ${pkgs.nix}/bin/nix flake update
```

**Impact:**
- `nix flake update` modifies `flake.lock` → creates dirty tree
- Next run of service aborts with "dirty tree" error (line 32-33 check)
- Service becomes self-blocking after first successful run
- Workaround: Service is currently disabled (line 49: `# wantedBy = ["timers.target"]`)

**Root Cause:**
Logic flaw: dirty-check happens *before* flake.lock modification, but flake.lock becomes dirty for subsequent runs

**Recommendation:**
Two options:
1. **Auto-commit approach:** Add auto-commit after update:
   ```bash
   git add flake.lock
   git commit -m "chore: automated flake update [skip ci]"
   ```
2. **Stash-based approach:** Stash changes before check, pop after:
   ```bash
   git stash -u
   nix flake update
   git add flake.lock
   git stash pop
   ```

**Effort:** Low (1 hour)  
**Priority:** Fix before re-enabling automation

---

#### 2.2 No Garbage Collection Automation
**Severity:** 🟡 **Medium**  
**File:Line:** `nixos-modules/core.nix:85,88`

**Evidence:**
```nix
# nixos-modules/core.nix:84-88
# Use nh's cleaner to avoid double GC scheduling.
gc.automatic = lib.mkDefault false;

# Store optimisation disabled (run manually: sudo nix-store --optimise)
optimise.automatic = false;
```

**Impact:**
- `/nix/store` grows unbounded (laptop disk space concern)
- Manual intervention required: `nh clean all --keep 5`
- Store optimization disabled, missing deduplication savings (typically 10-30% space)

**Context:**
- Comment indicates intentional choice: defer to nh's cleaner
- `nh` clean config exists at line 132-134 but doesn't run automatically
- Core.nix:65 also disables `auto-optimise-store` (inline optimization)

**Recommendation:**
1. Enable nh automatic cleaning with conservative settings:
   ```nix
   clean = {
     enable = true;
     dates = "weekly";
     extraArgs = "--keep-since 7d --keep 5";
   };
   ```
2. Consider enabling `gc.automatic = true` with `gc.dates = "weekly"` as fallback
3. Document manual optimization command in README

**Effort:** Low (30 minutes)  
**Priority:** Medium (disk space management for laptops)

---

### 3. Security and Secrets Management

#### 3.1 GPG Key Split-Brain Configuration
**Severity:** 🟡 **Medium**  
**Files:** `home-configurations/vino/default.nix:159`, `home-modules/secrets.nix:67-71`

**Evidence:**
```nix
# home-configurations/vino/default.nix:159 - Hardcoded key
signingkey = "FC8B68693AF4E0D9DC84A4D3B872E229ADE55151";

# home-modules/secrets.nix:67-71 - Key imported from sops secret
home.activation.importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" "reloadSystemd" ] ''
  SECRET_PATH="${config.sops.secrets.gpg_signing_key.path}"
  if [ -f "$SECRET_PATH" ]; then
    echo "Importing GPG signing key..."
    $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "$SECRET_PATH" 2>/dev/null
```

**Impact:**
- GPG key ID hardcoded in vino's config (line 159)
- Actual private key imported via sops (secrets.nix:67-71)
- If sops secret uses different key → signing fails silently
- Inconsistency: key ID is "config" but key material is "secret"

**Root Cause:**
Git signing requires key ID in config, but private key should come from secrets. Currently split across two files with no validation.

**Recommendation:**
1. Extract GPG key ID to sops secret or user identity file:
   ```nix
   # secrets/gpg.yaml
   gpg_key_id: FC8B68693AF4E0D9DC84A4D3B872E229ADE55151
   gpg_signing_key: |
     -----BEGIN PGP PRIVATE KEY BLOCK-----
     ...
   ```
2. Reference key ID from sops in git config
3. Add validation: check imported key matches configured signingkey
4. Alternative: Use ssh signing (simpler, no GPG needed): `git config gpg.format ssh`

**Effort:** Low (2 hours)  
**Priority:** Medium (prevents silent signing failures)

---

#### 3.2 Cachix Token Stored in Sops but Not Validated
**Severity:** 🟢 **Low**  
**Files:** `flake-modules/apps.nix:339`, `.sops.yaml`

**Evidence:**
```nix
# flake-modules/apps.nix:339
TOKEN_PATH="$HOME/.config/sops-nix/secrets/cachix_auth_token"

# Check if token exists
if [ ! -f "$TOKEN_PATH" ]; then
  echo "ERROR: Cachix auth token not found at: $TOKEN_PATH"
  exit 1
fi
```

**Impact:**
- Cachix push app checks if token file exists but doesn't validate token format
- Invalid token causes cryptic errors during push
- No check if sops-nix has decrypted secrets successfully

**Recommendation:**
1. Add token validation: check if non-empty and matches expected format
2. Consider using `config.sops.secrets.cachix_auth_token.path` instead of hardcoded path
3. Document token setup in README

**Effort:** Low (30 minutes)  
**Priority:** Low (nice-to-have UX improvement)

---

### 4. Maintainability and Technical Debt

#### 4.1 Non-Interactive Hazards in Apps
**Severity:** 🔴 **High**  
**Files:** `flake-modules/apps.nix:70,99`

**Evidence:**
```nix
# flake-modules/apps.nix:70 - commit app bypasses hooks
git commit --no-verify

# flake-modules/apps.nix:99 - generate-age-key blocks on read
read -p "Generate a new key anyway? This will backup the old one. [y/N] " -n 1 -r
```

**Impact:**
- **Line 70:** `commit` app uses `--no-verify`, skipping pre-commit hooks
  - Pre-commit hook configured (line 21), but commit app bypasses it
  - Inconsistent: qa app runs hooks (line 21), commit skips them
  - Risk: commits can bypass linting/formatting checks
- **Line 99:** `generate-age-key` app uses interactive `read -p`
  - Breaks in CI/automation environments
  - Hangs indefinitely in non-TTY contexts
  - Non-interactive shell strategy violated (per shell_strategy.md)

**Root Cause:**
- Commit app designed for convenience (line 68 comment: "like normal git workflow")
- Age key script written for manual interactive use only

**Recommendation:**
1. **Commit app:** Remove `--no-verify` or add flag to control hook running:
   ```nix
   # Option 1: Run hooks by default
   git commit
   
   # Option 2: Add environment variable control
   ${if NO_VERIFY then "--no-verify" else ""}
   ```
2. **Generate-age-key app:** Add non-interactive flag:
   ```bash
   # Check for --force flag or CI environment
   if [[ "$1" == "--force" ]] || [[ -n "${CI:-}" ]]; then
     # Skip confirmation
   else
     read -p "..."
   fi
   ```

**Effort:** Medium (4 hours for both apps + testing)  
**Priority:** High (breaks automation, violates non-interactive design)

---

#### 4.2 HM Isolation Fragility: osConfig Usage
**Severity:** 🔴 **High**  
**File:Line:** `home-configurations/vino/default.nix:10,17`

**Evidence:**
```nix
# home-configurations/vino/default.nix:10
osConfig ? null,

# home-configurations/vino/default.nix:17
hostName = osConfig.networking.hostName or hostname;
```

**Impact:**
- Home Manager config reads NixOS config via `osConfig`
- Breaks standalone HM deployments (non-NixOS systems)
- Tight coupling: HM changes require understanding NixOS state
- Fallback to `hostname` parameter exists, but pattern encourages osConfig usage

**Context:**
Home Manager best practice: configs should work standalone (macOS, non-NixOS Linux). Using osConfig creates NixOS dependency.

**Recommendation:**
1. **Short-term:** Current code has fallback (`or hostname`) → acceptable for NixOS-only use
2. **Long-term:** Refactor to pass hostname explicitly:
   ```nix
   # Instead of: osConfig.networking.hostName
   # Use: hostname parameter (already passed from ez-configs)
   hostName = hostname;  # Remove osConfig dependency
   ```
3. Document in AGENTS.md: "HM configs are NixOS-coupled, not portable"

**Effort:** Medium (3 hours - requires testing across hosts)  
**Priority:** High if planning non-NixOS deployments; Low if NixOS-only

---

#### 4.3 Latent cfgLib Bug (Missing lib Parameter)
**Severity:** 🟡 **Medium**  
**File:Line:** `flake-modules/_common.nix:10`

**Evidence:**
```nix
# flake-modules/_common.nix:10
cfgLib = import ../lib { inherit pkgs; };

# lib/default.nix:1 - Expects lib parameter
{ lib }:
let
  ...
```

**Impact:**
- `_common.nix` imports `lib/default.nix` with only `pkgs` parameter
- `lib/default.nix` expects `{ lib }` parameter (line 1)
- Currently latent bug: `cfgLib` is defined but never used in flake-modules
- Will cause evaluation error if any flake-module tries to use `cfgLib`

**Root Cause:**
Import mismatch: lib expects `{ lib }`, but caller only passes `{ pkgs }`

**Recommendation:**
1. Fix import in `_common.nix:10`:
   ```nix
   # Option 1: Add lib parameter
   cfgLib = import ../lib { inherit pkgs lib; };
   
   # Option 2: Get lib from pkgs
   cfgLib = import ../lib { lib = pkgs.lib; };
   ```
2. Verify cfgLib is actually used; if not, remove it
3. Add CI test that exercises all flake-modules exports

**Effort:** Low (30 minutes)  
**Priority:** Medium (latent bug, but currently harmless)

---

#### 4.4 Extensive Use of `with` Statements
**Severity:** 🟢 **Low**  
**Files:** 25 files, 55 occurrences

**Evidence:**
```bash
# grep results show:
flake-modules/_common.nix:14: commonDevPackages = with pkgs; [
nixos-modules/core.nix:27: systemPackages = with pkgs; [
home-modules/profiles.nix:38,68,83,103: corePkgs/devPkgs/desktopPkgs/extrasPkgs = with pkgs; [
```

**Impact:**
- `with pkgs;` creates implicit scope, reducing code clarity
- Makes it unclear where identifiers come from (especially in large lists)
- Nix RFC 0110 and community best practices discourage `with`
- Can cause name shadowing bugs in complex expressions

**Context:**
This is a widespread pattern in Nix ecosystem, but modern style prefers explicit `pkgs.package` references. Configuration uses `with` extensively in package lists, which is the least harmful use case.

**Recommendation:**
1. **Current state:** Acceptable for simple package lists
2. **Future improvement:** Migrate to explicit references:
   ```nix
   # Instead of:
   systemPackages = with pkgs; [ git vim curl ];
   
   # Prefer:
   systemPackages = [ pkgs.git pkgs.vim pkgs.curl ];
   ```
3. Priority: low (cosmetic/style issue, no functional impact)

**Effort:** Medium (6 hours - 55 occurrences across 25 files)  
**Priority:** Low (style improvement, not functional bug)

---

#### 4.5 Single `rec` Usage in Overlay
**Severity:** 🟢 **Low**  
**File:Line:** `overlays/default.nix:14`

**Evidence:**
```nix
# overlays/default.nix:14
tree-sitter-cli = prev.rustPlatform.buildRustPackage rec {
  pname = "tree-sitter-cli";
  version = "0.24.4";
  # ...
};
```

**Impact:**
- Single `rec` usage in overlay for tree-sitter-cli package
- `rec` enables self-references but can cause infinite recursion bugs
- In this case: `rec` likely used to reference `pname`/`version` in `src` attribute
- Modern pattern uses explicit attribute references

**Context:**
`rec` is generally discouraged but acceptable for simple package definitions. This is a contained use case (single package overlay).

**Recommendation:**
1. **Current state:** Acceptable for simple package overlay
2. **If refactoring:** Use explicit `let` binding:
   ```nix
   let
     pname = "tree-sitter-cli";
     version = "0.24.4";
   in
   prev.rustPlatform.buildRustPackage {
     inherit pname version;
     # ...
   }
   ```

**Effort:** Low (15 minutes)  
**Priority:** Low (single occurrence, contained scope)

---

#### 4.6 /bin/bash Activation Script Hack
**Severity:** 🟢 **Low**  
**File:Line:** `nixos-modules/core.nix:204-206`

**Evidence:**
```nix
# nixos-modules/core.nix:201-206
# Many third-party scripts use #!/bin/bash shebangs (e.g. Claude Code plugins).
# NixOS doesn't provide /bin/bash by default — only /bin/sh.
environment.shells = [ pkgs.bash ];
system.activationScripts.binbash = lib.stringAfter [ "stdio" ] ''
  ln -sfn ${pkgs.bash}/bin/bash /bin/bash
'';
```

**Impact:**
- Creates `/bin/bash` symlink at system activation
- Workaround for third-party scripts expecting FHS paths
- Not idiomatic NixOS (impure, breaks reproducibility guarantees)
- Comment indicates this is for Claude Code plugins

**Context:**
This is a pragmatic workaround for non-Nix-aware tools. NixOS community has mixed opinions on this pattern. The alternative is patching every script to use `/usr/bin/env bash`.

**Recommendation:**
1. **Current state:** Acceptable as documented workaround
2. **Best practice:** Use `patchShebangs` or wrapper scripts for third-party tools
3. **Alternative:** Set up `programs.bash.shellInit` to teach tools about Nix paths
4. Document this as a "known impurity" for pragmatic reasons

**Effort:** N/A (working as intended, just documenting)  
**Priority:** Low (pragmatic compromise, well-documented)

---

### 5. Configuration and Best Practices

#### 5.1 Multiple allowUnfree Declarations
**Severity:** 🟢 **Low**  
**Files:** `flake.nix:125`, `overlays/default.nix:7`, `home-modules/nixpkgs.nix:5`, `nixos-modules/core.nix:97`

**Evidence:**
```bash
# grep results:
flake.nix:125: config.allowUnfree = true;
overlays/default.nix:7: config.allowUnfree = true;
home-modules/nixpkgs.nix:5: allowUnfree = true;
nixos-modules/core.nix:97: allowUnfree = true;
```

**Impact:**
- `allowUnfree = true` set in 4 different places
- Redundant configuration (only needs to be set once)
- Can cause confusion about where config is actually sourced from
- No functional issue (all declarations agree), but violates DRY

**Root Cause:**
Multiple nixpkgs instances: flake-level, NixOS-level, HM-level, overlay-level. Each needs independent config.

**Recommendation:**
1. **Current state:** Required due to multiple nixpkgs instances
2. **Consolidation (advanced):** Use shared nixpkgs config module:
   ```nix
   # shared-modules/nixpkgs-config.nix
   { config.allowUnfree = true; config.allowAliases = false; }
   
   # Then import in flake.nix, core.nix, nixpkgs.nix
   ```
3. Document why multiple declarations are necessary

**Effort:** Low (1 hour - refactoring + docs)  
**Priority:** Low (cosmetic, no functional impact)

---

#### 5.2 Binary Cache Configuration (Well-Implemented)
**Severity:** ✅ **Not an Issue**  
**File:Line:** `nixos-modules/core.nix:72-81`

**Evidence:**
```nix
# nixos-modules/core.nix:72-81
substituters = [
  "https://cache.nixos.org"
  "https://nix-community.cachix.org"
  "https://vino-nixos-config.cachix.org" # Personal binary cache
];
trusted-public-keys = [
  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  "vino-nixos-config.cachix.org-1:8LFVkzmO/+crLWO0Q3bqWOOamVjScT3v1/PCHPiTiUU="
];
```

**Finding:**
- ✅ Official cache.nixos.org configured
- ✅ Community cache (nix-community.cachix.org) configured
- ✅ Personal cache (vino-nixos-config.cachix.org) configured
- ✅ All public keys properly specified
- ✅ CI workflow (cachix.yml) pushes builds to personal cache

**Recommendation:** No changes needed. This follows best practices.

---

#### 5.3 CI/CD Configuration (Well-Implemented)
**Severity:** ✅ **Not an Issue**  
**Files:** `.github/workflows/check.yml`, `.github/workflows/cachix.yml`

**Finding:**
- ✅ Automated flake check on push/PR (check.yml:55)
- ✅ Format checking with treefmt (check.yml:27)
- ✅ Build verification for NixOS + HM configs (check.yml:85,114)
- ✅ Cachix integration for faster CI (cachix.yml)
- ✅ Disk space management in CI (cachix.yml:14-21,48,57,68)

**Recommendation:** No changes needed. CI setup is comprehensive and follows best practices.

---

## 📋 Implementation Roadmap

### Phase 1: Critical Fixes (Week 1)
1. **Fix hardcoded repoRoot** (Issue 1.1)
   - Make configurable or use runtime detection
   - Test on different paths
2. **Fix update automation dirty tree** (Issue 2.1)
   - Add auto-commit or stash logic
   - Re-enable timer if desired
3. **Fix non-interactive hazards** (Issue 4.1)
   - Remove `--no-verify` from commit app
   - Add `--force` flag to generate-age-key

### Phase 2: High-Priority Improvements (Week 2)
4. **Fix HM isolation** (Issue 4.2)
   - Remove osConfig dependency
   - Test standalone HM deployment
5. **Fix GPG split-brain** (Issue 3.1)
   - Consolidate key management
   - Add validation check

### Phase 3: Medium-Priority Tech Debt (Week 3)
6. **Fix cfgLib import** (Issue 4.3)
   - Add lib parameter to import
7. **Enable GC automation** (Issue 2.2)
   - Configure nh clean automation
8. **Improve username portability** (Issue 1.2)
   - Document multi-user setup pattern

### Phase 4: Low-Priority Polish (Future)
9. **Reduce `with` usage** (Issue 4.4)
   - Gradual migration to explicit references
10. **Consolidate allowUnfree** (Issue 5.1)
    - Extract to shared config module

---

## 📚 Best Practices Comparison

| Practice | Current State | Community Standard | Gap |
|----------|---------------|-------------------|-----|
| **Flakes** | ✅ Full flake-based | Flakes | None |
| **Binary cache** | ✅ Cachix + CI | Cachix or custom | None |
| **Secrets** | ✅ sops-nix + Age | sops-nix or agenix | None |
| **HM integration** | ✅ Standalone configs | Integrated or standalone | None |
| **CI/CD** | ✅ GitHub Actions | GitHub/GitLab CI | None |
| **Dev shells** | ✅ perSystem devshells | direnv + devshell | None |
| **Formatting** | ✅ treefmt + pre-commit | nixpkgs-fmt or alejandra | None |
| **Structure** | ✅ Modular (ez-configs) | Modular (various tools) | None |
| **with usage** | ⚠️ Extensive | Discouraged in RFC 0110 | Style gap |
| **rec usage** | ✅ Single occurrence | Discouraged | Minor |
| **Portability** | ⚠️ Hardcoded paths | Parameterized | Gap |
| **GC automation** | ⚠️ Disabled | Enabled (weekly) | Config gap |

**Overall Assessment:** Configuration follows modern NixOS best practices with strong CI/CD, secrets management, and modular structure. Main gaps are portability (hardcoded paths) and operational concerns (GC automation, update service).

---

## 🎯 Quick Wins (< 2 hours each)

1. **Fix cfgLib import bug** (30 min) - Add `lib` parameter to `_common.nix:10`
2. **Fix update service logic** (1 hour) - Add auto-commit after flake update
3. **Remove --no-verify from commit app** (15 min) - Let pre-commit hooks run
4. **Document repoRoot limitation** (30 min) - Add setup instructions to README
5. **Enable nh clean automation** (30 min) - Set `clean.enable = true` with safe defaults

**Total impact:** Fixes 3 High/Critical issues + 2 Medium issues in ~3.5 hours of work.

---

## 📖 References

- [Nix RFC 0110](https://github.com/NixOS/rfcs/pull/110) - Deprecate `with` statement
- [Home Manager Manual](https://nix-community.github.io/home-manager/) - Standalone deployments
- [sops-nix Documentation](https://github.com/Mic92/sops-nix) - Secrets management patterns
- [Cachix Documentation](https://docs.cachix.org/) - Binary cache best practices
- [NixOS Wiki: Flakes](https://nixos.wiki/wiki/Flakes) - Flake configuration patterns

---

**Document Status:** ✅ Complete  
**Evidence Quality:** 🔬 All issues verified with file:line references  
**Actionability:** ✅ Concrete recommendations with effort estimates
