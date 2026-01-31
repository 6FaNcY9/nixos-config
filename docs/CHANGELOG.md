# Changelog

All notable changes to this NixOS configuration will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

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

## [2026-01-30] - Major Cleanup & Optimization

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
