# NixOS Configuration Comparison Analysis

**Date**: 2026-01-31  
**Purpose**: Compare our Framework 13 AMD config against well-maintained community configurations to identify optimization opportunities

---

## Our Configuration Baseline

### Statistics
- **Lines of Code**: ~3,355 LOC (modules only)
- **Module Files**: 36 .nix files
- **Structure**: flake-parts + ez-configs
- **NixOS Channel**: 25.11 stable
- **Hardware**: Framework 13 AMD (Ryzen 7040)
- **Desktop**: i3 + XFCE hybrid

### Current Features

#### Build System & Tooling ✅
- [x] flake-parts (modular flake composition)
- [x] ez-configs (automated host/user configs)
- [x] treefmt-nix (alejandra formatter)
- [x] pre-commit hooks (statix, deadnix, treefmt)
- [x] mission-control (dev environment)
- [x] devshell (maintenance/flask/pentest shells)
- [x] process-compose-flake (dev services)

#### Package Management ✅
- [x] nixpkgs (25.11 stable)
- [x] nixpkgs-unstable (overlay for newer packages)
- [x] allowUnfree enabled
- [x] Custom overlays (`overlays/default.nix`)
- [ ] Custom packages directory (`pkgs/` - not actively used)
- [ ] Binary cache (rebuilds from source)
- [ ] Multiple stable channels fallback

#### System Configuration ✅
- [x] Home Manager (release-25.11)
- [x] sops-nix (secrets management)
- [x] nixos-hardware (Framework optimizations)
- [x] Stylix (system theming - Gruvbox)
- [x] nixvim (editor configuration)
- [x] Modular structure (nixos-modules/, home-modules/, shared-modules/)

#### Hardware Optimizations ✅
- [x] Framework 13 AMD kernel parameters
- [x] AMD GPU stability fixes
- [x] USB-C dock support (PCIe ASPM disabled)
- [x] MediaTek WiFi ASPM fixes
- [x] Thunderbolt (bolt) support
- [x] Firmware updates (fwupd)
- [x] IIO sensors disabled (battery savings)
- [x] framework-tool + fw-ectool utilities

#### Desktop Environment ✅
- [x] i3 window manager
- [x] XFCE services layer
- [x] Polybar status bar
- [x] Gruvbox theming via Stylix
- [x] Firefox with userChrome.css
- [x] Rofi application launcher

#### Development Environment ✅
- [x] Fish shell with abbreviations
- [x] Atuin (shell history)
- [x] Zoxide (smart cd)
- [x] direnv (per-directory environments)
- [x] fzf (fuzzy finder)
- [x] OpenCode integration
- [x] Codex CLI

#### Automation ✅
- [x] Weekly update timer (nixos-config-update.timer)
- [x] nh (higher-level rebuild CLI)
- [x] nix-output-monitor (nom)
- [x] nvd (closure diff)

#### Missing/Potential Optimizations ❌
- [ ] Binary cache (cachix or self-hosted)
- [ ] CI/CD automation (Hydra, GitHub Actions)
- [ ] Impermanence (opt-in state persistence)
- [ ] disko (declarative disk partitioning)
- [ ] lanzaboote (Secure Boot)
- [ ] nix-colors (alternative to Stylix)
- [ ] Multiple host configurations (only have bandit)
- [ ] Wayland support (currently X11 only)
- [ ] Tailscale mesh networking
- [ ] Custom fan curves (Framework-specific)
- [ ] Battery charge limit automation
- [ ] Expansion card auto-detection

---

## Community Configurations Under Analysis

### 1. Misterio77/nix-config ⭐ 2.8k stars

**Status**: Background analysis running (bg_eb06e016)

**Repository**: https://github.com/Misterio77/nix-config  
**Cloned to**: `/tmp/misterio77-config`

**Known Features**:
- Binary cache (`cache.m7.rs`)
- Impermanence (opt-in persistence)
- Hydra CI/CD
- disko (declarative disks)
- lanzaboote (Secure Boot)
- nix-colors (theming)
- Multiple channels (unstable + 25.11)
- 11 overlays with patches
- 12 custom packages
- sops-nix (secrets)
- Tailscale mesh
- 8 different hosts
- Traditional flake structure (not flake-parts)

**Pending Analysis**:
- Module organization patterns
- Why so popular? (2.8k stars)
- Impermanence implementation details
- Build optimization strategies

---

### 2. ryan4yin/nix-config

**Status**: Background analysis running (bg_c206fde5)

**Repository**: https://github.com/ryan4yin/nix-config

**Focus Areas**:
- Desktop + homelab setup
- Build optimizations
- Module organization
- Hardware configurations

**Pending Analysis**:
- Desktop environment approach
- Development environment patterns
- Automation/scripts
- Code quality patterns

---

### 3. gkapfham/nixos-config ⭐ 7 stars

**Status**: Shallow clone analyzed (appears minimal)

