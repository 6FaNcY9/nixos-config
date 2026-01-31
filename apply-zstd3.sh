#!/usr/bin/env bash
# Apply zstd:3 compression strategy to all BTRFS mounts
# This script handles: commit → rebuild → verification

set -euo pipefail

echo "🔧 Applying zstd:3 Compression Strategy"
echo "======================================="
echo ""

# Step 1: Commit the changes
echo "📝 Step 1: Creating git commit..."
git add nixos-configurations/bandit/default.nix nixos-modules/storage.nix
git commit -m 'perf(filesystems): use zstd:3 compression across all BTRFS mounts

Strategy: Better space savings across entire system
- Changed all subvolumes from compress=zstd:1 to compress=zstd:3
- Documented BTRFS limitation: compression options are shared across
  all subvolumes on the same filesystem (cannot set different levels
  per mount point)
- Added systemd.timers.snapper-timeline.enable = false to properly
  disable hourly snapshots (TIMELINE_CREATE attribute does not work)
- Expected: 5-10% better compression ratio with minimal CPU overhead'

echo "✅ Commit created"
echo ""

# Step 2: Rebuild system
echo "🚀 Step 2: Rebuilding system..."
sudo nixos-rebuild switch --flake .#bandit

echo "✅ System rebuilt"
echo ""

# Step 3: Prompt for reboot
echo "⚠️  Step 3: Reboot Required"
echo "Compression changes require a reboot to take effect."
echo ""
read -p "Reboot now? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔄 Rebooting..."
    sudo reboot
else
    echo "⏸️  Reboot postponed. Run 'sudo reboot' when ready."
    echo ""
    echo "📋 After reboot, verify with:"
    echo "  mount | grep btrfs | grep compress"
    echo ""
    echo "Expected: compress=zstd:3 on all mounts"
fi
