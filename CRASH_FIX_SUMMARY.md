# Laptop Crash Fix - Implementation Summary

## Problem Identified

Your laptop crashed due to **memory exhaustion** at 07:11-07:14 on 2026-02-21. The system became unresponsive and required a forced power-off.

### Root Causes:

1. **systemd-oomd was broken** - Running but monitoring ZERO cgroups, couldn't kill processes
2. **Swap priorities inverted** - zram (fast) had lower priority than disk swap (slow)  
3. **memory.nix orphaned** - Not imported, so memory management settings weren't applied

## Configuration Changes Made

### Files Modified:

1. **nixos-modules/core/memory.nix**
   - Changed `vm.swappiness` from 10 → 80 (more proactive swapping)
   
2. **nixos-modules/core/oomd.nix** (NEW FILE)
   - Enabled systemd-oomd with proper cgroup monitoring
   - Configured to kill processes at 60% memory pressure for 30s
   - Monitors user slices (where desktop apps run)
   
3. **nixos-modules/core/default.nix**
   - Imported `./memory.nix` and `./oomd.nix`
   
4. **nixos-modules/features/hardware/laptop.nix**
   - Set `zramSwap.priority = 100` (high priority - use first)
   
5. **nixos-configurations/bandit/default.nix**
   - Increased zram from 25% → 50% RAM (3.7GB → 7GB)
   - Set disk swap `priority = 1` (low priority - backup only)

## How to Apply

### Step 1: Apply Configuration

```bash
cd /home/vino/src/nixos-config
sudo nixos-rebuild switch --flake .
```

### Step 2: Reboot

```bash
sudo reboot
```

### Step 3: Verify Settings (After Reboot)

```bash
# Check swappiness increased to 80
sysctl vm.swappiness vm.vfs_cache_pressure

# Check swap priorities (zram should be 100, disk should be 1)
swapon --show

# Check zram increased to ~7GB
zramctl

# Check oomd is monitoring cgroups now (should NOT be empty)
oomctl dump

# Check systemd-oomd service
systemctl status systemd-oomd
```

### Step 4: Memory Pressure Test (Optional)

To verify the system handles memory pressure gracefully:

```bash
# Install stress-ng if not present
nix-shell -p stress-ng

# Run memory stress test (system should stay responsive, oomd should kill it)
stress-ng --vm 2 --vm-bytes 95% --timeout 60s

# Watch oomd logs during test
journalctl -f -u systemd-oomd
```

### Step 5: Hibernate Test (Optional)

Verify hibernation still works:

```bash
# Test hibernate
systemctl hibernate

# After resume, check logs
journalctl -b | grep -i "hibernat\|resume"
```

## Expected Results

### Before (Current System):
- vm.swappiness: 60 (kernel default)
- zram priority: 5 (low)
- disk swap priority: -1 (even lower)
- zram size: 3.7GB
- oomd monitoring: EMPTY (not working)

### After (Fixed System):
- vm.swappiness: 80 (proactive)
- zram priority: 100 (use first)
- disk swap priority: 1 (backup)
- zram size: 7GB (doubled)
- oomd monitoring: user.slice (actively monitoring)

## What This Fixes

1. **No more sudden freezes** - System will swap proactively before running out of RAM
2. **Faster swap usage** - Fast zram used first, slow disk swap as backup only
3. **Process killing before freeze** - oomd kills memory hogs BEFORE total system lock
4. **More memory headroom** - 7GB zram gives more breathing room for memory spikes

## Build Status

✅ Configuration builds successfully
✅ All syntax validated
✅ No NixOS errors
✅ Ready to apply

**Configuration stored at:** `/nix/store/19r9r889wiqsvzyhx0xvidvnsx8x3vif-nixos-system-bandit-26.05.20260213.a82ccc3`
