# Cachix Binary Cache Integration

## 📖 What is Cachix?

**Cachix** is a binary cache service for Nix that stores pre-built packages. Instead of rebuilding everything from source, your machines download pre-compiled binaries from the cache.

### The Problem Without Cachix

```bash
# On a new machine or after updating
nixos-rebuild switch
# ⏳ Rebuilding 500+ packages... 30-60 minutes
```

### The Solution With Cachix

```bash
# On a new machine with Cachix configured
nixos-rebuild switch
# ⚡ Downloading from cache... 5-10 minutes
```

---

## 🚀 How It Works

### Build & Push Flow

```
1. You commit changes to git
   ↓
2. GitHub Actions triggers
   ↓
3. Builds all configurations
   ↓
4. Pushes to Cachix cache
   ↓
5. Other machines download from cache
```

### What Gets Cached

- ✅ NixOS system configuration
- ✅ Home Manager configuration
- ✅ All devshells (web, rust, go, etc.)
- ✅ Custom packages
- ✅ Dependencies

---

## ⚙️ Configuration (Already Done!)

This repository is already configured with Cachix:

### 1. Cache Added to Substituters

**File:** `nixos-modules/core.nix`

```nix
substituters = [
  "https://cache.nixos.org"
  "https://nix-community.cachix.org"
  "https://vino-nixos-config.cachix.org"  # Your cache
];
```

### 2. Auth Token Stored Securely

**File:** `secrets/cachix.yaml` (encrypted with sops)

- Token is encrypted at rest
- Only decryptable by authorized keys
- Available at: `~/.config/sops-nix/secrets/cachix_auth_token`

### 3. GitHub Actions Workflow

**File:** `.github/workflows/cachix.yml`

- Runs on every push to main
- Builds all configurations
- Automatically pushes to cache

### 4. Helper Script

**Command:** `nix run .#cachix-push`

- Builds current system
- Pushes to your Cachix cache
- Useful for testing or manual pushes

---

## 🎯 Usage

### On Your Main Machine (Push)

After rebuilding your system locally, push to cache:

```bash
# Option 1: Automatic (via GitHub Actions)
git add .
git commit -m "Update configuration"
git push
# GitHub Actions will build and push to Cachix

# Option 2: Manual push
nix run .#cachix-push
# Builds and pushes immediately
```

### On New Machines (Pull)

Cachix is already configured, so new machines automatically use the cache:

```bash
# Clone your config
git clone <your-repo>
cd nixos-config

# Rebuild (will download from cache!)
nh os switch
# ⚡ Fast! Most packages come from cache
```

---

## 📊 Cache Statistics

Check your cache at: **https://vino-nixos-config.cachix.org**

You'll see:
- Number of cached paths
- Total cache size
- Recent uploads
- Download statistics

---

## 🔧 Manual Operations

### Push Current System to Cache

```bash
nix run .#cachix-push
```

This will:
1. Build your current NixOS configuration
2. Authenticate with your Cachix token
3. Push all derivations to cache
4. Show progress and results

### Push Specific Build

```bash
# Build something
nix build .#nixosConfigurations.bandit.config.system.build.toplevel

# Get the auth token
export CACHIX_AUTH_TOKEN=$(cat ~/.config/sops-nix/secrets/cachix_auth_token)

# Push to cache
cachix push vino-nixos-config ./result
```

### Check Cache Status

```bash
# List cached paths (requires cachix CLI)
cachix use vino-nixos-config

# Or visit the web UI
xdg-open https://vino-nixos-config.cachix.org
```

---

## 🆕 Adding Cache to New Machines

### Quick Setup

If you clone this repo to a new machine, Cachix is already configured in `nixos-modules/core.nix`. Just rebuild:

```bash
# 1. Clone repo
git clone <your-repo-url>
cd nixos-config

# 2. Rebuild (will use cache automatically!)
nh os switch

# 3. Done! Cache is active
```

