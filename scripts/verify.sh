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

ok() { echo -e "${GREEN}✓${NC} $*"; }
fail() {
	echo -e "${RED}✗${NC} $*"
	exit 1
}
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
	--all)
		BUILD_NIXOS=true
		BUILD_ALL=true
		;;
	esac
done

step "Home Manager build (vino@bandit)"
if nix build .#homeConfigurations."vino@bandit".activationPackage --no-link; then
	ok "HM build passed"
else
	fail "HM build failed"
fi

step "NixOS build (bandit)"
if $BUILD_NIXOS; then
	if nix build .#nixosConfigurations.bandit.config.system.build.toplevel --no-link; then
		ok "NixOS build passed"
	else
		fail "NixOS build failed"
	fi
else
	skip "pass --nixos or --all to include NixOS build"
fi

step "Packages"
if $BUILD_ALL; then
	if nix build .#packages.x86_64-linux.dev-services --no-link; then
		ok "dev-services passed"
	else
		fail "dev-services failed"
	fi
	if nix build .#packages.x86_64-linux.web-db --no-link; then
		ok "web-db passed"
	else
		fail "web-db failed"
	fi
	if nix build .#packages.x86_64-linux.gruvboxWallpaperOutPath --no-link; then
		ok "gruvboxWallpaperOutPath passed"
	else
		fail "gruvboxWallpaperOutPath failed"
	fi
else
	skip "pass --all to include package builds"
fi

step "Dev shells"
if $BUILD_ALL; then
	if nix develop .#web --command echo "web shell OK"; then
		ok "web devshell passed"
	else
		fail "web devshell failed"
	fi
	if nix develop .#rust --command echo "rust shell OK"; then
		ok "rust devshell passed"
	else
		fail "rust devshell failed"
	fi
	if nix develop .#go --command echo "go shell OK"; then
		ok "go devshell passed"
	else
		fail "go devshell failed"
	fi
	if nix develop .#agents --command echo "agents shell OK"; then
		ok "agents devshell passed"
	else
		fail "agents devshell failed"
	fi
else
	skip "pass --all to include devshell checks"
fi

echo -e "\n${GREEN}${BOLD}All checks passed!${NC}"
