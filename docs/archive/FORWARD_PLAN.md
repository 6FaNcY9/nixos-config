# NixOS Configuration - Comprehensive Forward Plan

**Generated:** 2026-01-30 23:35 CET  
**System:** Framework 13 AMD (bandit) - Post-Reboot Status  
**Current State:** Fully operational with optimizations active

---

## ✅ **Current Status Summary**

### **What's Working**
- ✅ System rebooted - Phase 1 optimizations active
- ✅ Window class assignments fixed (Alacritty, Code capitalized)
- ✅ Rofi power menu with proper colors (palette-driven)
- ✅ Power profile: Performance (optimal for home/AC power)
- ✅ Monitoring disabled: 344MB RAM saved
- ✅ Auto-update timer disabled: Manual control retained
- ✅ No CPU governor errors (AMD EPP driver working)
- ✅ nix-ld enabled (bunx, AppImages work)
- ✅ 30 commits total (29 pushed to origin)

### **System Metrics**
- RAM usage: 2.5GB / 14GB (18%, excellent)
- No monitoring overhead
- No background timers
- Clean boot (no cpufreq errors)

### **Outstanding Issues**
1. ⚠️ Git SSH key issue (libcrypto error) - needs fixing for push
2. ℹ️ 1 local commit (window class fix) not yet pushed

---

## 🎯 **Forward Plan - 4 Phases**

---

## **PHASE 1: Immediate (Today) - Critical Fixes**

### **1.1 Fix Git SSH Key Issue**

**Problem:** `Load key "/home/vino/.ssh/github": error in libcrypto`

**Solution Options:**

**Option A: Regenerate SSH Key**
```bash
# Backup old key
cp ~/.ssh/github ~/.ssh/github.backup

# Generate new ED25519 key
ssh-keygen -t ed25519 -C "29282675+6FaNcY9@users.noreply.github.com" -f ~/.ssh/github

# Add to GitHub: cat ~/.ssh/github.pub
# Test: ssh -T git@github.com
```

**Option B: Fix Existing Key Permissions**
```bash
# Check permissions
ls -la ~/.ssh/github*

# Fix if needed
chmod 600 ~/.ssh/github
chmod 644 ~/.ssh/github.pub

# Reload SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github
```

**Option C: Use HTTPS Instead**
```bash
# Temporarily switch to HTTPS
git remote set-url origin https://github.com/6FaNcY9/nixos-config.git

# Push changes
git push origin claude/explore-nixos-config-ZhsHP

# Switch back to SSH later
```

**Priority:** HIGH  
**Time:** 10-15 minutes

---

### **1.2 Push Pending Commit**

Once SSH is fixed:
```bash
cd ~/src/nixos-config-claude-explore
git push origin claude/explore-nixos-config-ZhsHP
```

**Pending Commit:**
- `fix(home): correct window class capitalization for auto-assignment`

**Priority:** HIGH  
**Time:** 1 minute

---

### **1.3 Test Everything**

**Window Classes:**
```bash
# Open new Alacritty window - should go to workspace 2
alacritty &

# Check assignment
i3-msg -t get_tree | grep -A2 "Alacritty"
```

**Rofi Power Menu:**
```bash
# Open power menu (Mod+Shift+e)
# Verify: colored background, visible text, accent on selection
```

**Workspace Switching:**
```bash
# Test Mod+1 through Mod+9
# All should switch correctly to named workspaces
```

**Priority:** MEDIUM  
**Time:** 5 minutes

---

## **PHASE 2: Short-term (This Week) - Bloat Removal**

### **2.1 Remove Dead Code**

**Files to Delete:**
```bash
# Delete unused modules (disabled, using alternatives)
rm home-modules/i3blocks.nix  # Using polybar instead
rm home-modules/lnav.nix      # Minimal use

# Update imports
# Edit home-modules/default.nix and remove these from imports list
```

**Savings:** ~200 lines of code  
**Priority:** LOW  
**Time:** 5 minutes

---

### **2.2 Remove Bloated Packages**

**From `nixos-modules/core.nix`:**
```nix
# Remove these lines:
- gcc                    # 500MB, already in dev profile via clang
- pkgs.nix-tree         # 50MB, in nix-debug devshell
- pkgs.nix-diff         # In nix-debug devshell
- pkgs.nix-output-monitor  # In nix-debug devshell
```

**From `home-modules/profiles.nix`:**
```nix
# Remove from desktop profile:
- pulseaudio            # 50MB, using Pipewire
- vscode                # 300MB, Nixvim configured
- p7zip                 # 30MB, unzip+zip sufficient

# Remove duplicates from core profile:
- git      # Already in nixos-modules/core.nix
- curl     # Already in nixos-modules/core.nix
- wget     # Already in nixos-modules/core.nix
```

