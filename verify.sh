#!/usr/bin/env bash
# Automated verification for refactoring
# Run after every commit to ensure nothing broke

set -euo pipefail

echo "🔍 Phase 1: Flake checks..."
nix flake check

echo ""
echo "🏗️  Phase 2: Build NixOS configuration..."
nixos-rebuild build --flake .#bandit

echo ""
echo "🏠 Phase 3: Build Home Manager configuration..."
nix build .#homeConfigurations.vino@bandit.activationPackage

echo ""
echo "📦 Phase 4: Check packages build..."
nix build .#packages.x86_64-linux.dev-services
nix build .#packages.x86_64-linux.web-db
nix build .#packages.x86_64-linux.gruvboxWallpaperOutPath

echo ""
echo "🧪 Phase 5: Test devshells..."
nix develop .#web --command echo "web shell OK"
nix develop .#rust --command echo "rust shell OK"
nix develop .#go --command echo "go shell OK"
nix develop .#agents --command echo "agents shell OK"

echo ""
echo "✅ All automated checks passed!"
