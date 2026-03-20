# Hibernation Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable `systemctl hibernate` on bandit by adding `AllowHibernation=yes` to systemd's sleep config via a new `enableHibernation` option in the laptop feature module.

**Architecture:** Add `powerManagement.enableHibernation` boolean option to `nixos-modules/features/hardware/laptop.nix` alongside the existing power management options. When `true`, it sets `systemd.sleep.extraConfig` to allow hibernation. Enable it in `nixos-configurations/bandit/default.nix`.

**Tech Stack:** NixOS module system, systemd sleep configuration, `lib.mkIf`, `mkBoolOpt` helper from `cfgLib`.

**Spec:** `docs/superpowers/specs/2026-03-20-hibernation-fix-design.md`

---

## File Map

| File | Change |
|------|--------|
| `nixos-modules/features/hardware/laptop.nix` | Add `enableHibernation` option + `systemd.sleep.extraConfig` config block |
| `nixos-configurations/bandit/default.nix` | Set `features.hardware.laptop.powerManagement.enableHibernation = true` |

---

### Task 1: Add `enableHibernation` option to `laptop.nix`

**Files:**
- Modify: `nixos-modules/features/hardware/laptop.nix`

- [ ] **Step 1: Add the option declaration**

In `nixos-modules/features/hardware/laptop.nix`, locate the `powerManagement` options block (around line 20). Insert one new line after `enableGeneralPowerManagement`:

```nix
enableHibernation = mkBoolOpt false "Enable hibernation via systemd sleep configuration (requires resume device and offset to be set in boot config)";
```

This goes inside the existing `powerManagement = { ... };` block, immediately after the `enableGeneralPowerManagement` line. Do not replace the surrounding options.

- [ ] **Step 2: Add the config block**

In the `config = lib.mkIf cfg.enable { ... }` section, add the sleep config after `powerManagement.enable = cfg.powerManagement.enableGeneralPowerManagement;`:

```nix
powerManagement.enable = cfg.powerManagement.enableGeneralPowerManagement;

systemd.sleep.extraConfig = lib.mkIf cfg.powerManagement.enableHibernation ''
  AllowHibernation=yes
'';
```

- [ ] **Step 3: Verify the flake evaluates**

```bash
just qa
```

Expected: passes with no errors (option is declared but not yet enabled anywhere, defaults to `false`).

- [ ] **Step 4: Commit**

```bash
git add nixos-modules/features/hardware/laptop.nix
git commit -m "feat(laptop): add enableHibernation power management option"
```

---

### Task 2: Enable hibernation on bandit

**Files:**
- Modify: `nixos-configurations/bandit/default.nix`

- [ ] **Step 1: Enable the option**

In `nixos-configurations/bandit/default.nix`, locate `features.hardware.laptop` (around line 114). Add `powerManagement.enableHibernation = true` inside that block:

```nix
hardware.laptop = {
  enable = true;
  cpu.vendor = "amd";
  powerManagement.enableHibernation = true;
  zram = {
    memoryPercent = 50; # Increase from 25% to 50% for better memory headroom
  };
  framework = {
    enable = true;
    model = "framework-13-amd";
  };
};
```

Note: the block above lives inside `features = { ... }` in `bandit/default.nix`, so the full attribute path is `features.hardware.laptop`. Do not add a bare top-level `hardware.laptop` block — edit the existing one at lines 114–124.

- [ ] **Step 2: Verify the flake evaluates**

```bash
just qa
```

Expected: passes with no errors.

- [ ] **Step 3: Commit**

```bash
git add nixos-configurations/bandit/default.nix
git commit -m "feat(bandit): enable hibernation"
```

---

### Task 3: Rebuild and verify

- [ ] **Step 1: Rebuild the system**

```bash
just rebuild
```

Expected: switch completes successfully.

- [ ] **Step 2: Confirm the setting was applied**

NixOS may write the value directly into `/etc/systemd/sleep.conf` or as a drop-in. Check both:

```bash
cat /etc/systemd/sleep.conf
cat /etc/systemd/sleep.conf.d/*.conf 2>/dev/null || true
```

Expected: `AllowHibernation=yes` appears in one of the two.

- [ ] **Step 3: Test hibernation**

```bash
systemctl hibernate
```

Expected: system hibernates (screen off, power light off), then resumes correctly on next boot.

- [ ] **Step 4: Test rofi power menu**

Open the rofi power menu (`Super+Shift+E` or polybar power button) and select Hibernate. Expected: same result as Step 3.
