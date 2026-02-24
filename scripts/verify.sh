#!/usr/bin/env bash
# scripts/verify.sh — Post-commit regression verification
# Run after migration commits to catch build breakage early.
#
# Usage:
#   bash scripts/verify.sh          # HM build only (fast)
#   bash scripts/verify.sh --nixos  # HM + NixOS system build
#   bash scripts/verify.sh --all    # HM + NixOS + packages + devshells
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; exit 1; }
skip() { echo -e "${YELLOW}–${NC} $* (skipped)"; }
step() { echo -e "\n${BOLD}=== $* ===${NC}"; }

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"
echo "Repository root: ${repo_root}"

BUILD_NIXOS=false
BUILD_ALL=false
for arg in "$@"; do
  case "$arg" in
    --nixos) BUILD_NIXOS=true ;;
    --all)   BUILD_NIXOS=true; BUILD_ALL=true ;;
  esac
done

step "Home Manager build (vino@bandit)"
nix build .#homeConfigurations."vino@bandit".activationPackage --no-link \
  && ok "HM build passed" \
  || fail "HM build failed"

step "NixOS build (bandit)"
if $BUILD_NIXOS; then
  nix build .#nixosConfigurations.bandit.config.system.build.toplevel --no-link \
    && ok "NixOS build passed" \
    || fail "NixOS build failed"
else
  skip "pass --nixos or --all to include NixOS build"
fi

step "Packages"
if $BUILD_ALL; then
  nix build .#packages.x86_64-linux.dev-services --no-link \
    && ok "dev-services passed" || fail "dev-services failed"
  nix build .#packages.x86_64-linux.web-db --no-link \
    && ok "web-db passed" || fail "web-db failed"
  nix build .#packages.x86_64-linux.gruvboxWallpaperOutPath --no-link \
    && ok "gruvboxWallpaperOutPath passed" || fail "gruvboxWallpaperOutPath failed"
else
  skip "pass --all to include package builds"
fi

step "Dev shells"
if $BUILD_ALL; then
  nix develop .#web     --command echo "web shell OK"     && ok "web devshell passed"     || fail "web devshell failed"
  nix develop .#rust    --command echo "rust shell OK"    && ok "rust devshell passed"    || fail "rust devshell failed"
  nix develop .#go      --command echo "go shell OK"      && ok "go devshell passed"      || fail "go devshell failed"
  nix develop .#agents  --command echo "agents shell OK"  && ok "agents devshell passed"  || fail "agents devshell failed"
else
  skip "pass --all to include devshell checks"
fi

echo -e "\n${GREEN}${BOLD}All checks passed!${NC}"
