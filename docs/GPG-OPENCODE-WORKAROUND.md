# GPG Signing in OpenCode/SSH Environments

## Problem

GPG commit signing fails in OpenCode terminal (SSH-like, no proper TTY):
```
error: gpg failed to sign the data:
gpg: signing failed: Timeout
```

**Root Cause**: OpenCode runs in an SSH-like environment without a proper TTY. When GPG tries to prompt for the passphrase:
- `pinentry-curses` requires terminal interaction → hangs/times out
- `pinentry-gtk2/gnome3/qt` tries to show GUI popup → messes up TUI, requires killing session

## Workarounds

### Option 1: Disable GPG Signing for OpenCode Sessions (CURRENT)

**Local repository override** (already applied):
```bash
git config --local commit.gpgsign false
```

**Pros**:
- Commits work immediately in OpenCode
- No TUI interference
- Can still sign commits manually outside OpenCode

**Cons**:
- Commits from OpenCode are unsigned
- Need to remember to sign important commits manually

**Verification**:
```bash
git config --local --get commit.gpgsign  # Should show: false
git config --global --get commit.gpgsign  # Should show: true (global still enabled)
```

---

### Option 2: SSH-Based Commit Signing (RECOMMENDED FUTURE)

Git 2.34+ supports SSH keys for commit signing instead of GPG.

**Setup**:
```nix
# In nixos-modules/core.nix or home-modules/git.nix
programs.git = {
  extraConfig = {
    gpg.format = "ssh";
    user.signingKey = "~/.ssh/id_ed25519.pub";  # Or your SSH key path
    commit.gpgsign = true;
  };
};
```

**Pros**:
- No passphrase prompts (SSH agent handles it)
- Works in SSH/OpenCode environments
- Simpler than GPG (one key type for everything)
- GitHub/GitLab support SSH signatures

**Cons**:
- Requires Git 2.34+
- Need to upload SSH signing key to GitHub/GitLab
- Different trust model than GPG web of trust

**GitHub Setup**:
1. Go to Settings → SSH and GPG keys
2. Click "New SSH key"
3. Select key type: "Signing Key"
4. Paste your public SSH key
5. Commits will show "Verified" badge

---

### Option 3: GPG Agent Forwarding (COMPLEX)

Forward GPG agent from host machine to OpenCode session.

**Not Recommended** because:
- Complex setup (SSH agent forwarding + GPG socket forwarding)
- Still requires pinentry on host machine
- Fragile across session restarts
- Security implications (forwarding private key access)

---

### Option 4: Pre-Signed Commits (MANUAL)

Sign commits manually after OpenCode session:

```bash
# In OpenCode (unsigned commits)
git config --local commit.gpgsign false
git commit -m "message"

# Later, outside OpenCode (sign retroactively)
git config --local commit.gpgsign true
git commit --amend --no-edit -S
```

**Pros**:
- Keep unsigned workflow in OpenCode
- Sign important commits later

**Cons**:
- Manual process
- Easy to forget
- Changes commit hash (breaks pushed commits)

---

## Current Configuration

### System-Level GPG Config
**File**: `nixos-modules/core.nix`

```nix
programs.gnupg.agent = {
  enable = true;
  pinentryPackage = pkgs.pinentry-gtk2;  # GUI popup (doesn't work in OpenCode)
  enableSSHSupport = true;
};
```

### Git GPG Config
**Global** (from `home-modules/git.nix`):
```nix
programs.git = {
  signing = {
    key = "FC8B68693AF4E0D9DC84A4D3B872E229ADE55151";
    signByDefault = true;
  };
};
```

**Local Override** (this repository only):
```bash
git config --local commit.gpgsign false  # Disables signing in OpenCode
```

---

## Recommendations

### Short Term (Current)
- Keep `commit.gpgsign = false` in local config for OpenCode sessions
- Sign important commits manually in regular terminal when needed
- Document which commits were unsigned vs signed

### Long Term (Recommended Migration)
- Switch to SSH-based commit signing
- Simpler, works everywhere, GitHub/GitLab native support
- Remove GPG commit signing complexity

**Migration Steps**:
1. Generate/use existing SSH key for signing
2. Upload signing key to GitHub/GitLab
3. Update NixOS config to use `gpg.format = "ssh"`
4. Test signing in both OpenCode and regular terminal
5. Remove GPG signing config

---

## Testing Commit Signing

### Check Current Status
```bash
# Global setting
git config --global --get commit.gpgsign

# Local override
git config --local --get commit.gpgsign

# Effective setting for this repo
git config --get commit.gpgsign
```

### Test Unsigned Commit
```bash
git config --local commit.gpgsign false
git commit --allow-empty -m "test: unsigned commit"
git log --show-signature -1  # Should show no signature
```

### Test Signed Commit (Outside OpenCode)
```bash
git config --local commit.gpgsign true
git commit --allow-empty -m "test: signed commit"
git log --show-signature -1  # Should show GPG signature
```

### Verify on GitHub
Signed commits show a "Verified" badge. Unsigned commits show "Unverified".

---

## Alternative Pinentry Options (Not Recommended for OpenCode)

If you want to experiment with different pinentry flavors (these still won't work well in OpenCode):

```nix
# In nixos-modules/core.nix
programs.gnupg.agent.pinentryPackage = 
  pkgs.pinentry-curses;    # Terminal-based (original problem)
  # pkgs.pinentry-gtk2;    # GTK2 GUI (current, messes up TUI)
  # pkgs.pinentry-gnome3;  # GNOME GUI
  # pkgs.pinentry-qt;      # Qt GUI
  # pkgs.pinentry-rofi;    # Rofi integration (matches our launcher)
```

**All GUI pinentry variants will interfere with OpenCode TUI.**

---

## Related Issues

- NixOS issue: https://github.com/NixOS/nixpkgs/issues/108598
- GPG in SSH sessions: https://github.com/keybase/keybase-issues/issues/2798
- Git SSH signing docs: https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgformat

---

## Summary

**Current Solution**: Disabled GPG signing for this repository in OpenCode sessions.

**Recommended Future**: Migrate to SSH-based commit signing for universal compatibility.

**Quick Reference**:
```bash
# Disable signing in OpenCode
git config --local commit.gpgsign false

# Re-enable signing outside OpenCode
git config --local commit.gpgsign true

# Or remove local override to use global setting
git config --local --unset commit.gpgsign
```
