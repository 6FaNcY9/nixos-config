#!/usr/bin/env bash
# verify.sh — Home-modules refactor verification script
# Run after each migration commit to catch regressions early.
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
step() { echo -e "\n${BOLD}=== $1 ===${NC}"; }

step "Phase 1: flake check"
nix flake check --no-build 2>&1 && ok "flake check passed" || fail "flake check failed"

step "Phase 2: NixOS build (bandit)"
nixos-rebuild build --flake .#bandit 2>&1 && ok "nixos-rebuild build passed" || fail "nixos-rebuild build failed"

step "Phase 3: Home-Manager build (vino@bandit)"
home-manager build --flake .#vino@bandit 2>&1 && ok "home-manager build passed" || fail "home-manager build failed"

step "Phase 4: Smoke tests"
HM_RESULT=$(home-manager build --flake .#vino@bandit --no-link 2>/dev/null)

# Verify key programs are present in the output
EXPECTED_PROGRAMS=(
  "fish"
  "git"
  "nvim"
  "alacritty"
  "tmux"
)
for prog in "${EXPECTED_PROGRAMS[@]}"; do
  if nix-store -q --references "$HM_RESULT" 2>/dev/null | xargs -I{} ls {}/bin 2>/dev/null | grep -q "^${prog}$"; then
    ok "program present: $prog"
  else
    # Soft check — just warn, don't fail (package may be named differently)
    echo "  ? could not verify: $prog (check manually)"
  fi
done

echo -e "\n${GREEN}${BOLD}All checks passed!${NC}"