### Verification

Check if cache is being used:

```bash
# Should show vino-nixos-config.cachix.org
nix show-config | grep substituters

# Test download from cache
nix build .#nixosConfigurations.bandit.config.system.build.toplevel
# Should say "copying path from 'https://vino-nixos-config.cachix.org'"
```

---

## 🔐 Security

### Token Management

**Auth token is stored securely:**
- ✅ Encrypted with sops-nix
- ✅ Not committed to git (encrypted form is safe)
- ✅ Only decryptable by authorized age/GPG keys
- ✅ Available only after `nh home switch`

**GitHub Secret:**
The token is also stored as a GitHub secret (`CACHIX_AUTH_TOKEN`) for CI/CD.

### Token Rotation

If you need to rotate the token:

```bash
# 1. Generate new token on Cachix website
# Settings → Auth Tokens → Generate

# 2. Update the secret
sops secrets/cachix.yaml
# Replace cachix_auth_token value with new token

# 3. Update GitHub secret
# Go to: GitHub repo → Settings → Secrets → CACHIX_AUTH_TOKEN
# Update the value

# 4. Commit
git add secrets/cachix.yaml
git commit -m "Rotate Cachix auth token"
git push
```

---

## 🐛 Troubleshooting

### Problem: Builds not appearing in cache

**Check GitHub Actions:**
```bash
# Visit: https://github.com/<user>/<repo>/actions
# Look for failed Cachix workflow runs
```

**Check token:**
```bash
# Verify token is decrypted
cat ~/.config/sops-nix/secrets/cachix_auth_token
# Should show the JWT token
```

### Problem: "substituter not trusted"

**Solution:**
```bash
# Add to /etc/nix/nix.conf (already done in nixos-modules/core.nix)
trusted-substituters = https://vino-nixos-config.cachix.org
```

### Problem: Cache not being used

**Check substituters:**
```bash
nix show-config | grep substituters
# Should include vino-nixos-config.cachix.org
```

**Force cache usage:**
```bash
nix build --option substituters "https://vino-nixos-config.cachix.org https://cache.nixos.org" .#nixosConfigurations.bandit.config.system.build.toplevel
```

### Problem: `cachix-push` fails with token error

**Check secret is decrypted:**
```bash
ls -la ~/.config/sops-nix/secrets/
# Should show cachix_auth_token file

# If missing, activate secrets:
nh home switch
```

---

## 📈 Performance Benefits

### Before Cachix

```bash
# Fresh NixOS install
nixos-rebuild switch
# Time: 30-60 minutes
# Downloads: Source tarballs
# CPU: 100% building packages
```

### After Cachix

```bash
# Fresh NixOS install with cache
nixos-rebuild switch
# Time: 5-10 minutes
# Downloads: Pre-built binaries
# CPU: ~10% (just copying)
```

### Rebuild Times

| Operation | Without Cache | With Cache |
|-----------|--------------|------------|
| Fresh install | 30-60 min | 5-10 min |
| After flake update | 10-20 min | 1-2 min |
| Small config change | 5-10 min | <1 min |

---

## 💡 Best Practices

### ✅ DO:
- Push to cache after major configuration changes
- Keep GitHub Actions enabled for automatic caching
- Use cache for all your machines
- Monitor cache size occasionally

### ❌ DON'T:
- Don't share your auth token publicly
- Don't disable cache in production
- Don't push broken builds (test locally first)
- Don't forget to git push (CI won't run without it)

---

## 🔗 Additional Resources

- [Cachix Official Docs](https://docs.cachix.org/)
- [Cachix Dashboard](https://app.cachix.org/)
- [Your Cache](https://vino-nixos-config.cachix.org)
- [GitHub Actions Docs](https://docs.github.com/en/actions)

---

**Last Updated:** 2026-02-07
**Cache Name:** vino-nixos-config
**Maintainer:** 6FaNcY9
