# Next Steps - Comprehensive Improvement Plan

## ✅ **COMPLETED** (Phases 1-3)

### Phase 1: Error Detection & Fixes
- [x] Fixed flake warnings with documentation
- [x] Added statix/deadnix to dev environment
- [x] Created desktop hardening module
- [x] Added secrets validation
- [x] Added GPG key validation warnings

### Phase 2: Code Quality Improvements
- [x] Created helper library (lib/default.nix)
- [x] Refactored i3blocks.nix
- [x] Refactored firefox.nix

### Phase 3: Feature Additions
- [x] Created monitoring module (Prometheus, Grafana)
- [x] Created backup module (Restic)
- [x] Created user systemd services
- [x] Added Go development shell
- [x] Added pentest development shell
- [x] Added database development shell

---

## 🚀 **NEXT PRIORITIES** (Phase 4+)

### **Phase 4: Documentation** (Week 1-2)

#### 4.1 Troubleshooting Guide
**File:** `docs/troubleshooting.md`

**Content:**
- Common build failures and solutions
- NixOS/Home Manager activation errors
- Secrets management issues
- Flake update problems
- Hardware-specific issues (Framework 13)
- Performance optimization tips
- Recovery from broken builds

**Priority:** High - Helps with day-to-day maintenance

#### 4.2 Architecture Documentation
**File:** `docs/architecture.md`

**Content:**
- Design decisions (why ez-configs, why roles)
- Module organization philosophy
- Secret management architecture
- Backup strategy rationale
- Monitoring approach
- Development workflow
- Multi-host strategy

**Priority:** Medium - Onboarding and long-term maintenance

#### 4.3 Module Development Guide
**File:** `docs/adding-modules.md`

**Content:**
- Module structure conventions
- Using `_module.args`
- Option definition best practices
- Integration with ez-configs
- Testing modules
- Examples of different module types

**Priority:** Medium - For extending the configuration

#### 4.4 Disaster Recovery Guide
**File:** `docs/disaster-recovery.md`

**Content:**
- Snapshot restore procedures
- Restic backup restore
- System rebuild from scratch
- Secrets recovery
- Emergency boot procedures
- Rollback strategies

**Priority:** High - Critical for emergencies

---

### **Phase 5: Enhanced Features** (Week 3-4)

#### 5.1 Power Management Automation
**File:** `nixos-modules/roles/laptop-power.nix`

**Features:**
- Auto-switch power profiles based on AC status
- Battery threshold management
- Suspend/hibernate triggers
- Display brightness automation
- CPU governor switching

**Implementation:**
```nix
laptop.power = {
  autoProfile = true;  # Auto-switch on AC/battery
  batteryThreshold = 80;  # Stop charging at 80%
  suspendOnBattery = 20;  # Suspend at 20%
};
```

**Priority:** High - Improves laptop battery life

#### 5.2 Network Management Improvements
**File:** `nixos-modules/network-manager.nix`

**Features:**
- VPN auto-connect profiles
- Network-specific DNS settings
- WiFi priority configuration
- Captive portal handling
- Network location detection

**Priority:** Medium - QoL improvement

#### 5.3 Advanced Monitoring
**Enhance:** `nixos-modules/monitoring.nix`

**Features:**
- Alerting via email/notification
- Custom dashboards for Grafana
- Application-specific exporters
- Log aggregation with Loki
- Metrics retention policies

**Priority:** Medium - Better observability

#### 5.4 Backup Improvements
**Enhance:** `nixos-modules/backup.nix`

**Features:**
- Multiple repository types (S3, B2, SFTP)
- Backup verification automation
- Restore testing
- Bandwidth limiting
- Backup status notifications

**Priority:** Medium - More robust backups

---

### **Phase 6: Module Configuration Options** (Week 5-6)

#### 6.1 Home Manager Module Options
**Files to enhance:**
- `home-modules/shell.nix` - Customize abbreviations, plugins
- `home-modules/i3.nix` - Configurable keybindings, gaps, colors
- `home-modules/polybar.nix` - Customizable modules, fonts, colors
- `home-modules/nixvim.nix` - Configurable plugins, keybindings, LSP

**Example:**
```nix
shell.fish = {
  customAbbreviations = {
    "myabbr" = "my command";
  };
  extraPlugins = [ pkgs.fishPlugins.done ];
};
```

**Priority:** Low - Nice-to-have flexibility

#### 6.2 Desktop Variant Support
**Enhance:** `nixos-modules/desktop.nix`

**Features:**
- Support for other desktop environments (GNOME, KDE, Sway)
- Compositor options
- Display manager configuration
- Session management

**Priority:** Low - Current i3-xfce setup works well

#### 6.3 Granular Package Profiles
**Enhance:** `home-modules/profiles.nix`

**New profiles:**
- `profiles.cli-tools` (separate from core)
- `profiles.media` (ffmpeg, imagemagick, etc.)
- `profiles.security` (nmap, wireshark, etc.)
- `profiles.sysadmin` (ansible, terraform, etc.)
- `profiles.gaming` (steam, wine, etc.)

