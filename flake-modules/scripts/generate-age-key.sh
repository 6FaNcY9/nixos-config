#!/usr/bin/env bash
set -euo pipefail

KEY_DIR="$HOME/.config/sops/age"
KEY_FILE="$KEY_DIR/keys.txt"

echo "Age Key Generation for sops-nix"
echo "=================================="
echo ""

# Check if key already exists
if [ -f "$KEY_FILE" ]; then
	echo "Age key already exists at: $KEY_FILE"
	echo ""
	echo "Current public key:"
	grep "public key:" "$KEY_FILE" || echo "(Could not read public key)"
	echo ""
	echo "To regenerate, backup the existing key manually and delete it, or pass --force."
	echo "This script does not prompt in non-interactive environments."
	exit 1
fi

# Create directory
mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

# Generate new key
echo "Generating new Age key..."
age-keygen -o "$KEY_FILE"
chmod 600 "$KEY_FILE"

echo ""
echo "Age key generated successfully!"
echo ""
echo "Location: $KEY_FILE"
echo ""
echo "Your public key (add this to .sops.yaml):"
echo "-------------------------------------------"
grep "public key:" "$KEY_FILE"
echo "-------------------------------------------"
echo ""
echo "Next steps:"
echo "  1. Add the public key above to .sops.yaml"
echo "  2. Run: sops updatekeys secrets/*.yaml"
echo "  3. Commit the updated secrets"
echo ""
