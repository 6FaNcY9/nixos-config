# Using DevShells from Other Directories

This guide explains how to use the devShells from your NixOS config when working on projects in other directories.

## Available Shells

| Shell | Purpose |
|-------|---------|
| `default` | Flake tools (nix, formatting, linting) |
| `web` | Node.js, npm, TypeScript |
| `flask` | Python, Flask |
| `agents` | Python, AI/LLM tooling |
| `rust` | Rust toolchain |
| `go` | Go toolchain |
| `pentest` | Security testing tools |
| `database` | Database clients |
| `nix-debug` | Nix debugging tools |

All shells include **mission-control** (`, <command>`) for quick access to git, build, and dev commands. Type `, help` inside any shell.

## Method 1: Direct Reference (Quick & Simple)

From any directory, reference the flake directly:

```bash
# Enter web devShell from anywhere
nix develop /home/vino/src/nixos-config#web

# Or use the shorthand if you're in a subdirectory
nix develop ~/src/nixos-config#web
```

**Use case:** Quick one-off usage, testing, or temporary work.

---

## Method 2: Using direnv (Recommended for Projects)

Create a `.envrc` file in your project directory to automatically load the devShell when you `cd` into it.

### Setup (one-time):

direnv is already enabled system-wide in your config (via `nixos-modules/roles/development.nix`).

### Usage:

```bash
cd ~/projects/my-website
echo 'use flake ~/src/nixos-config#web' > .envrc
direnv allow
```

Now whenever you `cd` into `~/projects/my-website`, the web devShell automatically loads!

**Benefits:**
- Automatic activation/deactivation
- Per-project environment isolation
- Works with VSCode and other editors

---

## Method 3: Project flake.nix (Best for Shared Projects)

Create a minimal `flake.nix` in your project that uses your config as input:

```nix
# ~/projects/my-website/flake.nix
{
  description = "My Website Project";

  inputs = {
    nixos-config.url = "path:/home/vino/src/nixos-config";
  };

  outputs = {nixos-config, ...}: {
    devShells.x86_64-linux.default = nixos-config.devShells.x86_64-linux.web;
  };
}
```

Then use it:

```bash
cd ~/projects/my-website
nix develop
```

**Benefits:**
- Project is self-contained
- Can be committed to git (others can use it)
- Can extend or customize the devShell

---

## Method 4: Shell Alias (Convenient for Frequent Use)

Add to your Fish config (`~/.config/fish/config.fish` or `home-modules/shell.nix`):

```fish
# Add these abbreviations
abbr -a devweb 'nix develop ~/src/nixos-config#web'
abbr -a devrust 'nix develop ~/src/nixos-config#rust'
abbr -a devflask 'nix develop ~/src/nixos-config#flask'
```

Then from anywhere:

```bash
devweb    # Enters web devShell
devrust   # Enters rust devShell
```

---

## Method 5: Registry (Global Access)

Add your config to your Nix registry for easy access:

```bash
nix registry add myconfig ~/src/nixos-config
```

Now use it from anywhere:

```bash
nix develop myconfig#web
nix develop myconfig#rust
```

**Permanent setup:** Add to `nixos-modules/core.nix`:

```nix
nix.registry.myconfig = {
  from = {
    type = "indirect";
    id = "myconfig";
  };
  to = {
    type = "path";
    path = "${repoRoot}";
  };
};
```

---

## Comparison Table

| Method | Auto-activate | Portable | Per-project | Ease |
|--------|---------------|----------|-------------|------|
| Direct Reference | ❌ | ❌ | ❌ | ⭐⭐⭐ |
| direnv | ✅ | ❌ | ✅ | ⭐⭐⭐⭐⭐ |
| Project flake | ❌ | ✅ | ✅ | ⭐⭐⭐⭐ |
| Shell Alias | ❌ | ❌ | ❌ | ⭐⭐⭐⭐ |
| Registry | ❌ | ❌ | ❌ | ⭐⭐⭐⭐ |

---

## Recommended Workflow

### For Your Own Projects:
Use **direnv** (Method 2) - automatic, convenient, per-project

### For Quick Testing:
Use **Direct Reference** (Method 1) or **Shell Alias** (Method 4)

### For Shared/Public Projects:
Use **Project flake.nix** (Method 3) - others can reproduce your env

---

## Example: Web Development Project

```bash
# Create new web project
mkdir -p ~/projects/my-blog
cd ~/projects/my-blog

# Method 2: direnv (recommended)
echo 'use flake ~/src/nixos-config#web' > .envrc
direnv allow

# Now you have Node.js, npm, TypeScript, etc. automatically!
node --version
npm --version
tsc --version

# When you leave the directory, the environment unloads
cd ~  # web devShell deactivates
```

---

## Tips

1. **Keep config path consistent**: If you move `nixos-config`, update paths in your `.envrc` files

2. **VSCode integration**: Install the `direnv` extension to load devShells automatically in integrated terminal

3. **Mix and match**: You can use direnv with project-specific customizations:
   ```bash
   # .envrc
   use flake ~/src/nixos-config#web

   # Add project-specific vars
   export DATABASE_URL="postgresql://localhost/mydb"
   export NODE_ENV="development"
   ```

4. **Check what's loaded**: Run `echo $PATH` to see if the devShell is active

---

## Troubleshooting

**Problem:** `direnv: error .envrc is blocked`
**Solution:** Run `direnv allow` in the directory

**Problem:** Changes to nixos-config not reflected
**Solution:** Run `direnv reload` or `nix develop ... --refresh`

**Problem:** Slow to activate
**Solution:** First activation builds/downloads, subsequent ones are instant
