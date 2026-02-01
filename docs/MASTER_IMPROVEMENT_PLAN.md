# MASTER IMPROVEMENT PLAN (2025-2026)

## Document Metadata
- Repository: nixos-config
- Generated: 2026-02-01
- Source documents:
- HOME_MODULES_INDEX.md
- MODULES_ANALYSIS.md
- HOME_MODULES_RECOMMENDATIONS.md
- docs/architecture.md
- docs/COMPREHENSIVE-PLAN-2025.md
- Scope: nixos-modules, home-modules, shared-modules, lib, docs, CI/CD, ops
- Repository snapshot: 53 .nix files, well-organized feature layout
- Status: living plan, reviewed quarterly
- Audience: maintainers and future contributors
- Target length: 2000-2500 lines

## How to Use This Plan
- Part 1 establishes the baseline health, strengths, and gaps.
- Part 2 defines priorities and timelines for 2025-2026.
- Part 3 is the execution roadmap with tasks, estimates, and dependencies.
- Part 4 provides implementation playbooks (testing, rollback, validation).
- Part 5 is the quick reference for day-to-day use.
- Appendices provide detailed inventories, backlog, metrics, and definitions.

## Executive Summary
- Overall codebase health is strong and stable, with a weighted score of 7.7/10 (initial) and ~8.0/10 after Week 1-2 quick wins.
- Highest leverage work was short, targeted consistency and documentation cleanup (now completed).
- Structural foundations (architecture, module organization, CI/CD) are solid.
- Immediate focus: complete; next focus shifts to security hardening and multi-host readiness.
- Testing infrastructure is deferred per request (no tests/ folder will be created).
- Medium to long term focus: multi-host support, backup enhancements, Wayland, and impermanence.

## Status Update (2026-02-01)

### Completed Since Initial Plan
- Shell tools reorganized under `home-modules/features/shell/` (fish, git, starship, alacritty)
- i3 directional keybindings extracted into `lib.mkDirectionalBindings`
- Hardcoded `/home/vino` paths replaced with `config.home.homeDirectory`
- `backup.nix` split into `nixos-modules/backup/` submodules
- Sysctl settings centralized in `nixos-modules/security/sysctl.nix`
- Magic numbers documented (polybar intervals, battery thresholds, retention values)
- Module headers added (backup, monitoring, i3, secrets)
- Sudo workflow remains standard (password prompts; no askpass/NOPASSWD overrides)

### Updated Baseline
- Post-quick-wins score: ~8.0/10 (improved organization, portability, documentation)
- Remaining highest-impact gaps:
  - Automated testing infrastructure (Phase 5)
  - Security hardening (AppArmor, USBGuard, audit) (Phase 6)
  - Multi-host support and off-site backups (Phase 7/8)

### Next Phase
- Phase 5: Testing Infrastructure (deferred per request)

## Key Takeaways
- The repository is well-structured and consistent with community patterns.
- Home modules and NixOS modules are both strong but show localized debt.
- The most urgent gaps are testing and security, not basic organization.
- Quick wins can raise the overall rating to ~8.5/10 in under two weeks.
- Multi-host support and off-site backups are the highest medium-term value.
- Wayland and impermanence are high value but higher risk; stage carefully.

## Table of Contents
- Part 1: Current State Assessment (Comprehensive)
- 1.1 Repository Snapshot
- 1.2 Overall Codebase Health Score
- 1.3 Strengths Across All Layers
- 1.4 Weaknesses and Gaps
- 1.5 Technical Debt Quantified
- 1.6 Previous Work Completed (Phases 1-4)
- 1.7 Architecture Summary (Current State)
- 1.8 Repository Structure and Organization
- 1.9 Current Operational Metrics
- 1.10 Constraints and Assumptions
- Part 2: Strategic Priorities (2025-2026)
- 2.1 Prioritization Framework
- 2.2 Immediate Wins (Next 2 Weeks)
- 2.3 Short Term (Month 1-2)
- 2.4 Medium Term (Month 3-4)
- 2.5 Long Term (Month 5-6)
- Part 3: Actionable Roadmap
- 3.1 Immediate Wins Roadmap
- 3.2 Short Term Roadmap
- 3.3 Medium Term Roadmap
- 3.4 Long Term Roadmap
- Part 4: Implementation Guide
- 4.1 Phase Approach
- 4.2 Testing Strategy
- 4.3 Rollback Plans
- 4.4 Validation Checklists
- Part 5: Quick Reference
- 5.1 Top 10 Immediate Actions
- 5.2 Priority Matrix (Impact vs Effort)
- 5.3 Resource Links
- 5.4 Command Cheat Sheet
- Appendices
- Appendix A: Module Inventory (53 .nix files)
- Appendix B: Detailed Scoring Tables
- Appendix C: Technical Debt Backlog
- Appendix D: Risk Register
- Appendix E: Metrics and Targets
- Appendix F: Glossary

---

# Part 1: Current State Assessment (Comprehensive)

## 1.1 Repository Snapshot
- Total .nix files: 53
- Home Manager modules analyzed: 28 modules, 1,983 lines, overall 7.3/10
- NixOS modules analyzed: 15 modules, 1,612 lines, overall 7.2/10
- Shared modules and lib: core helpers and shared palette/workspaces
- Architecture documentation: current and updated (last updated 2026-01-31)
- Comprehensive plan: Phase 4 complete, plan exists for Phases 5-14
- Repo layout is coherent and feature-based, with clear aggregator patterns
- Primary host: Framework 13 AMD laptop (bandit)
- Home Manager user: vino

## 1.2 Overall Codebase Health Score

### Summary
- Overall health score: 7.7/10 (weighted composite)
- Interpretation: stable foundation with a clear improvement path
- Short-term opportunity: raise to ~8.5/10 with <15 hours
- Updated baseline (2026-02-01): ~8.0/10 after Week 1-2 quick wins

### Weighted Score Breakdown
| Area | Score | Weight | Weighted | Notes |
| --- | --- | --- | --- | --- |
| Home Modules | 7.3 | 0.25 | 1.825 | Strong patterns, some duplication and organization gaps |
| NixOS Modules | 7.2 | 0.25 | 1.800 | Solid role system, backup.nix bloat, sysctl duplication |
| Architecture Maturity | 8.2 | 0.15 | 1.230 | Well-documented principles and reasoning |
| Documentation | 8.5 | 0.15 | 1.275 | Phase 4 docs complete, minor gaps remain |
| CI/CD and Tooling | 8.0 | 0.10 | 0.800 | GitHub Actions and flake checks in place |
| Ops Safety (Backups, Secrets) | 7.5 | 0.10 | 0.750 | Good baseline, no off-site backups |
| Total | 7.7 | 1.00 | 7.680 | Weighted composite |

### Score Interpretation
- 9.0-10.0: world-class, highly automated, minimal tech debt
- 8.0-8.9: excellent and robust, mostly automated
- 7.0-7.9: strong and stable, with clear improvements needed
- 6.0-6.9: functional but uneven, multiple foundational gaps

## 1.3 Strengths Across All Layers

### Home Modules Strengths
- Clear module aggregation pattern with default.nix imports
- Palette-driven color system used across desktop and apps
- Device-aware configuration via devices.nix
- Reusable helper functions (mkShellScript, mkWorkspaceBindings)
- Comprehensive Nixvim configuration with 19 LSP servers
- Conditional profile gating with lib.mkIf and profiles.* toggles
- Reasonable file sizes and manageable module count
- Clean modules with no TODOs or dead code
- Stable i3 and polybar configuration patterns

### NixOS Modules Strengths
- Role-based separation (desktop, laptop, server, development)
- Consistent lib.mkIf and mkMerge usage for conditional config
- Strong options definitions in monitoring and backup modules
- Defensive mkDefault usage to preserve override capability
- Clear import ordering (external, shared, core, roles, UI)
- Service configuration grouped per feature, not scattered
- Consistent two-space indentation and readable formatting

### Infrastructure and Ops Strengths
- sops-nix with build-time validation for secrets
- Layered backup strategy (BTRFS snapshots, Restic, generations, Git)
- Stylix for unified theming across system and user apps
- ez-configs for clean host and user aggregation
- treefmt + statix + deadnix for linting and formatting
- GitHub Actions for checks and weekly flake updates

### Documentation Strengths
- Architecture doc explains rationale and tradeoffs
- Clear module organization explanation and usage patterns
- Disaster recovery and backup strategy documented
- Development workflow documented with command sequence
- Multi-host strategy and future architecture outlined

## 1.4 Weaknesses and Gaps

