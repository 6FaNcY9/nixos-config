#!/usr/bin/env bash
set -euo pipefail

TOKEN_PATH="$HOME/.config/sops-nix/secrets/cachix_auth_token"

echo "Cachix Push Utility"
echo "======================"
echo ""

# Check if token exists
if [ ! -f "$TOKEN_PATH" ]; then
	echo "ERROR: Cachix auth token not found at: $TOKEN_PATH"
	echo ""
	echo "Make sure secrets are activated:"
	echo "  nh home switch"
	exit 1
fi

# Export token for cachix
CACHIX_AUTH_TOKEN=$(cat "$TOKEN_PATH")
export CACHIX_AUTH_TOKEN

echo "Building current system configuration..."
SYSTEM_PATH=$(nix build --no-link --print-out-paths ".#nixosConfigurations.${PRIMARY_HOST}.config.system.build.toplevel" 2>&1 | tail -1)

if [ -z "$SYSTEM_PATH" ]; then
	echo "ERROR: Failed to build system"
	exit 1
fi

echo "Built: $SYSTEM_PATH"
echo ""
echo "Pushing to Cachix cache: $CACHE_NAME"
echo ""

# Push to cachix
cachix push "$CACHE_NAME" "$SYSTEM_PATH"

echo ""
echo "Successfully pushed to $CACHE_NAME!"
echo ""
echo "Your cache URL: https://$CACHE_NAME.cachix.org"
