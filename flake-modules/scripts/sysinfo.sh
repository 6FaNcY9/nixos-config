set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================"
echo "   NixOS Configuration Diagnostics"
echo "================================================"
echo ""

# ========================================
# Hardware Device Detection
# ========================================
echo -e "${BLUE}Hardware Devices${NC}"
echo "--------------------------------------------"

# Battery detection
if BAT_DEVICE=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -type l -printf '%f\n' 2>/dev/null | head -1); then
  if [ -n "$BAT_DEVICE" ]; then
    echo -e "${GREEN}OK${NC} Battery: $BAT_DEVICE"
  else
    echo -e "${YELLOW}--${NC} Battery: Not detected (desktop system?)"
  fi
else
  echo -e "${YELLOW}--${NC} Battery: Not detected (desktop system?)"
fi

# Backlight detection
if BACKLIGHT_DEVICE=$(find /sys/class/backlight -maxdepth 1 -mindepth 1 -type l -printf '%f\n' 2>/dev/null | head -1); then
  if [ -n "$BACKLIGHT_DEVICE" ]; then
    echo -e "${GREEN}OK${NC} Backlight: $BACKLIGHT_DEVICE"
  else
    echo -e "${YELLOW}--${NC} Backlight: Not detected (desktop system?)"
  fi
else
  echo -e "${YELLOW}--${NC} Backlight: Not detected (desktop system?)"
fi

echo ""

# ========================================
# Secrets Management Status
# ========================================
echo -e "${BLUE}Secrets Management${NC}"
echo "--------------------------------------------"

# Age key check
AGE_KEY="$HOME/.config/sops/age/keys.txt"
if [ -f "$AGE_KEY" ]; then
  echo -e "${GREEN}OK${NC} Age key: Present ($AGE_KEY)"
  if AGE_PUB=$(grep "public key:" "$AGE_KEY" 2>/dev/null); then
    echo "  Public: $(echo "$AGE_PUB" | awk '{print $NF}')"
  fi
else
  echo -e "${RED}MISSING${NC} Age key: Missing"
  echo "  Run: nix run .#generate-age-key"
fi

# GPG key check
GPG_KEY="FC8B68693AF4E0D9DC84A4D3B872E229ADE55151"
if gpg --list-secret-keys "$GPG_KEY" >/dev/null 2>&1; then
  echo -e "${GREEN}OK${NC} GPG signing key: Imported ($GPG_KEY)"
else
  echo -e "${YELLOW}--${NC} GPG signing key: Not imported"
  echo "  Key will auto-import on next home-manager activation"
fi

# Secrets directory check
SECRETS_DIR="$HOME/.config/sops-nix/secrets"
if [ -d "$SECRETS_DIR" ]; then
  SECRET_COUNT=$(find "$SECRETS_DIR" -type f -o -type l 2>/dev/null | wc -l)
  if [ "$SECRET_COUNT" -gt 0 ]; then
    echo -e "${GREEN}OK${NC} Decrypted secrets: $SECRET_COUNT available"
  else
    echo -e "${YELLOW}--${NC} Decrypted secrets: Directory exists but empty"
  fi
else
  echo -e "${YELLOW}--${NC} Decrypted secrets: Not yet activated"
  echo "  Run: nh os switch"
fi

echo ""

# ========================================
# Git Repository Status
# ========================================
echo -e "${BLUE}Repository Status${NC}"
echo "--------------------------------------------"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
cd "$repo_root"

# Git status
if git diff-index --quiet HEAD -- 2>/dev/null; then
  echo -e "${GREEN}OK${NC} Git status: Clean"
else
  DIRTY_COUNT=$(git status --porcelain | wc -l)
  echo -e "${YELLOW}--${NC} Git status: $DIRTY_COUNT uncommitted changes"
  echo "  Run: git status"
fi

# Current branch
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
echo "  Branch: $BRANCH"

# Last commit
LAST_COMMIT=$(git log -1 --format="%h - %s" 2>/dev/null || echo "unknown")
echo "  Last commit: $LAST_COMMIT"

echo ""

# ========================================
# System Information
# ========================================
echo -e "${BLUE}System Information${NC}"
echo "--------------------------------------------"

# Hostname
HOSTNAME=$(hostname)
echo "  Hostname: $HOSTNAME"

# NixOS version
if [ -f /etc/os-release ]; then
  NIXOS_VERSION=$(grep "VERSION=" /etc/os-release | cut -d'"' -f2 || echo "unknown")
  echo "  NixOS: $NIXOS_VERSION"
fi

# Current generation
if [ -e /run/current-system ]; then
  CURRENT_GEN=$(readlink /run/current-system | grep -oP 'system-\K[0-9]+-link' || echo "unknown")
  echo "  Generation: $CURRENT_GEN"
fi

echo ""

# ========================================
# Nix Store Status
# ========================================
echo -e "${BLUE}Nix Store Status${NC}"
echo "--------------------------------------------"

# Store size
if STORE_SIZE=$(du -sh /nix/store 2>/dev/null | awk '{print $1}'); then
  echo "  Store size: $STORE_SIZE"
fi

# Check if optimization is beneficial
if command -v nix-store >/dev/null 2>&1; then
  echo "  Optimization: Run 'sudo nix-store --optimise' to deduplicate"
fi

# Generation count
if [ -d /nix/var/nix/profiles ]; then
  GEN_COUNT=$(find /nix/var/nix/profiles -maxdepth 1 -name 'system-*-link' 2>/dev/null | wc -l)
  echo "  Generations: $GEN_COUNT (clean old: nh clean all --keep 5)"
fi

echo ""

# ========================================
# Quick Actions
# ========================================
echo -e "${BLUE}Quick Actions${NC}"
echo "--------------------------------------------"
echo "  Update system: nh os switch"
echo "  Update inputs: nix flake update"
echo "  Run QA checks: nix run .#qa"
echo "  Clean old gens: nh clean all --keep 5"
echo "  Optimize store: sudo nix-store --optimise"
echo ""