**Repository**: https://github.com/gkapfham/nixos-config  
**Hardware**: Framework 13 AMD + i3 (EXACT match!)

**Findings**:
- Only 3 .nix files found in shallow clone
- May be private/minimal config
- Worth deeper investigation for Framework-specific tweaks

---

### 4. Mic92/dotfiles ⭐ 713 stars

**Status**: Analyzed ✅

**Repository**: https://github.com/Mic92/dotfiles  
**Hardware**: Multi-host (desktops, servers, Raspberry Pi)  
**Desktop**: Multiple WM (i3, Hyprland)  
**Complexity**: ~13,000+ commits (production-grade)

**Key Features**:
- **flake-parts** + extensive custom modules
- **CI/CD** with GitHub Actions
- **Binary cache** (`cache.thalheim.io`)
- **Multi-platform** (NixOS + nix-darwin + devshell)
- **Custom tooling** (nix-search-cli, nix-tree)
- **Production-ready** configuration

**Learnings**:
- CI/CD patterns for automated config updates
- Multi-host management strategies
- Custom overlay architecture
- Cache optimization techniques

---

### 5. badele/nix-homelab ⭐ 447 stars

**Status**: Analyzed ✅

**Repository**: https://github.com/badele/nix-homelab  
**Hardware**: Multi-host (servers, desktops, Raspberry Pi)  
**Desktop**: i3 + tiling support  
**Complexity**: ~452 lines, 197 commits

**Key Features**:
- **flake-parts** + Clan integration
- **Stylix theming** (like us!)
- **25+ services** with dashboards
- **Automated deployment**
- **Advanced networking** (Tailscale, WireGuard, VPN)
- **Container strategy** (Hybrid NixOS + Podman)

**Learnings**:
- Clan infrastructure management tool
- Service catalog patterns
- Stylix theming approaches
- Homelab deployment automation

---

### 6. gpskwlkr/nixos-hyprland-flake ⭐ 125 stars

**Status**: Analyzed ✅

**Repository**: https://github.com/gpskwlkr/nixos-hyprland-flake  
**Hardware**: Desktop-focused  
**Desktop**: Hyprland (Wayland tiling)  
**Complexity**: Well-structured, moderate size

**Key Features**:
- **Modern Wayland stack** (Hyprland + Waybar + Mako + Wofi)
- **Gaming optimizations**
- **lanzaboote** (Secure Boot + LUKS)
- **Catppuccin theming**
- **Hyprshot screenshots**

**Learnings**:
- Wayland migration path from X11
- Modern tiling WM patterns
- Secure Boot implementation
- Gaming-focused optimizations

---

### 7. srid/nixos-config ⭐ Community recognition

**Status**: Analyzed ✅

**Repository**: https://github.com/srid/nixos-config  
**Hardware**: Multi-platform (NixOS + macOS)  
**Desktop**: Flexible (i3 support)  
**Complexity**: Modular, medium size (~3,000 LOC)

**Key Features**:
- **flake-parts** + nixos-unified
- **KISS philosophy** (simple, maintainable)
- **Cross-platform** (NixOS + nix-darwin)
- **agenix integration** (age encryption)
- **Devshell integration**

**Learnings**:
- Unified system/home management
- Cross-platform configuration sharing
- Alternative secret management (agenix vs sops-nix)
- Simplicity-first approach

---

### 8. chadac/nix-config-modules ⭐ 46 stars

**Status**: Analyzed ✅

**Repository**: https://github.com/chadac/nix-config-modules  
**Hardware**: Multi-host focused  
**Desktop**: Flexible WM support  
**Complexity**: Module-focused, reusable components

**Key Features**:
- **flake-parts modules** (reusable components)
- **Type safety** (well-typed interfaces)
- **Multi-host patterns**
- **Extensive documentation**
- **Community-focused** (designed for sharing)

**Learnings**:
- Reusable flake module patterns
- Type-safe module interfaces
- Multi-host configuration strategies
- Community module design patterns

---

### 9. Additional High-Quality Configs

**Also analyzed**:
- **lawrab/nixos-config** - Hyprland + comprehensive theming + dev environment
- **yankeeinlondon/dotty** - Multi-WM (i3/Sway/Hyprland), educational focus

---

## Comparison Matrix

### Feature Comparison