### Home Modules Weaknesses
- Shell tools are scattered instead of grouped under features/shell
- Polybar modules are large (191 lines in one file)
- Keybinding duplication in i3
- Hardcoded user paths and interface names
- Inconsistent package reference styles
- Low comment density (~2% vs 5% ideal)
- Minor inconsistencies in option conventions

### NixOS Modules Weaknesses
- backup.nix is bloated (393 lines, mixed concerns)
- Kernel sysctl duplication across server and hardening roles
- core.nix, storage.nix, desktop.nix lack user-facing options
- Magic numbers and strings without rationale
- Documentation uneven across modules
- Inline shell scripts reduce readability

### Infrastructure Gaps
- No automated testing infrastructure (unit or integration)
- Limited security hardening (no AppArmor, USBGuard, audit rules)
- Single-host configuration (multi-host not yet implemented)
- Backups are local-only (no off-site backup)
- Monitoring disabled on laptop due to battery constraints
- No impermanence (stateful root, potential drift)

### Documentation Gaps
- Missing home-modules README
- Missing OPTIONS.md or documented option conventions
- Kernel parameter explanations inconsistent
- Lack of module audit checklist in docs

## 1.5 Technical Debt Quantified

### Summary
- Total backlog estimate: 49-53 hours
- Quick wins: 12-13 hours
- Medium-term refactors: 14-15 hours
- Longer-term refactors: 23-25 hours

### Home Modules Debt (from analysis)
| Category | Tasks | Estimate | Notes |
| --- | --- | --- | --- |
| Quick Fixes | Package refs, paths, README | 1.5-2.0h | Highest leverage |
| Medium Improvements | Keybinding helper, device options, conventions | 4-5h | Moderate effort |
| Long Refactors | Polybar split, shell reorg, rofi scripts | 6-8h | Structural cleanup |
| Total | 3 categories | 12-15h | Prioritize in first 2 months |

### NixOS Modules Debt (from analysis)
| Category | Tasks | Estimate | Notes |
| --- | --- | --- | --- |
| Priority 1 | Sysctl extraction, options, magic numbers | 6h | Immediate value |
| Priority 2 | backup.nix refactor, security baseline, assertions | 10h | Structural improvements |
| Priority 3 | Move scripts to pkgs, role helpers, docs site | 17h | Optional, long-term |
| Total | 3 categories | 33h | Stage over 3-6 months |

### Debt by Layer
- Home modules: 12-15 hours
- NixOS modules: 33 hours
- Infra and testing: 10-15 hours (new work, not counted above)
- Documentation gaps: 4-6 hours

### Debt by Impact
- High impact, low effort: 10-12 hours
- Medium impact, medium effort: 12-15 hours
- Low impact, high effort: 20-25 hours

### Debt Reduction Trajectory
- Week 1-2: remove 30-40% of known debt
- Month 1-2: remove 60-70% of known debt
- Month 3-4: remove 80-90% of known debt

## 1.6 Previous Work Completed (Phases 1-4)

### Phase 1: Community Best Practices
- Unstable primary with stable fallback overlay implemented
- Binary cache configuration aligned to community standards
- Framework 13 AMD tuning included
- Decision rationale captured in architecture docs

### Phase 2: Code Quality Refactoring
- Monolithic configs split into feature-based modules
- Aggregator default.nix pattern established
- Helper library functions centralized in lib/default.nix
- Clear module boundaries for desktop, editor, and services

### Phase 3: CI/CD Automation
- GitHub Actions configured for formatting and flake checks
- Weekly flake update automation
- Build checks for system and home configurations

### Phase 4: Comprehensive Documentation
- Architecture documentation completed
- Troubleshooting and disaster recovery guides
- Module development conventions documented
- Current doc footprint: 4,274 lines, 96 KB

## 1.7 Architecture Summary (Current State)

### Core Principles
- Declarative configuration over manual setup
- Modularity through feature-based organization
- Community alignment with proven patterns
- Hardware-specific optimizations for Framework 13 AMD
- Defense in depth (snapshots, backups, generations, git)

### Key Architectural Choices
- ez-configs for auto-imported module aggregators
- Role system (desktop, laptop, server) for conditional inclusion
- Stylix for unified theming across system and user apps
- sops-nix for secret management with build-time validation
- Restic for encrypted backups to external storage

### Module Organization Pattern
- Feature-based organization under home-modules/features
- default.nix aggregators define imports per layer
- _module.args provides shared palette and fonts

### Shared Arguments Pattern
- Colors: c and palette passed via _module.args
- Fonts: stylixFonts passed to modules
- Workspaces: shared-modules/workspaces.nix
- i3 package: i3Pkg injected for consistency

### Helper Library Pattern
- Centralized helpers in lib/default.nix
- Validation helpers for secrets
- Shell script generator helpers
- Workspace and color helpers

### Secrets Architecture
- Age key stored in /var/lib/sops-nix/key.txt
- Secrets encrypted under secrets/ via .sops.yaml rules
- Build-time validation ensures encrypted secrets exist
- Decrypted secrets exposed under /run/secrets

### Backup Strategy
- BTRFS snapshots for quick local rollback
- Restic backups to external USB drive
- NixOS generations for config rollback
- Git for source control and remote backup

### Monitoring Approach
- Prometheus/Grafana setup exists but disabled on laptop
- Enhanced journald enabled for minimal overhead
- Plan to re-enable monitoring for server or AC power

### Multi-Host Strategy (Planned)
- Host-specific configs under nixos-configurations/<host>
- Role-based inclusion for shared modules
- Per-host secrets with sops-nix age keys

### Performance Considerations
- Binary caches to reduce build time
- BTRFS compression for space savings
- zram for memory pressure relief
- Power management for laptop battery life

## 1.8 Repository Structure and Organization

### Top-Level Layout (Health)
- flake.nix integrates flake-parts and ez-configs
- nixos-modules for system-level modules
- home-modules for Home Manager modules
- shared-modules for shared palette and workspace list
- lib for helper functions
- docs for architecture and operations

### Organization Assessment
- Feature grouping is consistent and discoverable
- Aggregator pattern reduces boilerplate
- Most modules are under 200 lines and focused

### Home Modules File Structure
- default.nix as entry point for imports
- features/desktop for i3 and polybar
- features/editor for nixvim
- rofi scripts and themes under rofi/

### NixOS Modules File Structure
- core services in core.nix, services.nix, storage.nix
- monitoring and backup as feature modules
- roles under roles/
- desktop configuration under desktop.nix

## 1.9 Current Operational Metrics
- Flake check available and used in CI
- Build time from cache: ~5-10 minutes (from architecture doc)
- Battery life: ~8 hours under current power settings
- Monitoring disabled on battery to reduce drain

## 1.10 Constraints and Assumptions
- Primary host is a laptop with battery constraints
- No dedicated server hardware is currently configured
- Monitoring and heavy services should be AC-gated
- Secrets must remain encrypted at rest and in git

---

# Part 2: Strategic Priorities (2025-2026)

## 2.1 Prioritization Framework
- Impact on stability and safety
- Effort relative to benefits
- Risk reduction per hour spent
- Alignment with architecture principles
- Dependency ordering (foundational before advanced)

### Priority Levels
- P0: critical, start immediately
- P1: high, start within 2 weeks
- P2: medium, start within 1-2 months
- P3: low, start within 3-4 months
- P4: nice to have, ongoing
- P5: future, as time permits

## 2.2 Immediate Wins (Next 2 Weeks)

### Goals
- Raise consistency and reduce local friction
- Improve documentation clarity
- Remove small sources of drift

### Key Tasks (6-7 hours quick wins + 6 hours NixOS P1)
- Normalize package reference style across home modules
- Fix hardcoded paths and interface names
- Add home-modules README and option conventions
- Extract simple keybinding helpers
- Document magic numbers and kernel parameters
- Extract shared sysctl settings to reduce duplication
- Add options for core, storage, and desktop modules

### Expected Outcomes
- Overall rating improves from 7.7 to ~8.5
- Reduced diff churn and easier reviews
- Increased portability across hosts

## 2.3 Short Term (Month 1-2)

### Goals
- Establish testing infrastructure
- Improve security baseline
- Refactor highest-risk modules

### Key Tasks
- Testing infrastructure (Phase 5)
- Security hardening (Phase 6)
- Refactor backup.nix into submodules
- Split polybar modules
- Reorganize shell tools and rofi scripts

### Expected Outcomes
- Automated validation before deployment
- Increased security posture
- Reduced module complexity

## 2.4 Medium Term (Month 3-4)

### Goals
- Enable multi-host support
- Implement off-site backups
- Stabilize desktop structure for scale

### Key Tasks
- Multi-host support (Phase 7)
- Backup enhancements (Phase 8)
- Desktop reorganization completion
- Monitoring toggle for AC or server roles

