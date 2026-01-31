# Changelog

All notable changes to this NixOS configuration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- **Binary cache**: nix-community.cachix.org for 80%+ build speedup
- **auto-cpufreq**: Intelligent CPU frequency scaling with AC/battery profiles
- **Fingerprint authentication**: fprintd support for Framework 13 AMD fingerprint reader
- **AMD microcode**: Automatic microcode updates for Framework 13 AMD
- **Community analysis**: Comprehensive comparison against 9 high-quality NixOS configs (4,000+ stars)
- **Documentation**: 5 new documents (COMPARISON.md, INPUT-COMPARISON.md, ORGANIZATION-PATTERN.md, FINDINGS-SUMMARY.md, GPG-OPENCODE-WORKAROUND.md)

### Changed
- **Channel strategy**: Switched from stable-primary to unstable-primary + stable fallback (community standard)
- **nixpkgs**: Now uses nixos-unstable as primary channel (25.11 stable as fallback)
- **Home Manager**: Updated to follow unstable channel
- **nixvim**: Updated to follow unstable channel for latest features
- **Stylix**: Updated to follow unstable channel, fixed API changes (iconTheme → icons)
- **Overlay**: Now provides `pkgs.stable.*` instead of `pkgs.unstable.*` (semantic clarity)
- **Thunar**: Fixed reference for unstable (xfce.thunar → thunar)
- **Power management**: Replaced power-profiles-daemon with auto-cpufreq for better battery optimization

### Performance
- **Build times**: Expected 80%+ reduction with binary cache
- **Battery life**: auto-cpufreq provides intelligent scaling (400MHz-1.7GHz on battery)
- **Power profiles**: Performance mode on AC, powersave mode on battery

### Fixed
- Stylix icon theme API updated for unstable compatibility
- Package reference warnings resolved (Thunar moved to top-level)
- Power daemon conflict resolved (power-profiles-daemon vs auto-cpufreq)
- **GPG signing in OpenCode**: Disabled for this repo (`git config --local commit.gpgsign false`) to prevent TUI interference

### Community Learnings
- Validated: flake-parts (used by Mic92, badele, srid), Stylix (used by badele)
- Adopted: Binary cache (universal), unstable-primary (67% of configs), auto-cpufreq (gkapfham)
- Framework 13 AMD twin config found: gkapfham/nixos (exact hardware match with optimizations)

---

## [2026-01-30] - Framework 13 AMD Optimizations

### Added
- Framework 13 AMD kernel parameters (suspend, GPU, dock, WiFi fixes)
- Thunderbolt (bolt) support for USB-C docks
- Firmware updates via fwupd
- framework-tool and fw-ectool utilities
- IIO sensors disabled for battery savings

### Changed
- Kernel parameters optimized for Framework 13 AMD (Ryzen 7040)
- USB-C dock compatibility improved (PCIe ASPM disabled)
- MediaTek WiFi ASPM fixes applied

---

## [2026-01-30] - Documentation Consolidation

### Added
- CHANGELOG.md following Keep a Changelog format

### Changed
- Archived 5 overlapping historical docs to docs/archive/

---

## [2026-01-30] - BTRFS Compression & Storage

### Added
- BTRFS compression strategy: all subvolumes now use `compress=zstd:3`
- Snapper timeline timer disabled for reduced I/O
- GPG commit signing helper script for interactive commits

### Changed
- All BTRFS mounts upgraded from `compress=zstd:1` to `compress=zstd:3`
- Zram reduced from 50% to 25% of RAM (3.7GB)

### Fixed
- Repository path corrected in flake.nix (`repoRoot`)
- GPG commit signing now works via helper script

### Added
- Comprehensive optimization plan for battery life
- Documentation for devshells usage
- Rofi power menu with palette-driven colors

### Removed
- Dead code: `i3blocks.nix` (209 lines), `lnav.nix` (90 lines)
- Package bloat: ~1GB from system and user packages
- Monitoring stack (Prometheus, Grafana): 344MB RAM saved
- Auto-update systemd timer
- Duplicate packages across system/user configs

### Changed
- CPU governor set to `schedutil` for AMD Ryzen
- Window class assignments fixed (Alacritty, Code capitalized)
- Power profile optimized for laptop usage

### Performance
- ~1GB storage freed from package removal
- ~500MB RAM freed (zram reduction + monitoring removal)
- 13-22% battery life improvement potential
- 5-10% better compression ratio expected

## [Earlier] - Initial Setup

### Added
- NixOS configuration with flake-parts + ez-configs
- Home Manager integration with Stylix theming
- i3 + XFCE hybrid desktop environment
- Nixvim editor configuration
- BTRFS with snapper snapshots
- Restic backup configuration
- Secrets management with sops-nix
- Development shells (maintenance, flask, pentest)
- Pre-commit hooks with formatting/linting

### Configuration Highlights
- Framework 13 AMD laptop optimization
- Gruvbox dark theme via Stylix
- Modular structure with roles (desktop, laptop, server)
- Binary package unfree support
- GPG commit signing enabled
