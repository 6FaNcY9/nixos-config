# Direnv Integration Guide

## 📖 What is Direnv?

**Direnv** is a shell extension that automatically loads and unloads environments when you navigate between directories. It eliminates the need to manually run `nix develop` every time you enter your project.

### The Problem Without Direnv

```bash
cd ~/src/nixos-config
nix develop              # 😩 Manual activation required
# ... work on project ...
cd ~/src/other-project   # ⚠️ Wrong environment still active!
```

### The Solution With Direnv

```bash
cd ~/src/nixos-config    # ✅ Automatically activates NixOS devshell
# ... work on project ... (all tools available)
cd ~/src/other-project   # ✅ Automatically switches to other devshell
cd ~/                    # ✅ Automatically unloads all environments
```

---

## 🚀 How It Works

### 1. **The `.envrc` File**

Each project contains a `.envrc` file that tells direnv what environment to load:

```bash
# .envrc
use flake  # Load the default devshell from flake.nix
```

When you `cd` into a directory with `.envrc`, direnv:
1. Detects the `.envrc` file
2. Executes its commands
3. Loads the specified environment
4. Exports all environment variables and packages

### 2. **Directory-Based Activation**

```
~/
├── src/
│   ├── nixos-config/
│   │   ├── .envrc          → use flake (NixOS tools)
│   │   └── flake.nix
│   └── rust-project/
│       ├── .envrc          → use flake .#rust (Rust tools)
│       └── flake.nix
└── documents/              → No .envrc (no environment)
```

**Result:**
- `cd nixos-config` → Loads: nix, alejandra, statix, gh, etc.
- `cd rust-project` → Loads: rustc, cargo, clippy, rust-analyzer
- `cd documents` → Clean shell (no dev tools)

### 3. **Security: Allow/Deny System**

Direnv won't execute `.envrc` files automatically (prevents malicious code):

```bash
$ cd ~/src/nixos-config
direnv: error .envrc is blocked. Run `direnv allow` to approve its content

$ direnv allow
direnv: loading ~/src/nixos-config/.envrc
direnv: using flake
direnv: nix-direnv: using cached dev shell
direnv: export +AR +AS +CC ... (environment loaded)
```

**Security Features:**
- Must explicitly approve each `.envrc` with `direnv allow`
- Tracks file changes via SHA hash
- If `.envrc` is modified, must re-approve
- Can revoke access with `direnv deny`

---

## 🎯 Setup (Already Done!)

This configuration already has direnv fully integrated:

✅ **Direnv installed** (`home-modules/profiles.nix`)
✅ **Fish hook enabled** (`home-modules/shell.nix`)
✅ **Nix-direnv extension** (better flake caching)
✅ **Base `.envrc` file** (root of repo)

### First Time Activation

After rebuilding your system:

```bash
# 1. Rebuild home-manager to activate direnv hook
nh home switch

# 2. Navigate to this repo
cd ~/src/nixos-config

# 3. Approve the .envrc file
direnv allow

# 4. Environment automatically loads!
# You'll see: direnv: loading ~/.envrc
#             direnv: using flake
#             direnv: nix-direnv: using cached dev shell
```

---

## 💡 Usage Examples

### Basic Workflow

```bash
# Normal navigation - direnv handles everything
cd ~/src/nixos-config
# ✅ Devshell automatically loaded

# Check what's available
which alejandra         # /nix/store/.../bin/alejandra
echo $IN_NIX_SHELL      # impure

# Leave the directory
cd ~/
# ✅ Environment automatically unloaded
which alejandra         # (not found)
```

### Checking Status

```bash
# View current direnv status
direnv status

# View loaded environment variables
direnv export json | jq

# Reload environment (after flake.nix changes)
direnv reload
```

### Managing .envrc Files

```bash
# Approve .envrc
direnv allow

# Deny/block .envrc
direnv deny

# Edit .envrc
$EDITOR .envrc
# After saving, direnv will prompt to re-approve
```

---

## 🔧 Advanced Usage

### Machine-Specific Overrides

Create `.envrc.local` for machine-specific settings (automatically gitignored):

```bash
# .envrc.local (not committed to git)
export MY_LOCAL_VAR="value"
export PATH="$HOME/custom/bin:$PATH"
```

The base `.envrc` automatically sources `.envrc.local` if it exists.

### Selecting Specific Devshells

To load a non-default devshell:

```bash
# .envrc
use flake .#rust       # Load rust devshell instead of default
```