### Expected Outcomes
- Multi-host builds validated in CI
- 3-2-1 backup rule achieved
- Desktop configuration easier to evolve

## 2.5 Long Term (Month 5-6)

### Goals
- Modernize desktop stack
- Adopt impermanence
- Expand advanced features

### Key Tasks
- Wayland migration (Phase 9)
- Impermanence (Phase 10)
- Advanced monitoring (Phase 11)
- Performance tuning (Phase 12)
- Developer experience improvements (Phase 13)
- Community contributions (Phase 14)

### Expected Outcomes
- Future-proof desktop stack
- Strong reproducibility and drift elimination
- Enhanced observability and performance

---

# Part 3: Actionable Roadmap

## 3.1 Immediate Wins Roadmap (Next 2 Weeks)

### IW-01 Normalize Package References
- Estimate: 0.5 hours
- Dependencies: none
- Scope: home-modules/features/desktop/i3/keybindings.nix
- Scope: home-modules/rofi/rofi.nix
- Scope: home-modules/features/desktop/polybar/modules.nix
- Steps:
- Identify inconsistent package references
- Convert to ${pkgs.X}/bin/Y format
- Update inline command references and wrappers
- Run nix fmt and check diff
- Success metrics:
- All executable references use consistent format
- No hardcoded binary names remain in these modules
- Risk and mitigation:
- Risk: incorrect binary path
- Mitigation: confirm with nix build or path derivation
- Example:
```nix
# BEFORE
terminal = "alacritty";

# AFTER
terminal = "${pkgs.alacritty}/bin/alacritty";
```

### IW-02 Fix Hardcoded Paths
- Estimate: 0.25 hours
- Dependencies: none
- Scope: home-modules/shell.nix
- Steps:
- Search for /home/vino or absolute paths
- Replace with $HOME or config.home.homeDirectory
- Run nix fmt
- Success metrics:
- No /home/vino literals remain
- Paths use home directory variables
- Risk and mitigation:
- Risk: incorrect variable scope
- Mitigation: use config.home.homeDirectory when in Nix
- Example:
```nix
# BEFORE
set -gx PATH /home/vino/.cache/.bun/bin $PATH

# AFTER
set -gx PATH $HOME/.cache/.bun/bin $PATH
```

### IW-03 Add home-modules README
- Estimate: 0.5 hours
- Dependencies: none
- Scope: home-modules/README.md
- Steps:
- Add overview of home-modules structure
- Document feature groups and module entry points
- Include guidance for adding new modules
- Add module list with brief descriptions
- Success metrics:
- README exists and describes structure
- New contributor can find module locations
- Risk and mitigation:
- Risk: module list becomes stale
- Mitigation: keep list short and focus on top-level groups

### IW-04 Document Option Conventions
- Estimate: 0.5 hours
- Dependencies: none
- Scope: home-modules/OPTIONS.md
- Steps:
- Document naming conventions (desktop.i3.*, editor.nixvim.*)
- Include patterns for mkEnableOption and mkOption
- Provide examples for path and enum options
- Reference in README and architecture docs
- Success metrics:
- OPTIONS.md exists with clear conventions
- Option naming consistency improved

### IW-05 Extract i3 Keybinding Helper
- Estimate: 1-2 hours
- Dependencies: IW-01 recommended
- Scope: lib/default.nix
- Scope: home-modules/features/desktop/i3/keybindings.nix
- Steps:
- Implement mkI3Keybindings helper in lib
- Replace duplicated bindings with helper usage
- Compare original and generated bindings
- Run nix fmt and nix eval
- Success metrics:
- Keybinding file reduced and DRY
- No change in behavior
- Risk and mitigation:
- Risk: incorrect bindings mapping
- Mitigation: compare generated bindings to original list
- Example:
```nix
# lib/default.nix
mkI3Keybindings = { mod, directions, arrows ? true }:
  let
    keys = ["j" "k" "l" "semicolon"];
    arrowKeys = ["Left" "Down" "Up" "Right"];
  in
    builtins.listToAttrs (lib.zipListsWith (k: d: {
      name = "${mod}+${k}";
      value = "focus ${d}";
    }) keys directions)
    // (if arrows then builtins.listToAttrs (lib.zipListsWith (k: d: {
      name = "${mod}+${k}";
      value = "focus ${d}";
    }) arrowKeys directions) else {});
```

### IW-06 Add Network Interface Option
- Estimate: 1 hour
- Dependencies: none
- Scope: home-modules/devices.nix
- Scope: home-modules/features/desktop/polybar/modules.nix
- Steps:
- Add devices.networkInterface option to devices.nix
- Update polybar network module to use config.devices.networkInterface
- Provide default empty string and conditional display
- Success metrics:
- No hardcoded interface names in polybar
- Device override works per host
- Example:
```nix
options.devices.networkInterface = lib.mkOption {
  type = lib.types.str;
  default = "";
  description = "Network interface name (e.g., wlp1s0)";
};
```

### IW-07 Document Magic Numbers
- Estimate: 1 hour
- Dependencies: none
- Scope: nixos-modules/backup.nix
- Scope: nixos-modules/storage.nix
- Scope: nixos-modules/roles/laptop.nix
- Steps:
- Identify magic numbers and thresholds
- Add comments explaining rationale
- Convert to options if user-tunable
- Success metrics:
- All thresholds have rationale comments
- Any user-tunable values exposed as options

### IW-08 Document Kernel Parameter Rationale
- Estimate: 1 hour
- Dependencies: none
- Scope: nixos-modules/roles/laptop.nix
- Steps:
- Add comments for each kernel parameter
- Link to known issue references where possible
- Ensure commentary explains why and when
- Success metrics:
- Kernel params fully documented

### IW-09 Extract Shared Sysctl Settings
- Estimate: 2 hours
- Dependencies: none
- Scope: nixos-modules/roles/server.nix
- Scope: nixos-modules/roles/desktop-hardening.nix
- Steps:
- Create nixos-modules/security-sysctl.nix
- Move shared sysctl keys into base module
- Update role modules to import base and add only role-specific keys
- Success metrics:
- Duplicate sysctl keys removed
- Single source of truth for shared sysctl values
- Example:
```nix
options.security.baseHardening.enable = lib.mkEnableOption "base sysctl";
config = lib.mkIf config.security.baseHardening.enable {
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.tcp_syncookies" = 1;
  };
};
```

### IW-10 Add Options to Stateless Modules
- Estimate: 3 hours
- Dependencies: none
- Scope: nixos-modules/core.nix
- Scope: nixos-modules/storage.nix
- Scope: nixos-modules/desktop.nix
- Steps:
- Add options for timezone, locale, devices, DM choice
- Replace hardcoded config values with options
- Provide defaults matching current values
- Update documentation with new options
- Success metrics:
- Modules are configurable without edits
- Default behavior unchanged
- Example:
```nix
options.core.timezone = lib.mkOption {
  type = lib.types.str;
  default = "Europe/Vienna";
  description = "System timezone";
};
config.time.timeZone = config.core.timezone;
```

### IW-11 Add Module Audit Checklist
- Estimate: 0.5 hours
- Dependencies: none
- Scope: docs/module-audit-checklist.md
- Steps:
- Add checklist for module best practices
- Include common pitfalls (mkForce, hardcoded paths)
- Reference in README and architecture docs
- Success metrics:
- Checklist documented and referenced

### IW-12 Nixvim LSP Profiling
- Estimate: 1 hour
- Dependencies: none
- Scope: home-modules/features/editor/nixvim/plugins.nix
- Steps:
- List active LSP servers
- Identify optional vs mandatory servers
- Gate optional servers behind profile toggle
- Success metrics:
- Reduced default LSP set
- Optional servers still available

### Immediate Wins Success Metrics
- 100% of targeted modules updated
- No regressions in desktop or shell behavior
- Documentation coverage increased
- Overall rating rises to ~8.5/10

## 3.2 Short Term Roadmap (Month 1-2)

### ST-01 Testing Infrastructure Skeleton (Phase 5)
- Estimate: 6-8 hours
- Dependencies: none
- Scope: tests/, flake checks
- Steps:
- Create tests/unit/ and tests/integration/
- Add base test for system boot
- Add unit test for lib helpers
- Add checks to flake outputs
- Add minimal CI workflow to run tests
- Success metrics:
- Tests run with nix build .#checks
- At least one unit and one integration test
- Example:
```nix
# tests/unit/lib-helpers.nix
pkgs.runCommand "test-workspaces" {} ''
  ${pkgs.lib.assertMsg (builtins.length workspaces == 9) "Expected 9 workspaces"}
  touch $out
''
```