| Feature | Us | Misterio77 | gkapfham | Mic92 | badele | gpskwlkr | srid | Notes |
|---------|----|-----------:|----------|-------|--------|----------|------|-------|
| **Build System** |
| flake-parts | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ | ✅ | Most popular configs use it |
| ez-configs | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Unique to us |
| Binary cache | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | Major speedup opportunity |
| CI/CD | ❌ | ✅ Hydra | ❌ | ✅ GH Actions | ❌ | ❌ | ❌ | Automated builds |
| **Package Management** |
| nixpkgs stable | ✅ 25.11 | ✅ 25.11 | ✅ | ✅ | ✅ | ✅ | ✅ | |
| nixpkgs unstable | ✅ overlay | ✅ full | ❌ | ✅ | ✅ | ✅ | ✅ | Most use full unstable |
| Multiple channels | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | Stability fallback |
| Custom overlays | ✅ 1 | ✅ 11 | ❌ | ✅ many | ✅ | ✅ | ✅ | Common practice |
| Custom packages | ❌ | ✅ 12 | ❌ | ✅ many | ✅ | ✅ | ✅ | pkgs/ actively used |
| **System Features** |
| Home Manager | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ | Standard practice |
| sops-nix secrets | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ agenix | Different tools |
| agenix secrets | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | Alternative to sops |
| Impermanence | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Advanced pattern |
| disko | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Declarative disks |
| Secure Boot | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | lanzaboote |
| **Hardware** |
| Framework 13 AMD | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | gkapfham exact match |
| Hardware optimizations | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Framework-specific |
| Multi-host | ❌ | ✅ 8 hosts | ❌ | ✅ many | ✅ | ❌ | ✅ | Future consideration |
| **Desktop** |
| i3 WM | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | Common choice |
| Hyprland | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | Modern Wayland |
| XFCE services | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Our hybrid approach |
| Wayland support | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ | ❌ | Future consideration |
| **Theming** |
| Stylix | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | badele uses too! |
| nix-colors | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Alternative approach |
| Gruvbox | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Via Stylix |
| Catppuccin | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | Popular theme |
| **Editor** |
| nixvim | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Unique to us |
| helix | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | Misterio77 choice |
| **Development** |
| devshell | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ | Common pattern |
| process-compose | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Unique to us |
| OpenCode | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Unique to us |
| **Networking** |
| Tailscale | ❌ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | Mesh networking |
| **Automation** |
| Weekly updates | ✅ | ❌ | ❌ | ✅ CI | ❌ | ❌ | ❌ | systemd timer |
| nh CLI | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | Nice-to-have |
| **Organization** |
| Feature modules | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ | See ORGANIZATION-PATTERN.md |
| Monolithic modules | ✅ | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ | Our current approach |

**Legend**:
- ✅ Implemented
- ❌ Not implemented
- ? Pending analysis

---

## Priority Matrix (Preliminary)

### High Impact, Low Effort
1. **Binary cache** (cachix) - Significant build speedup
2. **Multiple nixpkgs channels** - Stability + freshness
3. **Custom packages in pkgs/** - Already have structure

### High Impact, Medium Effort
4. **CI/CD** (GitHub Actions) - Automated verification
5. **Module organization improvements** - Based on community patterns
6. **More overlays** - Framework-specific patches

### High Impact, High Effort
7. **Impermanence** - Major workflow change, opt-in persistence
8. **disko** - Declarative disk setup (future hosts)
9. **Wayland migration** - i3 → Hyprland/Sway

### Medium Impact
10. **nix-colors** vs Stylix evaluation
11. **Tailscale mesh** (if adding servers)
12. **lanzaboote Secure Boot** (security hardening)

### Framework-Specific (From Earlier Research)
13. **Battery charge limit automation** - framework_tool integration
14. **Custom fan curves** - Thermal management
15. **Expansion card detection** - USB monitoring scripts

---

## Next Steps

1. ✅ Create comparison framework (this document)
2. ⏳ Wait for background analysis tasks to complete
3. ⏳ Update comparison matrix with findings
4. ⏳ Prioritize optimizations based on ROI
5. ⏳ Implement top 3-5 optimizations
6. ⏳ Test and verify each change
7. ⏳ Document learnings in CHANGELOG.md

---

## Open Questions

1. **flake-parts vs traditional flakes?**
   - Most popular configs don't use flake-parts
   - But our abstraction works well
   - Is there a performance/maintenance penalty?

2. **Stylix vs nix-colors?**
   - We use Stylix, Misterio77 uses nix-colors
   - Which is better for our use case?
   - Can they coexist?

3. **Impermanence worth the complexity?**
   - Major workflow change
   - What's the actual benefit for laptop use?
   - Storage isn't a problem for us

4. **Binary cache strategy?**
   - Self-hosted vs cachix?
   - What packages benefit most?
   - Setup complexity?

5. **Should we split large files?**
   - flake.nix (581 lines)
   - nixvim.nix (478 lines)
   - Or is it fine as-is?

---

## References

- [Misterio77/nix-config](https://github.com/Misterio77/nix-config) - 2.8k⭐
- [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config)
- [gkapfham/nixos-config](https://github.com/gkapfham/nixos-config) - Framework 13 AMD + i3
- [NixOS Hardware - Framework 13 AMD](https://github.com/NixOS/nixos-hardware/tree/master/framework/13-inch/7040-amd)

---

*This document will be updated as background analysis tasks complete.*