**Priority:** Low - Current 5 profiles sufficient

---

### **Phase 7: Advanced Automation** (Week 7-8)

#### 7.1 Automated System Updates
**Enhance:** `nixos-modules/services.nix`

**Features:**
- Pre-update validation
- Post-update testing
- Automatic rollback on failure
- Update notifications
- Scheduled update windows

**Priority:** Medium - Reduces manual work

#### 7.2 CI/CD Integration
**File:** `.github/workflows/nixos-ci.yml`

**Features:**
- Automatic flake check on PR
- Build verification
- Format/lint checking
- Auto-update dependencies
- Deploy preview environments

**Priority:** Low - Mainly useful for multi-contributor setups

#### 7.3 Configuration Drift Detection
**File:** `nixos-modules/drift-detection.nix`

**Features:**
- Detect manual system changes
- Report configuration drift
- Suggest fixes
- Auto-remediation options

**Priority:** Low - Advanced use case

---

### **Phase 8: Security Enhancements** (Ongoing)

#### 8.1 Enhanced Desktop Hardening
**Enhance:** `nixos-modules/roles/desktop-hardening.nix`

**Features:**
- AppArmor profiles
- Firejail application sandboxing
- USB device restrictions
- Filesystem encryption enforcement
- Audit logging

**Priority:** High - Security is important

#### 8.2 Secrets Management Improvements
**Features:**
- Secret rotation automation
- Multi-user secret sharing
- Emergency secret recovery
- Secret expiration tracking

**Priority:** Medium - Better secret lifecycle

#### 8.3 Two-Factor Authentication
**Features:**
- 2FA for sudo
- SSH key + 2FA
- Encrypted disk + 2FA
- YubiKey support

**Priority:** Medium - Enhanced security

---

### **Phase 9: Performance Optimization** (Week 9-10)

#### 9.1 Build Performance
**Features:**
- Build caching optimization
- Distributed builds
- Binary cache setup
- Evaluation optimization

**Priority:** Low - Builds are already fast enough

#### 9.2 System Performance
**File:** `docs/performance-tuning.md`

**Topics:**
- Kernel parameters tuning
- I/O scheduler optimization
- Memory management
- CPU scaling
- Disk caching

**Priority:** Low - System already performs well

---

### **Phase 10: Multi-Host Management** (Future)

#### 10.1 Additional Host Types
**Create:**
- `nixos-configurations/server-example/` - Headless server
- `nixos-configurations/desktop-heavy/` - Workstation variant
- `nixos-configurations/minimal/` - Lightweight setup

**Priority:** Low - Single host currently

#### 10.2 Shared Configuration
**Features:**
- Common settings across hosts
- Role-based inheritance
- Host-specific overrides
- Centralized secret management

**Priority:** Low - Useful when adding more hosts

---

## 📋 **RECOMMENDED IMMEDIATE ACTIONS**

1. **Week 1: Documentation**
   - Create `docs/troubleshooting.md` with common issues
   - Create `docs/disaster-recovery.md` with emergency procedures
   - Expand `secrets/README.md` with rotation procedures

2. **Week 2: Power Management**
   - Implement laptop power automation
   - Test battery threshold settings
   - Configure suspend/hibernate triggers

3. **Week 3: Monitoring Enhancements**
   - Set up Grafana dashboards
   - Configure alerting
   - Test backup verification

4. **Week 4: Security Hardening**
   - Review and enhance AppArmor profiles
   - Implement USB restrictions
   - Set up audit logging

5. **Ongoing: Maintenance**
   - Weekly: Check monitoring dashboards
   - Monthly: Verify backups
   - Quarterly: Review and update documentation
   - As needed: Security updates

---

## 🎯 **SUCCESS METRICS**

- **Documentation:** All common issues documented
- **Automation:** <5 min manual work per week
- **Security:** All hardening features enabled
- **Reliability:** >99% uptime, tested recovery
- **Performance:** Build times <2 min, boot <30 sec
- **Maintainability:** Any change requires <30 min

---

## 🔄 **CONTINUOUS IMPROVEMENT CYCLE**

1. **Monitor** - Check dashboards, logs, backups
2. **Identify** - Find issues, inefficiencies, gaps
3. **Prioritize** - High/medium/low based on impact
4. **Implement** - Make changes following conventions
5. **Test** - Verify builds, run checks, test recovery
6. **Document** - Update docs, add troubleshooting
7. **Review** - Weekly/monthly review sessions

---

## 📚 **LEARNING RESOURCES**

- NixOS Manual: https://nixos.org/manual/nixos/stable/
- Home Manager Manual: https://nix-community.github.io/home-manager/
- Nix Pills: https://nixos.org/guides/nix-pills/
- NixOS Wiki: https://nixos.wiki/
- NixOS Discourse: https://discourse.nixos.org/

---

*Last Updated: 2026-01-30*
*Configuration Status: Production Ready ✅*