### ST-02 CI Integration for Tests
- Estimate: 2-3 hours
- Dependencies: ST-01
- Scope: .github/workflows/test.yml
- Steps:
- Add GitHub Actions workflow for tests
- Ensure caching and nix installer steps
- Add checks for unit and integration tests
- Success metrics:
- Tests run on every PR
- CI duration within acceptable limits

### ST-03 AppArmor Baseline (Phase 6)
- Estimate: 6-8 hours
- Dependencies: none
- Scope: nixos-modules/security/apparmor.nix
- Steps:
- Enable AppArmor
- Add baseline profiles for Firefox, Thunar, custom scripts
- Start in complain mode for initial validation
- Review logs and adjust profiles
- Switch to enforce mode for stable profiles
- Success metrics:
- AppArmor enabled without breaking apps
- Profile logs reviewed and adjusted

### ST-04 USBGuard Configuration (Phase 6)
- Estimate: 2-3 hours
- Dependencies: none
- Scope: nixos-modules/security/usb-guard.nix
- Steps:
- Enable USBGuard service
- Define rules for built-in Framework devices
- Add polkit rule for user authorization
- Test device authorization and blocking
- Success metrics:
- Unknown USB devices blocked by default
- User can authorize devices as needed

### ST-05 Audit Logging and Sudo Hardening
- Estimate: 3-4 hours
- Dependencies: none
- Scope: nixos-modules/security/audit.nix
- Scope: nixos-modules/security/sudo.nix
- Steps:
- Enable auditd with core rules
- Add sudo logging and reduced timeout
- Document audit log review steps
- Success metrics:
- auditd enabled and logs created
- sudo logging configured

### ST-06 Refactor backup.nix Into Submodules
- Estimate: 4 hours
- Dependencies: none
- Scope: nixos-modules/backup/
- Steps:
- Create backup/default.nix aggregator
- Split scripts, systemd, udev into separate files
- Ensure imports and options unchanged
- Validate with nix flake check
- Success metrics:
- backup.nix split into focused modules
- No behavioral changes

### ST-07 Split Polybar Modules
- Estimate: 2-3 hours
- Dependencies: IW-06 recommended
- Scope: home-modules/features/desktop/polybar/
- Steps:
- Create modules/ subdir and default.nix
- Split modules.nix into logical files
- Update default.nix to import new modules
- Validate with home-manager build
- Success metrics:
- Each module file < 100 lines
- Behavior unchanged

### ST-08 Reorganize Shell Tools
- Estimate: 2 hours
- Dependencies: IW-03, IW-04 recommended
- Scope: home-modules/features/shell/
- Steps:
- Create features/shell/ with default.nix
- Split fish, git, starship, fzf, direnv, zoxide
- Update home-modules/default.nix
- Validate with home-manager build
- Success metrics:
- Shell tools grouped consistently
- No change in config behavior

### ST-09 Extract Rofi Scripts
- Estimate: 1-2 hours
- Dependencies: IW-01, IW-02 recommended
- Scope: home-modules/rofi/
- Steps:
- Create rofi/scripts/
- Move power/network/clipboard scripts into separate files
- Update rofi.nix to import script modules
- Validate with home-manager build
- Success metrics:
- rofi.nix reduced size
- Scripts are modular and reusable

### Short Term Success Metrics
- CI runs test suite on all PRs
- Security baseline enabled without regressions
- backup.nix refactor reduces file size and improves clarity

## 3.3 Medium Term Roadmap (Month 3-4)

### MT-01 Host Templates (Phase 7)
- Estimate: 4 hours
- Dependencies: ST-01 recommended
- Scope: nixos-configurations/templates/
- Steps:
- Create laptop, server, desktop templates
- Add role toggles and common options
- Document usage
- Success metrics:
- Templates exist and build
- New host can be created in < 15 minutes

### MT-02 Add Second Host
- Estimate: 3-4 hours
- Dependencies: MT-01
- Scope: nixos-configurations/<new-host>/
- Steps:
- Create host default.nix and hardware-configuration
- Add host to flake outputs
- Add host-specific HM override
- Add CI checks for new host
- Success metrics:
- New host builds in CI
- Host uses shared modules without duplication

### MT-03 Per-Host Secrets
- Estimate: 4-6 hours
- Dependencies: MT-01
- Scope: secrets/hosts/, .sops.yaml
- Steps:
- Create age keys per host
- Update .sops.yaml with creation rules
- Move secrets into shared vs host-specific
- Validate secret decryption per host
- Success metrics:
- Secrets decrypt correctly per host
- Host receives only required secrets

### MT-04 Off-Site Backup Repository
- Estimate: 4-6 hours
- Dependencies: ST-06
- Scope: nixos-modules/backup, secrets
- Steps:
- Add cloud repository (B2 or S3)
- Add environment file secret
- Add bandwidth limits and schedule
- Document restore procedure
- Success metrics:
- Cloud backups run weekly
- Local backups remain daily

### MT-05 Backup Verification and Restore Tests
- Estimate: 4-5 hours
- Dependencies: MT-04
- Scope: nixos-modules/backup, tests/
- Steps:
- Add restic check timers
- Create restore test script
- Schedule monthly restore validation
- Document restore logs and alerts
- Success metrics:
- Automated checks run on schedule
- Restore test passes

### MT-06 Monitoring Toggle for AC or Server
- Estimate: 2-3 hours
- Dependencies: none
- Scope: nixos-modules/monitoring.nix
- Steps:
- Add option to enable monitoring only on AC
- Gate monitoring by roles.server or AC power
- Document behavior
- Success metrics:
- Laptop stays in low-power mode on battery
- Monitoring enabled for server or AC

### MT-07 Network Topology Module
- Estimate: 3-4 hours
- Dependencies: MT-01
- Scope: shared-modules/network.nix
- Steps:
- Define host topology and network metadata
- Use to configure host-level settings (optional)
- Document usage and update architecture docs
- Success metrics:
- Network metadata available for hosts
- Minimal duplication of host-specific IPs

### Medium Term Success Metrics
- At least 2 hosts configured from single repo
- Off-site backups running and verified
- Monitoring can be enabled safely on AC or server roles

## 3.4 Long Term Roadmap (Month 5-6)

### LT-01 Wayland Parallel Session (Phase 9)
- Estimate: 6-8 hours
- Dependencies: MT-01 recommended
- Scope: nixos-modules/desktop-wayland.nix
- Steps:
- Add Hyprland and XDG portals
- Enable xwayland for legacy apps
- Add Wayland environment variables
- Document session selection
- Success metrics:
- Hyprland session available at login
- Legacy apps run via XWayland

### LT-02 Waybar Setup
- Estimate: 3-4 hours
- Dependencies: LT-01
- Scope: home-modules/features/desktop/waybar/
- Steps:
- Create Waybar config and styles
- Use Stylix palette for colors
- Mirror Polybar modules where possible
- Document module mapping
- Success metrics:
- Waybar usable with i3-like workflow
- Styling consistent with current theme

### LT-03 Wayland Migration Checklist
- Estimate: 2 hours
- Dependencies: LT-01
- Scope: docs/wayland-migration.md
- Steps:
- Create migration checklist
- Document fallback to i3
- Document known issues
- Success metrics:
- Migration plan documented and actionable

### LT-04 Impermanence Research and VM Testing (Phase 10)
- Estimate: 6-10 hours
- Dependencies: MT-04 recommended
- Scope: nixos-modules/impermanence.nix
- Steps:
- Prototype impermanence in VM
- Identify persistence directories and files
- Document migration plan and rollback
- Success metrics:
- VM boots with tmpfs root
- Persistence list validated

### LT-05 Impermanence Implementation
- Estimate: 8-12 hours
- Dependencies: LT-04
- Scope: hardware-configuration.nix
- Scope: nixos-modules/impermanence.nix
- Steps:
- Add persistence directory list
- Update filesystem mounts
- Rebuild and test on hardware
- Validate secrets and networking
- Success metrics:
- Root is ephemeral and system boots
- Secrets and user data persist

### LT-06 Advanced Monitoring (Phase 11)
- Estimate: 6-8 hours
- Dependencies: MT-06
- Scope: nixos-modules/monitoring-advanced.nix
- Steps:
- Add Loki and Alertmanager
- Add backup and security alerts
- Document dashboards and alerts
- Success metrics:
- Alerts fire for test conditions
- Dashboards present for key metrics

### LT-07 Performance Tuning (Phase 12)
- Estimate: 4-6 hours
- Dependencies: none
- Scope: nixos-modules/performance.nix
- Steps:
- Evaluate powertop recommendations
- Tune I/O scheduler and kernel params
- Document changes and results
- Success metrics:
- Boot time and battery improvements measured

