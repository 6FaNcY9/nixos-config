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

# Run a nix command and report pass/fail with a label.
nix_check() {
	local label="$1"
	shift
	if "$@"; then
		ok "${label} passed"
	else
		fail "${label} failed"
	fi
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}" || fail "Cannot cd to repo root: ${repo_root}"
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
	*) fail "Unknown argument: ${arg}" ;;
	esac
done

step "Home Manager build (vino@bandit)"
nix_check "HM build" \
	nix build .#homeConfigurations."vino@bandit".activationPackage --no-link

step "NixOS build (bandit)"
if $BUILD_NIXOS; then
	nix_check "NixOS build" \
		nix build .#nixosConfigurations.bandit.config.system.build.toplevel --no-link
else
	skip "pass --nixos or --all to include NixOS build"
fi

step "Packages"
if $BUILD_ALL; then
	for pkg in dev-services web-db gruvboxWallpaperOutPath; do
		nix_check "${pkg}" nix build ".#packages.x86_64-linux.${pkg}" --no-link
	done
else
	skip "pass --all to include package builds"
fi

step "Dev shells"
if $BUILD_ALL; then
	for shell in web rust go agents; do
		nix_check "${shell} devshell" \
			nix develop ".#${shell}" --command echo "${shell} shell OK"
	done
else
	skip "pass --all to include devshell checks"
fi

echo -e "\n${GREEN}${BOLD}All checks passed!${NC}"
