# Sudo in OpenCode/SSH Environments

## Problem

Sudo commands fail in OpenCode terminal (SSH-like, no proper TTY):
```
sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
sudo: a password is required
```

**Root Cause**: OpenCode runs in an SSH-like environment without a proper TTY. When sudo tries to prompt for the password:
- **Terminal sudo**: Requires interactive terminal input → fails in OpenCode
- **No askpass configured**: sudo has no fallback method to request password

This is **exactly analogous** to the GPG signing problem (see `docs/GPG-OPENCODE-WORKAROUND.md`).

---

## Workarounds

### Option 1: SUDO_ASKPASS with GUI Helper (RECOMMENDED)

Configure sudo to use a GUI password prompt when no terminal is available.

**How it works**:
1. Set `SUDO_ASKPASS` environment variable to point to a GUI password prompt program
2. Sudo automatically uses it when run with `-A` flag OR when no terminal is available
3. GUI popup appears (like GPG's pinentry-gtk2), you enter password, command runs

**Setup**:

#### Step 1: Choose an askpass program

You already have `x11-ssh-askpass` installed (found in your system):
```bash
# Current location
/nix/store/l796cj5xa1czjcq6iivjs8lvm0igk268-x11-ssh-askpass-1.2.4.1/libexec/x11-ssh-askpass
```

**Available options** (all in nixpkgs):
- `pkgs.x11-ssh-askpass` - Simple X11 password dialog (CURRENT, lightweight)
- `pkgs.openssh-askpass` - GTK-based (matches your pinentry-gtk2 style)
- `pkgs.lxqt.lxqt-openssh-askpass` - LXQt style
- `pkgs.kdePackages.ksshaskpass` - KDE style

**Recommended**: `pkgs.openssh-askpass` (GTK style matches your GPG pinentry)

#### Step 2: Configure environment variable

**In `home-modules/shell.nix`** (add to Fish environment):
```nix
{pkgs, ...}: {
  programs.fish = {
    shellInit = ''
      # ... existing config ...
      
      # Sudo askpass helper (GUI password prompt for OpenCode/SSH)
      # Similar to GPG's pinentry-gtk2
      set -gx SUDO_ASKPASS "${pkgs.openssh-askpass}/libexec/ssh-askpass"
    '';
  };
}
```

**OR in system config** (`nixos-modules/core.nix`):
```nix
{pkgs, ...}: {
  environment.variables = {
    SUDO_ASKPASS = "${pkgs.openssh-askpass}/libexec/ssh-askpass";
  };
}
```

#### Step 3: Configure sudo behavior

**In `nixos-modules/core.nix`** (or create `/etc/sudo.conf`):
```nix
{pkgs, ...}: {
  security.sudo = {
    wheelNeedsPassword = true;
    extraConfig = ''
      # Path to askpass helper program (GUI password prompt)
      Path askpass ${pkgs.openssh-askpass}/libexec/ssh-askpass
      
      # Optional: Always use askpass when no terminal (auto -A flag)
      # Defaults askpass
    '';
  };
  
  # Ensure askpass program is installed system-wide
  environment.systemPackages = with pkgs; [
    openssh-askpass  # GTK password dialog
  ];
}
```

#### Step 4: Usage

**Automatic** (if you enable `Defaults askpass` in sudo config):
```bash
sudo nixos-rebuild switch  # GUI popup appears automatically
```

**Manual** (safer, explicit):
```bash
sudo -A nixos-rebuild switch  # Force askpass mode
```

**Pros**:
- ✅ Works in OpenCode/SSH environments (just like GPG pinentry)
- ✅ GUI popup matches your existing GPG workflow
- ✅ No NOPASSWD needed (maintains security)
- ✅ Explicit with `-A` flag (you control when to use GUI)

**Cons**:
- ⚠️ GUI popup may interfere with OpenCode TUI (same as GPG pinentry-gtk2)
- ⚠️ Requires `-A` flag unless you enable `Defaults askpass`
- ⚠️ Won't work in pure SSH (no X11 forwarding)

---

### Option 2: NOPASSWD for Specific Commands (SIMPLE)

Allow specific commands to run without password.

**Setup in `nixos-modules/core.nix`**:
```nix
{lib, username, ...}: {
  security.sudo = {
    wheelNeedsPassword = true;  # Default: require password
    extraRules = [
      {
        users = [ username ];  # Just you
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-store";
            options = [ "NOPASSWD" ];
          }
          # Add more as needed
        ];
      }
    ];
  };
}
```

**Pros**:
- ✅ Simple, works everywhere (terminal, SSH, OpenCode)
- ✅ No TUI interference
- ✅ No GUI popup needed

**Cons**:
- ⚠️ Security risk: anyone with access to your unlocked session can run these commands
- ⚠️ Need to explicitly list every command
- ⚠️ Less secure than password prompt

**Security tip**: Limit to specific commands, not `ALL`. Never use `%wheel ALL=(ALL) NOPASSWD: ALL`.

---

### Option 3: Pre-authenticate with `sudo -v` (MANUAL)

Cache your sudo credentials before starting OpenCode work.

**Workflow**:
```bash
# In a regular terminal (before OpenCode session)
sudo -v  # Enter password once, cached for 5 minutes (your current timeout)

# Now work in OpenCode for next 5 minutes
# Sudo commands will use cached credentials
```

**Extend timeout** in `nixos-modules/roles/desktop-hardening.nix`:
```nix
desktop.hardening.sudo.timeout = 15;  # 15 minutes instead of 5
```

**Pros**:
- ✅ No configuration changes needed
- ✅ Maintains full security
- ✅ Works for any command

**Cons**:
- ⚠️ Manual process (must remember to run `sudo -v`)
- ⚠️ Times out (need to re-run every 5-15 minutes)
- ⚠️ Not ideal for long OpenCode sessions

---

### Option 4: Password via stdin `-S` (NOT RECOMMENDED)

Pass password through standard input.

```bash
echo "your-password" | sudo -S command
```

**Cons**:
- ❌ Password visible in process list
- ❌ Password in command history
- ❌ Password in shell variables
- ❌ Major security vulnerability

**Never use this in real scenarios.**

---

### Option 5: pkexec Instead of sudo (ALTERNATIVE)

Use polkit/pkexec which already has GUI authentication.

**Usage**:
```bash
pkexec nixos-rebuild switch
```

**Setup**: You already have polkit configured!
- `security.polkit.enable = true` (in `nixos-modules/desktop.nix`)
- `polkit-gnome-authentication-agent-1` running (in i3 autostart)

**Pros**:
- ✅ GUI popup already configured (polkit-gnome)
- ✅ No additional setup needed
- ✅ More fine-grained permission model

**Cons**:
- ⚠️ Not all commands support pkexec
- ⚠️ Different permission model than sudo
- ⚠️ Need to configure polkit rules for specific actions
- ⚠️ OpenCode AI assistant uses `sudo` by default

---

## Comparison: GPG vs Sudo Solutions

| Aspect | GPG Problem | Sudo Problem |
|--------|-------------|--------------|
| **Root Cause** | No TTY for pinentry | No TTY for password prompt |
| **Terminal behavior** | pinentry-curses hangs | Terminal prompt fails |
| **GUI behavior** | pinentry-gtk2 shows popup | No GUI configured by default |
| **Your current solution** | Disabled GPG signing locally | Not yet solved |
| **Parallel solution** | Use SSH signing | Use SUDO_ASKPASS |
| **GUI helper** | pinentry-gtk2 | openssh-askpass (GTK) |
| **Environment variable** | (GPG_TTY) | SUDO_ASKPASS |

**The pattern is identical!** Just as GPG uses pinentry for password prompts, sudo can use askpass.

---

## Recommended Solution

**For your setup** (matching GPG workflow):

### Short Term: SUDO_ASKPASS with Manual `-A` Flag
1. Configure `SUDO_ASKPASS` to use `openssh-askpass` (GTK style, matches pinentry)
2. Use `sudo -A` explicitly when you need GUI prompts in OpenCode
3. Regular terminal sudo still uses terminal prompts (no TUI interference)

### Long Term: NOPASSWD for Safe Commands
1. Add NOPASSWD for specific system management commands (nixos-rebuild, systemctl)
2. Keep password requirement for dangerous commands (rm, dd, etc.)
3. Best of both worlds: convenience + security

### Hybrid Approach (RECOMMENDED)
```nix
# In nixos-modules/core.nix
{pkgs, lib, username, ...}: {
  # SUDO_ASKPASS for GUI prompts
  environment.variables = {
    SUDO_ASKPASS = "${pkgs.openssh-askpass}/libexec/ssh-askpass";
  };
  
  environment.systemPackages = with pkgs; [
    openssh-askpass
  ];
  
  security.sudo = {
    wheelNeedsPassword = true;
    
    # Askpass helper for when no terminal available
    extraConfig = ''
      Path askpass ${pkgs.openssh-askpass}/libexec/ssh-askpass
    '';
    
    # NOPASSWD for safe, common commands
    extraRules = [
      {
        users = [ username ];
        commands = [
          { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/systemctl"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/nix-store"; options = [ "NOPASSWD" ]; }
        ];
      }
    ];
  };
}
```

**Usage**:
- `nixos-rebuild`, `systemctl`: No password (NOPASSWD)
- Other commands in terminal: Terminal password prompt
- Other commands in OpenCode: `sudo -A` for GUI popup

---

## Configuration Examples

### Minimal Setup (Just SUDO_ASKPASS)

```nix
# nixos-modules/core.nix
{pkgs, ...}: {
  environment.variables.SUDO_ASKPASS = "${pkgs.openssh-askpass}/libexec/ssh-askpass";
  environment.systemPackages = [ pkgs.openssh-askpass ];
  
  security.sudo.extraConfig = ''
    Path askpass ${pkgs.openssh-askpass}/libexec/ssh-askpass
  '';
}
```

### Full Setup (NOPASSWD + ASKPASS)

```nix
# nixos-modules/core.nix
{pkgs, lib, username, ...}: {
  environment = {
    variables.SUDO_ASKPASS = "${pkgs.openssh-askpass}/libexec/ssh-askpass";
    systemPackages = [ pkgs.openssh-askpass ];
  };
  
  security.sudo = {
    wheelNeedsPassword = true;
    extraConfig = ''
      Path askpass ${pkgs.openssh-askpass}/libexec/ssh-askpass
    '';
    extraRules = [
      {
        users = [ username ];
        commands = [
          { command = "/run/current-system/sw/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/home-manager"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/systemctl"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/nix-store"; options = [ "NOPASSWD" ]; }
        ];
      }
    ];
  };
}
```

### Fish Shell Alias (Convenience)

```nix
# home-modules/shell.nix
programs.fish.shellAbbrs = {
  # ... existing abbrs ...
  gsudo = "sudo -A";  # GUI sudo (like how you have gcommit)
};
```

Then use: `gsudo some-command` for GUI password prompt.

---

## Testing

### Test SUDO_ASKPASS
```bash
# Set environment variable
export SUDO_ASKPASS=/nix/store/.../ssh-askpass

# Test with -A flag (should show GUI popup)
sudo -A whoami

# If it works, you'll see a GTK password dialog
```

### Test NOPASSWD Rules
```bash
# Should work without password
sudo nixos-rebuild --help

# Should still require password
sudo rm /etc/some-file  # (don't actually run this!)
```

### Test in OpenCode
1. Start OpenCode session
2. Run: `sudo -A whoami`
3. GTK password dialog should appear
4. Enter password
5. Command executes

---

## Security Considerations

### SUDO_ASKPASS
- ✅ Password never stored in plaintext
- ✅ GUI prompt requires active user interaction
- ⚠️ Anyone can click the popup if session unlocked
- ⚠️ Askpass script could be replaced by attacker (protect with file permissions)

### NOPASSWD
- ⚠️ No authentication for specified commands
- ⚠️ Anyone with access to your session can run them
- ⚠️ Carefully audit which commands you whitelist
- ✅ Limited to specific commands (not `ALL`)

### Best Practices
1. **NOPASSWD**: Only for system management commands (nixos-rebuild, systemctl)
2. **ASKPASS**: For everything else that needs GUI
3. **Terminal sudo**: For sensitive operations (always require password)
4. **Never**: NOPASSWD for `rm`, `dd`, `mkfs`, or destructive commands

---

## Troubleshooting

### "sudo: no askpass program specified"
**Cause**: `SUDO_ASKPASS` not set or invalid path

**Fix**:
```bash
# Check environment variable
echo $SUDO_ASKPASS

# Should show path like:
/nix/store/...-openssh-askpass-.../libexec/ssh-askpass

# If empty, rebuild after adding to config
```

### GUI popup doesn't appear
**Cause**: No X11 session or askpass program not executable

**Fix**:
```bash
# Check if program exists and is executable
ls -la $SUDO_ASKPASS

# Check if X11 is available
echo $DISPLAY  # Should show :0 or similar

# Test askpass directly
$SUDO_ASKPASS "Test prompt"  # Should show GUI
```

### "askpass program messes up OpenCode TUI"
**Cause**: Same issue as GPG pinentry-gtk2

**Workaround**: Use NOPASSWD for common commands instead

---

## Related Issues

- NixOS sudo askpass: https://discourse.nixos.org/t/remote-nixos-rebuild-sudo-askpass-problem/28830
- Sudo man page: `man sudo` (search for SUDO_ASKPASS)
- Similar to GPG issue: `docs/GPG-OPENCODE-WORKAROUND.md`

---

## Summary

**Problem**: Sudo fails in OpenCode (no TTY), just like GPG signing.

**Solutions** (in order of recommendation):
1. **NOPASSWD for safe commands** - Simplest, most practical
2. **SUDO_ASKPASS + `-A` flag** - Explicit GUI prompts (matches GPG workflow)
3. **Hybrid (NOPASSWD + ASKPASS)** - Best of both worlds
4. **Pre-authenticate with `sudo -v`** - Manual but secure
5. **pkexec** - Alternative to sudo (already configured)

**Recommended**: Hybrid approach (NOPASSWD for nixos-rebuild/systemctl, ASKPASS for others)

**Quick Start**:
```bash
# Add to nixos-modules/core.nix, then:
sudo nixos-rebuild switch  # Last time you'll need password for this!
```