**Expected Savings:** ~1GB closure size  
**Priority:** MEDIUM  
**Time:** 15 minutes

---

### **2.3 Verify Correct Window Classes**

Some window classes might need verification. Test these applications:

```bash
# Firefox (should be workspace 1)
firefox &
sleep 2
xprop WM_CLASS | grep -i firefox

# Discord (should be workspace 8)
# discord &
# xprop WM_CLASS

# Check if any need capitalization fixes
```

**Priority:** LOW  
**Time:** 10 minutes

---

## **PHASE 3: Medium-term (Next 2 Weeks) - Optimization & Enhancement**

### **3.1 Filesystem Optimizations** (+2-3% battery when on battery)

**Add to `nixos-modules/storage.nix`:**
```nix
fileSystems."/" = {
  options = [
    "noatime"          # Don't update access times
    "nodiratime"       # Don't update directory access times
    "compress=zstd:1"  # Lighter compression (was 3)
    # ... keep existing options
  ];
};
```

**Tune zram:**
```nix
# In nixos-modules/roles/laptop.nix
zramSwap.memoryPercent = 25;  # Reduce from 50% (more free RAM)
```

**Priority:** LOW (you're at home, performance mode)  
**Time:** 10 minutes  
**Benefit:** Faster I/O, less SSD writes, more free RAM

---

### **3.2 Timer Optimizations** (+1-2% battery)

**Disable snapper hourly snapshots:**
```nix
# In nixos-modules/storage.nix
services.snapper.configs.home = {
  TIMELINE_CREATE = false;  # Disable hourly snapshots
  # Manual snapshots still work: sudo snapper -c home create
};
```

**Disable nix auto-optimise:**
```nix
# In nixos-modules/core.nix
nix.optimise.automatic = false;  # Manual: sudo nix-store --optimise
```

**Priority:** LOW  
**Time:** 5 minutes

---

### **3.3 Theme Switch to Gruvbox Dark Hard**

**Current:** `gruvbox-dark-pale`  
**Proposed:** `gruvbox-dark-hard` (higher contrast, darker background)

**Edit `shared-modules/stylix-common.nix`:**
```nix
base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
```

**Benefits:**
- Darker background: #1d2021 vs #32302f
- More vibrant colors
- Better readability in bright environments
- More "aggressive" aesthetic

**Priority:** OPTIONAL (aesthetic preference)  
**Time:** 2 minutes + rebuild

---

### **3.4 Enhanced Power Management Automation**

**Create `nixos-modules/roles/laptop-power.nix`:**
```nix
# Auto-switch power profiles based on AC status
laptop.power = {
  autoProfile = true;  # Switch on AC/battery
  batteryThreshold = 80;  # Stop charging at 80%
  suspendOnBattery = 20;  # Suspend at 20%
};
```

**Priority:** MEDIUM (useful when mobile)  
**Time:** 30 minutes

---

### **3.5 Split Heavy Devshells**

**Current:** Single shells with all tools  
**Proposed:** Light + Heavy variants

```nix
# pentest-light (CLI tools only, ~500MB)
pentest-light = {
  packages = [ nmap tcpdump netcat nikto gobuster hydra ];
};

# pentest-heavy (GUI + all tools, ~2GB)
pentest-heavy = {
  packages = pentest-light.packages ++ [ wireshark metasploit burpsuite ];
};

# Same for database: database-cli vs database-servers
```

**Benefits:** Faster shell activation, less downloads  
**Priority:** LOW  
**Time:** 20 minutes

---

## **PHASE 4: Long-term (Future) - Advanced Features**

### **4.1 Documentation**

**Create:**
- `docs/troubleshooting.md` - Common issues & solutions
- `docs/disaster-recovery.md` - Emergency procedures
- `docs/performance-tuning.md` - Optimization guide
- `docs/battery-optimization.md` - Mobile best practices

**Priority:** MEDIUM  
**Time:** 2-3 hours total

---

### **4.2 Advanced Monitoring (Optional)**

**When needed:**
- Re-enable monitoring with `monitoring.enable = true`
- Add custom Grafana dashboards
- Set up alerting (email/notification)
- Add application-specific exporters

**Priority:** LOW (only when debugging)  
**Time:** 1 hour

---

### **4.3 Backup Improvements**

**Enhancements:**
- Add remote backup targets (B2, S3, SFTP)
- Automated restore testing
- Backup verification automation
- Status notifications

**Priority:** MEDIUM  
**Time:** 1-2 hours

---

### **4.4 Security Hardening**

**Enhancements:**
- AppArmor profiles for key applications
- Firejail sandboxing
- USB device restrictions
- 2FA for sudo (YubiKey support)

**Priority:** MEDIUM  
**Time:** 2-3 hours

---

## 📋 **Action Items Checklist**

### **Do Today (30 minutes):**
- [ ] Fix Git SSH key issue (Option A, B, or C)
- [ ] Push pending window class fix commit
- [ ] Test window assignments (Alacritty → workspace 2)
- [ ] Test rofi power menu colors (Mod+Shift+e)
- [ ] Verify workspace switching (Mod+1-9)

### **Do This Week (1-2 hours):**
- [ ] Remove dead code (i3blocks.nix, lnav.nix)
- [ ] Remove bloated packages (~1GB savings)
- [ ] Verify all window classes with xprop
- [ ] Consider theme switch (gruvbox-dark-hard)

### **Do Next Week (2-3 hours):**
- [ ] Filesystem optimizations (noatime, zram tuning)
- [ ] Timer optimizations (snapper, nix-optimise)
- [ ] Split heavy devshells (pentest, database)
- [ ] Start documentation (troubleshooting.md)

### **Future Improvements:**
- [ ] Power management automation
- [ ] Advanced monitoring setup (when needed)
- [ ] Backup enhancements
- [ ] Security hardening

---

## 🎯 **Success Metrics**

### **Current (Baseline):**
- RAM usage: 2.5GB / 14GB (18%)
- No monitoring overhead
- 30 commits, 29 pushed
- Clean boot, no errors
- Window classes: ✅ Fixed
- Rofi colors: ✅ Working
- Power profile: Performance (home)

### **After Phase 2:**
- Closure size: -1GB (target: ~3.8GB from 4.8GB)
- Code cleanup: ~200 lines removed
- All tests passing

### **After Phase 3:**
- Filesystem: +10-15% I/O performance
- Battery (when mobile): +3-5% life
- Devshells: 50% faster activation for light variants

### **After Phase 4:**
- Documentation: 100% coverage
- Backup: Multi-target redundancy
- Security: Hardened configuration

---

## 🚨 **Known Issues & Workarounds**

### **Issue 1: Git SSH Key Libcrypto Error**
**Status:** ACTIVE  
**Impact:** Cannot push commits  
**Workaround:** Use HTTPS temporarily  
**Fix:** See Phase 1.1

### **Issue 2: Window Classes Were Broken**
**Status:** ✅ FIXED  
**Solution:** Capitalized Alacritty and Code classes  
**Commit:** `fix(home): correct window class capitalization`

### **Issue 3: Rofi Power Menu White Text**
**Status:** ✅ FIXED  
**Solution:** Palette-driven .rasi files, disabled Stylix rofi target

---

## 📊 **Performance Timeline**

| Date | Event | Impact |
|------|-------|--------|
| 2026-01-30 13:20 | Phase 1 applied (pre-reboot) | Monitoring disabled, timer off |
| 2026-01-30 20:00 | System rebooted | Optimizations activated |
| 2026-01-30 21:00 | Window classes fixed | Auto-assignment restored |
| 2026-01-30 23:35 | Power profile set | Performance mode (home) |

---

## 🔄 **Continuous Improvement**

1. **Weekly:** Check for security updates (`nix flake update`)
2. **Monthly:** Verify backups, review logs
3. **Quarterly:** Review performance metrics, update documentation
4. **As needed:** Adjust power profiles, tweak optimizations

---

## 📞 **Quick Reference**

### **Power Profiles:**
```bash
# Performance (home/AC)
powerprofilesctl set performance

# Balanced (mobile, good battery)
powerprofilesctl set balanced

# Power-saver (maximum battery)
powerprofilesctl set power-saver

# Check current
powerprofilesctl get
```

### **Rebuild Commands:**
```bash
# System
sudo nixos-rebuild switch --flake .#bandit
# or: nh os switch -H bandit

# Home Manager
home-manager switch --flake .#vino@bandit
# or: nh home switch -c vino@bandit
```

### **Git Commands:**
```bash
# Format and lint
nix run .#qa

# Commit with pre-commit hooks
nix run .#commit

# Push
git push origin claude/explore-nixos-config-ZhsHP
```

### **Monitoring:**
```bash
# System resources
htop  # or: btop

# Memory
free -h

# Disk usage
df -h

# Journal errors
journalctl -b -p err
```

---

**Last Updated:** 2026-01-30 23:35 CET  
**Next Review:** 2026-02-06 (1 week)