### LT-08 Developer Experience Enhancements (Phase 13)
- Estimate: 6-8 hours
- Dependencies: ST-01
- Scope: devshells, tooling, docs
- Steps:
- Add per-language devShells
- Add pre-commit templates
- Document workflows for new projects
- Success metrics:
- New devShell works in < 2 minutes
- Pre-commit standardization documented

### LT-09 Community Contribution (Phase 14)
- Estimate: 4-6 hours
- Dependencies: none
- Scope: docs, upstream contributions
- Steps:
- Document Framework 13 AMD tuning
- Publish module patterns or blog post
- Upstream small improvements when possible
- Success metrics:
- At least one external contribution or doc published

### Long Term Success Metrics
- Wayland session stable and usable daily
- Impermanence validated and rolled out safely
- Monitoring and performance improvements measured

---

# Part 4: Implementation Guide

## 4.1 Phase Approach

### General Execution Flow
- Step 1: Define acceptance criteria for the phase
- Step 2: Create a feature branch (dev or feature/*)
- Step 3: Implement changes in small, reviewable chunks
- Step 4: Format and lint (nix fmt, statix, deadnix)
- Step 5: Run flake checks and tests
- Step 6: Validate behavior on target host
- Step 7: Document changes and update checklists

### Change Management Principles
- Preserve defaults when adding options
- Use mkDefault for safe overrides
- Avoid mkForce unless explicitly justified
- Prefer small modules over large monoliths
- Document why settings exist, not just what they do

## 4.2 Testing Strategy

### Unit Testing
- Validate helper functions in lib/default.nix
- Use pkgs.runCommand with assertions
- Keep tests deterministic and fast

### Integration Testing
- Use NixOS test framework for system boot
- Add basic service checks for critical services
- Expand tests as features grow

### Home Manager Validation
- Build home activation package
- Use home-manager switch in test environments

### Commands
- nix fmt
- statix check .
- deadnix -f .
- nix flake check
- nix build .#nixosConfigurations.bandit.config.system.build.toplevel
- nix build .#homeConfigurations."vino@bandit".activationPackage

## 4.3 Rollback Plans

### NixOS Generations
- Use nixos-rebuild --rollback for immediate rollback
- Keep older generations until validated

### BTRFS Snapshots
- Create snapper snapshot before risky changes
- Restore files or subvolumes as needed

### Restic Backups
- Verify repository integrity with restic check
- Use restic restore for data recovery

### Git Rollback
- Use git to revert changes when needed
- Keep branches clean and merged after validation

## 4.4 Validation Checklists

### General Checklist
- [ ] nix fmt passes
- [ ] statix check passes
- [ ] deadnix passes
- [ ] nix flake check passes
- [ ] No new hardcoded paths
- [ ] No new magic numbers without documentation
- [ ] Options are typed and documented
- [ ] Modules remain under ~200 lines where feasible

### Phase 5 (Testing) Checklist
- [ ] Unit tests exist for lib helpers
- [ ] Integration test boots system
- [ ] CI runs tests on PRs
- [ ] Test runtime within 10 minutes

### Phase 6 (Security) Checklist
- [ ] AppArmor enabled
- [ ] USBGuard blocks unknown devices
- [ ] auditd running with key rules
- [ ] Sudo logging enabled

### Phase 7 (Multi-Host) Checklist
- [ ] Host templates in place
- [ ] New host builds in CI
- [ ] Per-host secrets configured

### Phase 8 (Backups) Checklist
- [ ] Local + cloud backups configured
- [ ] restic check timers scheduled
- [ ] Restore test documented

### Phase 9 (Wayland) Checklist
- [ ] Hyprland session available
- [ ] Waybar configured
- [ ] XWayland fallback works

### Phase 10 (Impermanence) Checklist
- [ ] /persist mounted and required paths persisted
- [ ] Secrets decrypt after reboot
- [ ] Root is tmpfs

---

# Part 5: Quick Reference

## 5.1 Top 10 Immediate Actions
1. Normalize package references in home modules
2. Fix hardcoded paths in shell configuration
3. Add home-modules/README.md
4. Add home-modules/OPTIONS.md
5. Extract shared sysctl settings
6. Add options to core/storage/desktop modules
7. Document kernel parameter rationale
8. Split polybar modules
9. Refactor backup.nix into submodules
10. Establish testing skeleton in tests/

## 5.2 Priority Matrix (Impact vs Effort)
| Item | Impact | Effort | Priority |
| --- | --- | --- | --- |
| Testing infrastructure | High | Medium | P0 |
| Security hardening | High | High | P0 |
| Sysctl extraction | Medium | Low | P1 |
| Home module quick fixes | Medium | Low | P1 |
| Backup refactor | Medium | Medium | P1 |
| Multi-host support | Medium | Medium | P2 |
| Backup cloud repo | High | Medium | P2 |
| Wayland migration | Medium | High | P3 |
| Impermanence | Medium | High | P3 |
| Advanced monitoring | Low | Medium | P4 |

## 5.3 Resource Links
- NixOS Manual: https://nixos.org/manual/nixos/stable/
- Home Manager Manual: https://nix-community.github.io/home-manager/
- Stylix Documentation: https://github.com/danth/stylix
- sops-nix Documentation: https://github.com/Mic92/sops-nix
- ez-configs Documentation: https://github.com/ehllie/ez-configs
- Impermanence: https://github.com/nix-community/impermanence

## 5.4 Command Cheat Sheet
- Format: nix fmt
- Lint: statix check .
- Dead code: deadnix -f .
- Flake check: nix flake check
- Build system: nix build .#nixosConfigurations.bandit.config.system.build.toplevel
- Build home: nix build .#homeConfigurations."vino@bandit".activationPackage
- System switch: nh os switch -H bandit
- Home switch: nh home switch -c vino@bandit

---

# Appendices

## Appendix A: Module Inventory (53 .nix files)
- flake.nix
- lib/default.nix
- overlays/default.nix
- shared-modules/palette.nix
- shared-modules/stylix-common.nix
- shared-modules/workspaces.nix
- nixos-modules/default.nix
- nixos-modules/core.nix
- nixos-modules/storage.nix
- nixos-modules/services.nix
- nixos-modules/secrets.nix
- nixos-modules/monitoring.nix
- nixos-modules/backup.nix
- nixos-modules/desktop.nix
- nixos-modules/stylix-nixos.nix
- nixos-modules/home-manager.nix
- nixos-modules/roles/default.nix
- nixos-modules/roles/laptop.nix
- nixos-modules/roles/server.nix
- nixos-modules/roles/development.nix
- nixos-modules/roles/desktop-hardening.nix
- nixos-configurations/bandit/default.nix
- nixos-configurations/bandit/hardware-configuration.nix
- home-configurations/vino/default.nix
- home-configurations/vino/hosts/bandit.nix
- home-modules/default.nix
- home-modules/profiles.nix
- home-modules/devices.nix
- home-modules/secrets.nix
- home-modules/shell.nix
- home-modules/git.nix
- home-modules/starship.nix
- home-modules/firefox.nix
- home-modules/alacritty.nix
- home-modules/clipboard.nix
- home-modules/user-services.nix
- home-modules/desktop-services.nix
- home-modules/xfce-session.nix
- home-modules/nixpkgs.nix
- home-modules/rofi/rofi.nix
- home-modules/features/desktop/i3/default.nix
- home-modules/features/desktop/i3/config.nix
- home-modules/features/desktop/i3/keybindings.nix
- home-modules/features/desktop/i3/workspace.nix
- home-modules/features/desktop/i3/autostart.nix
- home-modules/features/desktop/polybar/default.nix
- home-modules/features/desktop/polybar/modules.nix
- home-modules/features/desktop/polybar/colors.nix
- home-modules/features/editor/nixvim/default.nix
- home-modules/features/editor/nixvim/options.nix
- home-modules/features/editor/nixvim/plugins.nix
- home-modules/features/editor/nixvim/keymaps.nix
- home-modules/features/editor/nixvim/extra-config.nix

## Appendix B: Detailed Scoring Tables

### Home Modules Category Scores
| Category | Score | Notes |
| --- | --- | --- |
| Organization | 7/10 | Good hierarchy, shell tools scattered |
| Modularity | 8/10 | Strong aggregator pattern |
| Desktop i3 | 7/10 | Keybinding duplication |
| Desktop Polybar | 6/10 | Large module file |
| Desktop Rofi | 8/10 | Solid script management |
| Editor Nixvim | 8/10 | Comprehensive setup |
| Shell Config | 7/10 | Hardcoded paths |
| Application Configs | 7/10 | Inconsistent options |
| User Services | 8/10 | Clean pattern |
| Code Quality | 7/10 | Low docs, some duplication |
| Overall | 7.3/10 | Well-engineered, clear path |

### NixOS Modules Category Scores
| Criteria | Score | Notes |
| --- | --- | --- |
| Organization | 8/10 | Good role system |
| Config Patterns | 7.5/10 | Some duplication |
| Interdependencies | 7.5/10 | Clear but not optimal |
| Code Quality | 6.5/10 | backup.nix bloat |
| Best Practices | 8/10 | Strong patterns |
| Documentation | 6/10 | Uneven comments |
| Maintainability | 7/10 | OK now, hard to scale |
| Overall | 7.2/10 | Good foundation |

## Appendix C: Technical Debt Backlog

### Home Modules
- Normalize package references (0.5h)
- Fix hardcoded paths (0.25h)
- Add home-modules README (0.5h)
- Add OPTIONS.md (0.5h)
- Extract i3 keybinding helper (1-2h)
- Add devices.networkInterface (1h)
- Add comments to complex modules (1h)
- Split polybar modules (2-3h)
- Reorganize shell tools (2h)
- Extract rofi scripts (1-2h)
- Profile Nixvim LSPs (1-2h)

### NixOS Modules
- Extract shared sysctl settings (2h)
- Add options to core/storage/desktop (3h)
- Document magic numbers (1h)
- Refactor backup.nix into submodules (4h)
- Create security baseline module (3h)
- Add assertions for critical options (3h)
- Move scripts to pkgs/ (5h)
- Role composition helpers (4h)
- Documentation site generation (8h)

## Appendix D: Risk Register
- Risk: Impermanence migration breaks secrets
- Mitigation: persist /var/lib/sops-nix, test in VM
- Risk: AppArmor profiles break apps
- Mitigation: start in complain mode and iterate
- Risk: Wayland migration disrupts workflow
- Mitigation: parallel session and rollback to i3
- Risk: Multi-host secrets leakage
- Mitigation: per-host age keys and sops creation rules
- Risk: Backup cloud costs grow unexpectedly
- Mitigation: prune policies and bandwidth limits

## Appendix E: Metrics and Targets
- Build time from cache: < 5 minutes
- Boot time: < 20 seconds
- Battery life: 10+ hours
- Test coverage: 90% of critical modules
- Backup RTO: < 4 hours
- Multi-host count: 3+ hosts

## Appendix F: Glossary
- ez-configs: flake helper for auto-imported module aggregators
- Stylix: theming module for NixOS and Home Manager
- sops-nix: secrets management with SOPS encryption
- Restic: encrypted backup tool
- BTRFS: snapshot-capable filesystem
- Impermanence: ephemeral root filesystem pattern

## Appendix G: Detailed Phase Playbooks (Phases 5-14)

### Phase 5: Testing Infrastructure (Deferred)
#### Status
- Deferred per request: do not create a `tests/` directory or implement tests.

#### Rationale
- Current workflow relies on manual rebuilds and flake checks.
- Testing can be revisited later if needed.

#### Notes
- If re-enabled in the future, use the NixOS test framework and extend flake checks.
- No test scaffolding should be added until explicitly requested.
- CI runner must have sufficient resources
- Ensure tests do not require secrets

#### Success Metrics
- Unit tests run with nix build .#checks.x86_64-linux.unit-tests
- Integration tests run with nix build .#checks.x86_64-linux.integration-tests
- Tests complete within 10 minutes on CI
- No flaky tests after two weeks of runs
- Regression detection before deployment

#### Risks and Mitigations
- Risk: tests are too slow
- Mitigation: keep integration tests minimal and focused
- Risk: tests are flaky due to timing
- Mitigation: use wait_for_unit and stable checks
- Risk: CI resource limits
- Mitigation: prioritize critical tests and optimize caching

#### Code Examples
```nix
# tests/unit/lib-helpers.nix
{ pkgs, lib, ... }:
let
  cfgLib = import ../../lib { inherit lib; };
  bindings = cfgLib.mkWorkspaceBindings {
    mod = "Mod4";
    workspaces = ["1" "2" "3"];
    commandPrefix = "workspace";
  };
in
pkgs.runCommand "test-workspace-bindings" {} ''
  ${pkgs.lib.assertMsg (builtins.length (builtins.attrNames bindings) == 3)
    "Expected 3 workspace bindings"}
  touch $out
''
```

```nix
# tests/integration/system-boot.nix
import <nixpkgs/nixos/tests/make-test-python.nix> {
  name = "bandit-boot";
  nodes.machine = { ... }: {
    imports = [ ../../nixos-configurations/bandit/default.nix ];
  };
  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("systemctl is-system-running | grep -E 'running|degraded'")
  '';
}
```

#### Validation Checklist
- [ ] tests/unit exists
- [ ] tests/integration exists
- [ ] flake checks include unit tests
- [ ] flake checks include integration tests
- [ ] CI workflow runs tests on PRs
- [ ] Local test instructions documented
- [ ] Tests complete within 10 minutes on CI
- [ ] No tests require secrets
- [ ] Integration tests start from clean state
- [ ] Test results are easy to read

#### Rollout Notes
- Start with a single integration test
- Add one unit test per helper function category
- Keep tests minimal in first iteration
- Expand after stabilizing CI runtime

#### Resources
- NixOS tests manual
- nixpkgs nixos/tests examples
- Mic92/dotfiles tests examples

---

### Phase 6: Security Hardening
#### Goal
- Introduce defense-in-depth for desktop and server roles
- Reduce attack surface and increase visibility
- Maintain usability on a laptop workflow

#### Current Gap
- No mandatory access control (AppArmor or SELinux)
- No USB device policy enforcement
- Minimal audit logging for sensitive files
- Sudo policy is permissive and not audited

#### Key Findings and Inputs
- AppArmor integrates well with NixOS
- USBGuard can protect against rogue USB devices
- auditd provides forensic logging with manageable overhead
- Desktop hardening role already exists and can be extended

#### Scope
- AppArmor baseline profiles for critical apps
- USBGuard rule set for built-in and known devices
- auditd rules for secrets and config changes
- Sudo logging and reduced timeout
- Optional 2FA for sudo (future)

#### Implementation Plan
1. Add security/apparmor.nix module
2. Add security/usb-guard.nix module
3. Add security/audit.nix module
4. Add security/sudo.nix module
5. Enable base hardening role and import modules
6. Start AppArmor in complain mode
7. Collect logs and refine profiles
8. Switch to enforce mode for stable profiles
9. Document opt-out flags for development
10. Add audit log review guidance

#### Task Breakdown
- P6-01: Enable AppArmor with base profiles (4h)
- P6-02: Add custom profiles for Firefox and Thunar (3h)
- P6-03: Enable USBGuard with rules (2h)
- P6-04: Add auditd rules for secrets and config (2h)
- P6-05: Add sudo logging and timeout (1h)
- P6-06: Document security controls (1h)

#### Dependencies and Prerequisites
- AppArmor packages available in nixpkgs
- Known device IDs for USBGuard
- PolicyKit rules for user authorization
- Clean separation between desktop and server roles

#### Success Metrics
- AppArmor enabled and profiles active
- Unknown USB devices blocked by default
- Audit logs record secret access and config changes
- Sudo usage logged and timeout reduced
- No day-to-day workflow regressions

#### Risks and Mitigations
- Risk: AppArmor blocks apps
- Mitigation: complain mode, iterative profile tuning
- Risk: USBGuard blocks needed devices
- Mitigation: allowlist known devices and provide auth tool
- Risk: auditd performance impact
- Mitigation: minimal rule set and rotation

#### Code Examples
```nix
# nixos-modules/security/apparmor.nix
{ config, pkgs, lib, ... }:
{
  options.security.apparmor.enable = lib.mkEnableOption "AppArmor";
  config = lib.mkIf config.security.apparmor.enable {
    security.apparmor.enable = true;
    security.apparmor.packages = [ pkgs.apparmor-profiles ];
  };
}
```

```nix
# nixos-modules/security/usb-guard.nix
{ config, lib, ... }:
{
  services.usbguard = {
    enable = true;
    implicitPolicyTarget = "block";
    rules = ''
      allow with-interface 03:00:00
      allow with-interface 08:06:50
    '';
  };
}
```

#### Validation Checklist
- [ ] AppArmor enabled
- [ ] At least two custom profiles active
- [ ] USBGuard blocks unknown devices
- [ ] auditd logs secrets and config changes
- [ ] sudo logging enabled
- [ ] Documentation updated with opt-out flags

#### Rollout Notes
- Roll out AppArmor in complain mode first
- Collect logs for at least one week
- Switch to enforce mode gradually

#### Resources
- NixOS Security Hardening wiki
- AppArmor profile reference
- USBGuard documentation
- Linux audit framework documentation

---

### Phase 7: Multi-Host Support
#### Goal
- Support multiple host types from a single repository
- Reduce duplication across hosts
- Improve portability and scalability

#### Current Gap
- Only one host (bandit) currently configured
- Host templates not defined
- Per-host secrets not structured
- CI only validates one host

#### Key Findings and Inputs
- Role system already supports conditional inclusion
- ez-configs simplifies host addition
- Secrets architecture supports per-host rules
- Host matrix defined in README and architecture docs

#### Scope
- Host templates for laptop, server, desktop
- Add at least one additional host
- Extend flake outputs for multi-host builds
- Add per-host secrets and SOPS rules

#### Implementation Plan
1. Create host templates under nixos-configurations/templates
2. Define laptop, server, desktop defaults
3. Add a second host with minimal overrides
4. Update flake outputs and checks
5. Add SOPS rules for per-host secrets
6. Document host onboarding process

#### Task Breakdown
- P7-01: Create laptop template (2h)
- P7-02: Create server template (2h)
- P7-03: Create desktop template (2h)
- P7-04: Add second host (3-4h)
- P7-05: Update flake outputs and checks (2h)
- P7-06: Add per-host secrets rules (3h)
- P7-07: Document host onboarding (1h)

#### Dependencies and Prerequisites
- Phase 5 tests recommended for CI validation
- Options added to core modules to reduce hardcoding
- SOPS age keys per host

#### Success Metrics
- At least 2 hosts configured
- CI builds for both hosts
- Shared modules apply cleanly to both hosts
- Per-host secrets decrypt correctly

#### Risks and Mitigations
- Risk: secrets leak to wrong host
- Mitigation: strict SOPS creation rules
- Risk: duplication in host configs
- Mitigation: templates and role usage
- Risk: CI time increases
- Mitigation: stagger checks or cache more aggressively

#### Code Examples
```nix
# nixos-configurations/templates/laptop.nix
{ ... }: {
  roles = {
    desktop = true;
    laptop = true;
    development = true;
  };
  desktop.variant = "i3-xfce";
}
```

```nix
# flake.nix (hosts)
 ezConfigs.nixos.hosts = {
  bandit = { userHomeModules = ["vino"]; };
  server-home = { userHomeModules = ["vino"]; };
 };
```

#### Validation Checklist
- [ ] Templates build standalone
- [ ] New host builds in CI
- [ ] Host-specific overrides are minimal
- [ ] Per-host secrets decrypt successfully
- [ ] Documentation updated

#### Rollout Notes
- Add one host first, then expand
- Use templates for all new hosts

#### Resources
- NixOS multi-host configuration docs
- sops-nix multi-host guidance
- ez-configs documentation

---

### Phase 8: Backup Enhancements
#### Goal
- Achieve 3-2-1 backup strategy
- Add off-site backups and verification
- Automate restore testing

#### Current Gap
- Backups are local-only (USB)
- No verification automation
- No restore testing
- No off-site recovery option

#### Key Findings and Inputs
- Restic supports multiple repositories
- Cloud options: Backblaze B2, Wasabi, S3
- Existing backup.nix module provides base structure
- Architecture doc recommends off-site as future step

#### Scope
- Add cloud repository to backup.nix
- Add restic check timers
- Add restore testing script
- Add backup health monitoring hooks

#### Implementation Plan
1. Add cloud repository configuration
2. Add secrets for cloud credentials
3. Add restic check timers (local weekly, cloud monthly)
4. Add restore test script and timer
5. Document restore procedure
6. Add optional monitoring alerts

#### Task Breakdown
- P8-01: Add cloud repository (4h)
- P8-02: Add cloud secrets and env file (2h)
- P8-03: Add restic check timers (2h)
- P8-04: Add restore testing script (2h)
- P8-05: Document restore procedure (1h)
- P8-06: Add optional monitoring integration (2h)

#### Dependencies and Prerequisites
- Phase 6 security for secrets handling
- Phase 7 multi-host for remote backups (optional)
- backup.nix refactor recommended

#### Success Metrics
- Local backups run daily
- Cloud backups run weekly
- restic check runs on schedule
- Restore test passes monthly
- Documented RTO achieved

#### Risks and Mitigations
- Risk: cloud costs increase
- Mitigation: prune policies, exclude large directories
- Risk: bandwidth constraints
- Mitigation: upload limits and scheduling
- Risk: restore test fails
- Mitigation: alerting and manual verification

#### Code Examples
```nix
backup.repositories.cloud = {
  repository = "b2:nixos-backups:/home";
  passwordFile = config.sops.secrets.restic_password.path;
  environmentFile = config.sops.secrets.backblaze_credentials.path;
  timerConfig.OnCalendar = "weekly";
};
```

```nix
systemd.timers.restic-check-local = {
  timerConfig.OnCalendar = "Sun 03:00";
  timerConfig.Persistent = true;
};
```

#### Validation Checklist
- [ ] Cloud repo initializes successfully
- [ ] Local and cloud backups complete
- [ ] restic check timers run
- [ ] Restore test script runs
- [ ] Restore procedure documented

#### Rollout Notes
- Start with cloud backups weekly
- Increase frequency after stability

#### Resources
- Restic documentation
- Backblaze B2 + Restic guide
- 3-2-1 backup strategy

---

### Phase 9: Desktop Modernization (Wayland)
#### Goal
- Introduce a modern Wayland compositor in parallel to i3
- Improve display scaling, security, and rendering
- Maintain existing workflow during migration

#### Current Gap
- X11-only desktop stack
- No Wayland support for fractional scaling
- No modern Wayland tooling (Waybar, grim, etc)

#### Key Findings and Inputs
- Hyprland or Sway are primary options
- i3 workflow can be replicated in Hyprland
- Waybar replaces Polybar cleanly
- Alacritty already works on Wayland

#### Scope
- Add Wayland session as optional alternative
- Configure Waybar with current status modules
- Ensure rofi-wayland or fuzzel works
- Keep i3 session for fallback

#### Implementation Plan
1. Add desktop-wayland.nix module
2. Enable Hyprland with XWayland support
3. Add Waybar configuration
4. Configure Wayland environment variables
5. Add rofi-wayland or fuzzel
6. Document migration checklist

#### Task Breakdown
- P9-01: Add Hyprland session (3h)
- P9-02: Add Waybar config (3h)
- P9-03: Add Wayland environment variables (1h)
- P9-04: Add Wayland tools (grim, slurp, wl-clipboard) (1h)
- P9-05: Create migration checklist (2h)

#### Dependencies and Prerequisites
- Stable i3 baseline retained
- Stylix palette available for Waybar
- Rofi scripts may need adjustment

#### Success Metrics
- Hyprland session available at login
- Waybar replicates key Polybar info
- All daily apps run under Wayland or XWayland
- No regression in productivity

#### Risks and Mitigations
- Risk: workflow disruption
- Mitigation: parallel session and fallback to i3
- Risk: app incompatibilities
- Mitigation: use XWayland and test list

#### Code Examples
```nix
programs.hyprland.enable = true;
xdg.portal.enable = true;
xdg.portal.wlr.enable = true;
```

```nix
environment.systemPackages = with pkgs; [
  wl-clipboard
  grim
  slurp
  wf-recorder
];
```

#### Validation Checklist
- [ ] Hyprland starts from login manager
- [ ] Waybar renders correctly
- [ ] Screen sharing works
- [ ] Clipboard works
- [ ] Fallback to i3 still available

#### Rollout Notes
- Run Wayland in parallel for at least one week
- Only switch default session after stable usage

#### Resources
- Hyprland documentation
- Waybar wiki
- NixOS Wayland guide

---

### Phase 10: Impermanence
#### Goal
- Implement ephemeral root filesystem
- Persist only explicit state under /persist
- Eliminate configuration drift

#### Current Gap
- Stateful root filesystem
- Drift possible after manual changes
- Limited assurance of reproducibility

#### Key Findings and Inputs
- impermanence module supports persistence mapping
- sops-nix age keys must be persisted
- NetworkManager state should be persisted
- BTRFS subvolume layout required for /persist

#### Scope
- Add impermanence module
- Define persistence directories and files
- Update filesystem mounts
- Provide rollback and migration docs

#### Implementation Plan
1. Add impermanence module to flake
2. Define persistence list for system and user
3. Update hardware-configuration.nix for /persist
4. Test in VM with tmpfs root
5. Roll out to hardware with backups
6. Validate secrets and network persistence

#### Task Breakdown
- P10-01: Add impermanence module (2h)
- P10-02: Define persistence list (3h)
- P10-03: Update filesystem mounts (3h)
- P10-04: VM test (4h)
- P10-05: Hardware rollout (4h)
- P10-06: Document migration and rollback (2h)

#### Dependencies and Prerequisites
- Full backups and snapshots
- Age key backup verified
- Familiarity with BTRFS subvolumes

#### Success Metrics
- Root is tmpfs after reboot
- /persist mounted and required data present
- Secrets decrypt and services start
- No regression in network or user data

#### Risks and Mitigations
- Risk: missing persistence path
- Mitigation: VM testing and incremental rollout
- Risk: secrets fail to decrypt
- Mitigation: persist /var/lib/sops-nix
- Risk: boot failure
- Mitigation: rollback via snapshots and NixOS generation

#### Code Examples
```nix
environment.persistence."/persist" = {
  directories = [
    "/etc/nixos"
    "/var/lib/sops-nix"
    "/var/log"
  ];
  files = [
    "/etc/machine-id"
  ];
};
```

```nix
fileSystems."/" = {
  device = "tmpfs";
  fsType = "tmpfs";
  options = ["defaults" "size=4G" "mode=755"];
};
```

#### Validation Checklist
- [ ] / is tmpfs
- [ ] /persist mounts early
- [ ] Secrets decrypt
- [ ] NetworkManager state persists
- [ ] User home persists

#### Rollout Notes
- Test in VM first
- Use full backups before rollout
- Keep rollback path documented

#### Resources
- impermanence module docs
- NixOS wiki on impermanence
- Erase your darlings article

---

### Phase 11: Advanced Monitoring
#### Goal
- Enable production-grade monitoring when appropriate
- Add alerting for backups and security events
- Provide observability for performance and services

#### Current Gap
- Monitoring disabled on laptop by default
- No alerting or centralized logs
- No backup health monitoring

#### Key Findings and Inputs
- Prometheus and Grafana already configured
- Loki adds log aggregation
- Alertmanager adds notifications
- Monitoring should be role- or AC-gated

#### Scope
- Add Loki and Alertmanager
- Configure alerts for disk, backup, and services
- Document dashboards and alert rules

#### Implementation Plan
1. Add monitoring-advanced.nix module
2. Enable Loki and Alertmanager
3. Add Grafana dashboards for backups and system
4. Add alert rules for critical signals
5. Gate monitoring by roles.server or AC

#### Task Breakdown
- P11-01: Add Loki stack (3h)
- P11-02: Add Alertmanager configuration (2h)
- P11-03: Add backup metrics exporter (2h)
- P11-04: Add alert rules (2h)
- P11-05: Document dashboards and alerts (1h)

#### Dependencies and Prerequisites
- Monitoring base module ready
- AC gating for laptop
- Backup module with metrics

#### Success Metrics
- Dashboards available and populated
- Alerts trigger on test conditions
- Monitoring does not degrade battery life

#### Risks and Mitigations
- Risk: monitoring increases resource usage
- Mitigation: AC gating and low-frequency scraping
- Risk: alert fatigue
- Mitigation: start with critical alerts only

#### Code Examples
```nix
services.loki.enable = true;
services.prometheus.alertmanager.enable = true;
```

```nix
services.prometheus.rules = [
  ''
    groups:
      - name: backup
        rules:
          - alert: BackupNotRun
            expr: time() - restic_backup_timestamp > 172800
  ''
];
```

#### Validation Checklist
- [ ] Loki running
- [ ] Alertmanager running
- [ ] Dashboards available
- [ ] Alerts tested

#### Rollout Notes
- Only enable on server or AC
- Gradually add alerts

#### Resources
- Prometheus docs
- Grafana dashboards
- Loki docs

---

### Phase 12: Performance Tuning
#### Goal
- Improve boot time, battery life, and responsiveness
- Tune kernel and system settings based on real metrics
- Document measurable improvements

#### Current Gap
- Performance tuning is minimal and mostly defaults
- No formal measurement baseline for boot time
- Battery life improvements are incremental

#### Key Findings and Inputs
- powertop and s-tui can identify CPU and power issues
- Kernel parameters already include hardware tweaks
- BTRFS compression reduces disk usage

#### Scope
- Collect baseline metrics
- Tune power management and I/O settings
- Document performance changes

#### Implementation Plan
1. Establish baseline metrics for boot and battery
2. Run powertop and apply recommendations
3. Tune CPU governor and power profiles
4. Evaluate I/O scheduler and filesystem options
5. Document results

#### Task Breakdown
- P12-01: Baseline metrics (1h)
- P12-02: powertop tuning (2h)
- P12-03: CPU governor tuning (1h)
- P12-04: I/O scheduler tuning (1h)
- P12-05: Documentation update (1h)

#### Dependencies and Prerequisites
- Access to battery and usage metrics
- Stable baseline system

#### Success Metrics
- Boot time reduced by measurable amount
- Battery life improved by at least 10%
- No regressions in stability

#### Risks and Mitigations
- Risk: tuning reduces stability
- Mitigation: apply changes incrementally and test
- Risk: tuning reduces performance under load
- Mitigation: measure before and after

#### Code Examples
```nix
powerManagement.powertop.enable = true;
services.power-profiles-daemon.enable = true;
```

```nix
boot.kernelParams = ["amd_pstate=active"];
```

#### Validation Checklist
- [ ] Baseline metrics captured
- [ ] New metrics captured
- [ ] Improvements documented

#### Rollout Notes
- Make changes one at a time
- Capture metrics before and after

#### Resources
- powertop documentation
- NixOS performance tuning wiki

---

### Phase 13: Developer Experience
#### Goal
- Streamline project onboarding
- Improve consistency across development tooling
- Provide reproducible dev environments

#### Current Gap
- Dev tooling is present but not standardized
- devShells exist but not organized per language
- Pre-commit practices vary between projects

#### Key Findings and Inputs
- direnv and nix-direnv already in use
- Nixvim and LSP setup is comprehensive
- devShells can improve reproducibility

#### Scope
- Add per-language devShells
- Add pre-commit templates
- Document project onboarding steps

#### Implementation Plan
1. Create devshells for common languages
2. Add per-language LSP options
3. Document new project workflow
4. Add template for pre-commit hooks
5. Add optional container-based dev envs

#### Task Breakdown
- P13-01: Add devshell for Python (2h)
- P13-02: Add devshell for Rust (2h)
- P13-03: Add devshell for Node (2h)
- P13-04: Add pre-commit template (1h)
- P13-05: Document onboarding (1h)

#### Dependencies and Prerequisites
- Base tooling in nixpkgs
- Consistent module structure

#### Success Metrics
- New project setup under 5 minutes
- devShells build reliably
- Pre-commit template reused across projects

#### Risks and Mitigations
- Risk: devshells become stale
- Mitigation: document update process and automate checks

#### Code Examples
```nix
# flake.nix
 devShells.x86_64-linux.python = pkgs.mkShell {
  packages = [ pkgs.python3 pkgs.poetry pkgs.ruff ];
 };
```

```nix
# pre-commit template
repos:
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v4.6.0
  hooks:
  - id: trailing-whitespace
```

#### Validation Checklist
- [ ] devShells build
- [ ] LSP servers available in devShells
- [ ] Pre-commit template documented

#### Rollout Notes
- Start with two languages and expand

#### Resources
- direnv documentation
- nix-direnv docs
- pre-commit docs

---

### Phase 14: Community Contribution
#### Goal
- Give back to the NixOS community
- Share lessons from Framework 13 AMD setup
- Upstream reusable module improvements

#### Current Gap
- Knowledge remains internal to this repo
- Useful patterns not shared publicly

#### Key Findings and Inputs
- Framework tuning is valuable to others
- Backup and monitoring modules are reusable
- Documentation is already strong and can be adapted

#### Scope
- Publish documentation for Framework 13 AMD setup
- Contribute small improvements upstream
- Write a short blog post or guide

#### Implementation Plan
1. Extract reusable module patterns
2. Write a short public guide or blog
3. Upstream small improvements if practical
4. Share learnings in community forums

#### Task Breakdown
- P14-01: Create public guide (2h)
- P14-02: Publish module patterns (2h)
- P14-03: Upstream one improvement (2h)

#### Dependencies and Prerequisites
- Stable documentation base
- Clean module patterns

#### Success Metrics
- At least one public resource published
- At least one upstream contribution

#### Risks and Mitigations
- Risk: time constraints
- Mitigation: keep scope small and focused

#### Code Examples
```markdown
# Framework 13 AMD NixOS Notes
- Kernel params for stable suspend
- Power profile settings
- WiFi stability fixes
```

#### Validation Checklist
- [ ] Public guide published
- [ ] Community post or contribution completed

#### Rollout Notes
- Focus on one high-value contribution

#### Resources
- NixOS Discourse
- NixOS Wiki contribution guide
