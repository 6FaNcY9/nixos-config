# Config Cleanup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove two remaining code quality issues identified in the config audit.

**Architecture:** Both changes are isolated, zero-risk edits with no behavioural effect. They clean up dead code and a Nix no-op. No functional changes. Verify with `nix flake check` after both.

**Tech Stack:** Nix, NixOS module system

---

### Task 1: Remove `mkDevshellMotd` dead code

**Files:**
- Modify: `lib/default.nix`

`mkDevshellMotd` is defined, exported, and never called anywhere in the repo. It was superseded by inline motd strings in devshells.nix.

**Step 1: Delete the function body (lines 69–80)**

In `lib/default.nix`, remove:

```nix
  # mkDevshellMotd :: { title :: Str, emoji :: Str?, description :: Str? } -> Str
  # Create a formatted MOTD (message of the day) for devshells with color codes.
  mkDevshellMotd =
    {
      title,
      emoji ? "🔨",
      description ? "",
    }:
    ''
      {202}${emoji} ${title}{reset}
      ${description}
    '';
```

**Step 2: Delete the export (line 261)**

In `lib/default.nix`, remove from the final attrset:

```nix
  # Devshell helpers
  inherit mkDevshellMotd mkShellScript;
```

Replace with:

```nix
  # Devshell helpers
  inherit mkShellScript;
```

**Step 3: Verify no other callers exist**

```bash
grep -r "mkDevshellMotd" /home/vino/src/nixos-config
```

Expected: no output (only the definition, which we just removed).

**Step 4: Format**

```bash
nix fmt
```

Expected: no output (success).

**Step 5: Commit**

```bash
git add lib/default.nix
git commit -m "chore(lib): remove unused mkDevshellMotd helper"
```

---

### Task 2: Remove `mkEnableOption` no-op default override

**Files:**
- Modify: `nixos-modules/features/services/auto-update.nix`

`lib.mkEnableOption` already defaults to `false`. The `// { default = false; }` override is a no-op that adds noise.

**Step 1: Edit the file**

In `nixos-modules/features/services/auto-update.nix`, change line 20:

```nix
      enable = lib.mkEnableOption "systemd timer for automatic updates" // {
        default = false;
      };
```

to:

```nix
      enable = lib.mkEnableOption "systemd timer for automatic updates";
```

**Step 2: Format**

```bash
nix fmt
```

Expected: no output.

**Step 3: Verify config evaluates**

```bash
nix flake check --system x86_64-linux 2>&1 | tail -5
```

Expected: exits 0 with no errors (may print build progress).

**Step 4: Commit**

```bash
git add nixos-modules/features/services/auto-update.nix
git commit -m "chore(auto-update): remove redundant mkEnableOption default override"
```

---

### Task 3: Mark audit as complete

**Files:**
- Modify: `docs/AUDIT_FIXES.md`

**Step 1: Prepend completion header**

Add at the top of `docs/AUDIT_FIXES.md`:

```markdown
# ✓ AUDIT COMPLETE — 2026-03-10

All batches verified. Summary of final state:
- Batch 1 (dead code/correctness): Done — items 1.1–1.5, 1.7 fixed; 1.6 (backup.nix) not applicable (file removed).
- Batch 2 (security): Done — all items fixed (IPv6 redirects, fail2ban params, DROP policy, assertions, SSH hardening).
- Batch 3 (architecture): Done — cfgLib injection, dunst font, workspace lookup, device options all fixed.
- Batch 4 (scripts/docs): Done — rofi scripts, verify.sh, CONTRIBUTING.md all fixed.
- Batch 5 (perf): Done — nixpkgs.follows, installCargo/installRustc all fixed.
- New finding (2026-03-10): mkDevshellMotd dead code removed (Tasks 1–2 above).

---

```

**Step 2: Commit**

```bash
git add docs/AUDIT_FIXES.md
git commit -m "docs(audit): mark all audit items complete"
```
