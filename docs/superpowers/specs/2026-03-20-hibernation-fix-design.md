# Hibernation Fix Design

**Date:** 2026-03-20
**Host:** bandit (Framework 13 AMD, NixOS)

## Problem

`systemctl hibernate` fails with:

```
Call to Hibernate failed: Sleep verb 'hibernate' is not configured or configuration is not supported by kernel
```

The kernel-level resume parameters (`boot.resumeDevice`, `resume_offset`) are already correctly set in `nixos-configurations/bandit/default.nix`. The rofi power menu already calls `systemctl hibernate`. The issue is that systemd's sleep subsystem requires `AllowHibernation=yes` in `/etc/systemd/sleep.conf` before it will permit the hibernate verb — this is not set anywhere in the config.

The user also tried `sudo hibernate` which does not exist as a standalone command in NixOS; the correct command is `systemctl hibernate`.

## What Is Already Correct

- `boot.resumeDevice` — set to the BTRFS partition UUID in `bandit/default.nix:145`
- `kernelParams = [ "resume_offset=1959063" ]` — set in `bandit/default.nix:147`
- Swap file at `/swap/swapfile` with priority 1 (disk backup after zram)
- Rofi power menu `power-menu.sh:33` calls `systemctl hibernate`
- `xss-lock --transfer-sleep-lock` in autostart handles screen lock before hibernate
- Polkit (`desktop-hardening.nix`) does not restrict `org.freedesktop.login1.hibernate` — local wheel users can hibernate without a password prompt

## What Is Missing

`systemd.sleep.extraConfig` with `AllowHibernation=yes` is not set anywhere. Without it, systemd refuses to execute the hibernate verb regardless of kernel parameters.

## Design

### Option Chosen: Extend `laptop.nix` power management options

Add a `powerManagement.enableHibernation` boolean option to `nixos-modules/features/hardware/laptop.nix`. This fits naturally alongside the existing power management options (`enablePowerProfilesDaemon`, `useAutoFreq`, `enableGeneralPowerManagement`).

**New option:**
```nix
powerManagement = {
  enableHibernation = mkBoolOpt false "Enable hibernation via systemd sleep configuration";
  # ... existing options unchanged
};
```

**New config block (inside `config = lib.mkIf cfg.enable`):**
```nix
systemd.sleep.extraConfig = lib.mkIf cfg.powerManagement.enableHibernation ''
  AllowHibernation=yes
  HibernateMode=platform shutdown
'';
```

`HibernateMode=platform shutdown` is the correct mode for UEFI systems (uses the UEFI hibernate mechanism, falls back to shutdown if unavailable). This is the systemd default but making it explicit avoids ambiguity.

**Enable in `bandit/default.nix`:**
```nix
features.hardware.laptop.powerManagement = {
  enableHibernation = true;
  # existing options unchanged
};
```

### Why Not Other Locations

- **`bandit/default.nix` directly** — Would work but `systemd.sleep.extraConfig` is a power management concern, not a host-specific boot concern. Grouping it with `enablePowerProfilesDaemon` etc. is semantically cleaner and reusable for future laptop hosts.
- **`swap.nix`** — Swap is a prerequisite for hibernate but not the right owner of the sleep subsystem config.

## Files to Change

| File | Change |
|------|--------|
| `nixos-modules/features/hardware/laptop.nix` | Add `enableHibernation` option + `systemd.sleep.extraConfig` config block |
| `nixos-configurations/bandit/default.nix` | Set `enableHibernation = true` |

## Testing

After rebuild:
1. `systemctl hibernate` should succeed without error
2. System should hibernate, power off, and resume correctly on next boot
3. Rofi power menu hibernate entry should work
4. If swap file is ever recreated, `resume_offset` must be regenerated:
   ```bash
   sudo filefrag -v /swap/swapfile | awk 'NR==4{gsub(/\.\./,""); print $4}'
   ```
   and updated in `bandit/default.nix`.

## Non-Goals

- No changes to the rofi power menu (already correct)
- No polkit rule changes (not needed)
- No `sudo hibernate` alias (use `systemctl hibernate` directly)