Available devshells in this repo:
- `default` - Full NixOS configuration tools (default)
- `maintenance` - Maintenance and QA tools
- `web` - Web development (Node.js, pnpm, TypeScript)
- `rust` - Rust development
- `flask` - Python Flask development
- `go` - Go development
- `agents` - AI agent tools (stable `opencode`, latest `opencode-bun`, bun)
- `pentest` - Penetration testing tools
- `database` - Database tools (postgres, redis, etc.)
- `nix-debug` - Nix debugging and analysis

### Custom Environment Variables

```bash
# .envrc
use flake

# Add custom exports
export MY_PROJECT_ROOT="$PWD"
export MY_CUSTOM_PATH="$PWD/bin"
export PATH="$MY_CUSTOM_PATH:$PATH"
```

---

## 🐛 Troubleshooting

### Problem: `.envrc` not loading automatically

**Solution:**
```bash
# Check if direnv hook is loaded
direnv hook fish  # Should output hook code

# Restart shell
exec fish

# Re-approve .envrc
direnv allow
```

### Problem: "direnv: error .envrc is blocked"

**Solution:**
```bash
direnv allow  # Explicitly approve the .envrc
```

### Problem: Environment loads but packages missing

**Solution:**
```bash
# Clear direnv cache and reload
direnv reload

# Or clear nix-direnv cache
rm -rf ~/.cache/direnv

# Then re-enter directory
cd .
```

### Problem: Slow environment loading

**Solution:**
```bash
# nix-direnv caches the environment, but first load is slow
# After first load, subsequent loads are instant

# Check cache status
ls ~/.cache/direnv/layouts/

# Force cache rebuild
direnv reload
```

### Problem: Changes to flake.nix not reflected

**Solution:**
```bash
# Direnv caches the environment
# After changing flake.nix, reload:
direnv reload

# Or exit and re-enter directory
cd .. && cd nixos-config
```

---

## 📊 Performance Benefits

### Before Direnv

```bash
cd ~/src/nixos-config
nix develop              # 5-10 seconds wait ⏳
# ... work ...
exit                     # Manual exit required
```

**Issues:**
- 5-10 second wait every time
- Must remember to activate
- Environment persists incorrectly

### After Direnv (with nix-direnv cache)

```bash
cd ~/src/nixos-config    # Instant! ⚡ (<100ms)
# ... work ...
cd ~/                    # Instant cleanup! ⚡
```

**Benefits:**
- First load: ~5 seconds (builds cache)
- Subsequent loads: <100ms (uses cache)
- Automatic activation/deactivation
- Zero mental overhead

---

## 🎓 Best Practices

### ✅ DO:
- Commit `.envrc` to git (base configuration)
- Run `direnv allow` after cloning repos
- Use `.envrc.local` for machine-specific settings
- Run `direnv reload` after flake changes

### ❌ DON'T:
- Don't commit `.envrc.local` (machine-specific)
- Don't put secrets in `.envrc` (use sops-nix)
- Don't blindly `direnv allow` untrusted repos (security!)
- Don't edit `.envrc` without understanding implications

---

## 🔗 Integration with This Repo

### Current Setup

```
nixos-config/
├── .envrc              ← Auto-loads default devshell
├── .envrc.local        ← Your local overrides (gitignored)
├── flake.nix           ← Defines devshells
└── home-modules/
    └── shell.nix       ← Configures direnv integration
```

### What Happens When You `cd` Here

1. **Direnv detects** `.envrc` file
2. **Executes** `use flake` command
3. **Nix-direnv** caches the flake environment
4. **Exports** all packages and variables:
   - Nix tools: alejandra, statix, deadnix
   - Git tools: gh, lazygit
   - Dev tools: ripgrep, fd, fzf, bat
   - Project tools: nh, nix-output-monitor
   - Mission control: `,` command

5. **You get** instant access to everything!

### Testing Your Setup

```bash
# 1. Navigate to repo
cd ~/src/nixos-config

# 2. First time: direnv will ask for approval
direnv allow

# 3. Check environment is loaded
echo $IN_NIX_SHELL      # Should output: impure

# 4. Test a tool
, sysinfo               # Should work (mission-control loaded)

# 5. Leave directory
cd ~/

# 6. Try again
, sysinfo               # Should fail (environment unloaded)
```

---

## 📚 Additional Resources

- [Direnv Official Docs](https://direnv.net/)
- [Nix-direnv GitHub](https://github.com/nix-community/nix-direnv)
- [Direnv Wiki](https://github.com/direnv/direnv/wiki)

---

**Last Updated:** 2026-02-07
**Maintainer:** 6FaNcY9
