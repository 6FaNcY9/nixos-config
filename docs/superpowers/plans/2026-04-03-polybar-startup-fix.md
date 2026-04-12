# Polybar Startup Deadlock Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the ~90-second desktop startup delay caused by a circular deadlock between the polybar systemd service and the i3 session startup sequence.

**Architecture:** Change `polybar.service` from `Type=forking` to `Type=simple` so systemd declares it active immediately on start, breaking the deadlock. Replace the background `&` launch with `exec` so the start script itself becomes the tracked service process.

**Tech Stack:** Nix, Home Manager `services.polybar`, systemd user services.

---

## Files

| File | Change |
|---|---|
| `home-modules/features/desktop/polybar/default.nix` | Script `&` → `exec`; add `systemd.user.services.polybar.Service.Type = lib.mkForce "simple"` |

---

### Task 1: Apply the two-line fix to polybar/default.nix

**Files:**
- Modify: `home-modules/features/desktop/polybar/default.nix:62`

- [ ] **Step 1: Change `&` to `exec` in the launch line**

In `home-modules/features/desktop/polybar/default.nix`, change line 62:

```nix
      script = ''
        ${pkgs.procps}/bin/pkill -x polybar || true
        # Wait for i3 socket — polybar starts before i3 is ready at login,
        # causing the i3 module to be silently disabled for the whole session.
        until I3SOCK=$(${pkgs.i3}/bin/i3 --get-socketpath 2>/dev/null); do
          ${pkgs.coreutils}/bin/sleep 0.5
        done
        export I3SOCK
        exec ${config.services.polybar.package}/bin/polybar --reload top
      '';
```

The `&` is removed and `exec` is prepended. `exec` replaces the shell process with polybar directly — the wait loop runs first, then `exec` hands over to polybar as the live service process.

- [ ] **Step 2: Add `Type = simple` override immediately after the `services.polybar` block**

The full `config` block in `home-modules/features/desktop/polybar/default.nix` should be:

```nix
  config = lib.mkIf cfg.enable {
    services.polybar = {
      enable = true;
      package = pkgs.polybar.override {
        i3Support = true;
        pulseSupport = true;
        iwSupport = true;
      };

      script = ''
        ${pkgs.procps}/bin/pkill -x polybar || true
        # Wait for i3 socket — polybar starts before i3 is ready at login,
        # causing the i3 module to be silently disabled for the whole session.
        until I3SOCK=$(${pkgs.i3}/bin/i3 --get-socketpath 2>/dev/null); do
          ${pkgs.coreutils}/bin/sleep 0.5
        done
        export I3SOCK
        exec ${config.services.polybar.package}/bin/polybar --reload top
      '';

      settings = {
        "bar/top" = {
          # ... (unchanged)
        };
        "settings" = {
          # ... (unchanged)
        };
      };
    };

    # Override service type: forking → simple.
    # Type=simple declares the service active the instant ExecStart is launched,
    # not when it forks. This breaks the circular deadlock:
    #   xsession blocks on hm-graphical-session.target
    #   → which waited for tray.target
    #   → which waited for polybar.service to fork (Type=forking)
    #   → which looped waiting for i3 socket
    #   → but i3 couldn't start because xsession was blocked
    # With Type=simple, polybar.service is immediately active → tray.target
    # satisfied → hm-graphical-session.target completes → xsession runs i3
    # → i3 creates socket → polybar wait loop exits and execs polybar.
    systemd.user.services.polybar.Service.Type = lib.mkForce "simple";
  };
```

- [ ] **Step 3: Run `just qa`**

```bash
just qa
```

Expected output: exits 0 with no errors or warnings. If `statix` or `deadnix` complain, fix them before proceeding.

- [ ] **Step 4: Commit**

```bash
git add home-modules/features/desktop/polybar/default.nix
git commit -m "fix(polybar): break startup deadlock — Type=simple + exec launch

Change polybar.service from Type=forking to Type=simple so systemd
declares it active immediately on ExecStart, not after the start script
exits. Replace background '&' with 'exec' so the script process becomes
the tracked service process.

Fixes ~90s login delay caused by:
  xsession blocking on hm-graphical-session.target
  → waited for tray.target (After=polybar.service)
  → waited for polybar to fork (Type=forking)
  → polybar looped waiting for i3 socket
  → i3 couldn't start because xsession was still blocked

Desktop now appears in ~3–5s after login.
See docs/superpowers/specs/2026-04-03-polybar-startup-deadlock-fix.md"
```

---

### Task 2: Apply and verify on the live system

**Files:** (none changed — runtime verification only)

- [ ] **Step 1: Apply the configuration**

```bash
just rebuild
```

Expected: switch completes with no errors. Polybar will restart as part of HM activation.

- [ ] **Step 2: Verify the service type changed**

```bash
systemctl --user show polybar.service --property=Type
```

Expected output:
```
Type=simple
```

- [ ] **Step 3: Verify the start script uses exec**

```bash
systemctl --user cat polybar.service | grep ExecStart
```

Expected: the `ExecStart=` line points to the generated start script. Then:

```bash
cat $(systemctl --user show polybar.service --property=ExecStart --value | awk '{print $1}' | sed 's/^@//')
```

Expected: last line of the script is `exec /nix/store/.../bin/polybar --reload top` (no trailing `&`).

- [ ] **Step 4: Log out and log back in, measure startup time**

Log out of the i3 session. Log in. Count seconds until polybar appears.

Expected: polybar and desktop visible within **3–5 seconds** of login completing (time for i3 to initialise and create its socket).

If polybar is still missing after 10 seconds, run:

```bash
journalctl --user -u polybar.service -n 30 --no-pager
```

Look for: either the wait loop spinning (i3 socket not yet available) or polybar having started and exited with an error.

- [ ] **Step 5: Verify crash-restart still works**

```bash
systemctl --user kill --signal=SIGKILL polybar.service
sleep 3
systemctl --user status polybar.service
```

Expected: status shows `Active: active (running)` and polybar is visible on screen again. systemd's `Restart=on-failure` should have relaunched it. The restart script re-runs, finds the i3 socket immediately (i3 already running), and `exec`s polybar.
