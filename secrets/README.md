# Secrets Management with sops-nix

This directory contains encrypted secrets managed by [sops-nix](https://github.com/Mic92/sops-nix).

## 📋 Overview

Secrets are encrypted using **Age** and **GPG** keys defined in `.sops.yaml` at the repository root. Only holders of the corresponding private keys can decrypt these secrets.

### Current Secrets:

- `github-mcp.yaml` - GitHub MCP Personal Access Token
- `github.yaml` - GitHub SSH private key
- `gpg-signing-key.yaml` - GPG private key for commit signing
- `restic.yaml` - Restic backup password

## 🔐 How Encryption Works

### Public/Private Key Cryptography:

```
Public Key (in .sops.yaml)  → Anyone can ENCRYPT
Private Key (secret!)       → Only YOU can DECRYPT
```

### Encryption Process:

1. **Create/Edit Secret:** `sops secrets/mysecret.yaml`
2. **Sops generates random data key** (one-time encryption key)
3. **Encrypts your secret with data key**
4. **Encrypts data key with EACH public key** from `.sops.yaml`
5. **Stores encrypted data + encrypted keys in file**

### Decryption Process:

1. **You run:** `sops --decrypt secrets/mysecret.yaml`
2. **Sops tries your private keys** (Age, GPG)
3. **If match found:** Decrypts data key → Decrypts secret
4. **Shows plaintext**

## 🔑 Current Keys

### Age Keys:
- **User:** `age134u5vtdts98pnept0k9v0uy4m6guthggfguw0ycvzn0evjeqgemsgl0krt`
  - Private key: `~/.config/sops/age/keys.txt`
  - Used for: User-level decryption

- **Host:** `age1r6cncetmt3xx9mv2hedvwm8dwc2nhy9rmekhah747kxeguzygplq6a875l`
  - Private key: `/var/lib/sops-nix/key.txt`
  - Used for: System-level decryption (auto-generated per host)

### GPG Key:
- **Signing Key:** `FC8B68693AF4E0D9DC84A4D3B872E229ADE55151`
  - Private key: `~/.gnupg/`
  - Used for: Git commit signing + backup decryption

## 🆕 Adding a New Machine

### On New Machine:

```bash
# 1. Clone repository
git clone <your-repo-url>
cd nixos-config

# 2. Generate new Age key
nix run .#generate-age-key

# Copy the public key shown (age1...)
```

### On Machine With Access:

```bash
# 3. Add new public key to .sops.yaml
nano .sops.yaml

keys:
  - &user age134u5v...  # existing
  - &host age1r6cn...   # existing
  - &gpg_user FC8B68... # existing
  - &new_machine age1newmachine123...  # ADD THIS

creation_rules:
  - path_regex: secrets/.*\.ya?ml
    key_groups:
      - age:
          - *user
          - *host
          - *new_machine  # ADD THIS
        pgp:
          - *gpg_user

# 4. Re-encrypt ALL secrets with new key
sops updatekeys secrets/*.yaml

# 5. Commit and push
git add .sops.yaml secrets/*.yaml
git commit -m "Add new machine to sops recipients"
git push
```

### Back On New Machine:

```bash
# 6. Pull changes
git pull

# 7. Test decryption
sops --decrypt secrets/github.yaml  # Should work!

# 8. Rebuild
nixos-rebuild switch --flake .
```

## ➕ Creating a New Secret

```bash
# Create and edit new secret
sops secrets/new-secret.yaml

# Add your secret data in YAML format:
# password: my_secret_value
# api_key: another_secret

# Save and quit - sops automatically encrypts

# Commit
git add secrets/new-secret.yaml
git commit -m "Add new-secret.yaml"
git push
```

## 🔄 Editing Existing Secrets

```bash
# Edit (automatically decrypts, lets you edit, re-encrypts)
sops secrets/github.yaml

# Make your changes, save and quit

# Commit
git add secrets/github.yaml
git commit -m "Update github secret"
git push
```

## 🔐 Key Rotation

### Rotating Age Keys:

```bash
# 1. Generate new Age key
nix run .#generate-age-key
# (will backup old key automatically)

# 2. Update .sops.yaml with new public key
nano .sops.yaml

# 3. Re-encrypt all secrets
sops updatekeys secrets/*.yaml

# 4. Commit
git add .sops.yaml secrets/*.yaml
git commit -m "Rotate Age encryption keys"
git push
```

### Removing a Key:

```bash
# 1. Remove key from .sops.yaml
nano .sops.yaml  # Delete the unwanted key

# 2. Re-encrypt without that key
sops updatekeys secrets/*.yaml

# 3. Commit
git add .sops.yaml secrets/*.yaml
git commit -m "Remove old machine from sops recipients"
git push
```

## 🚨 Recovery Procedures

### Lost Age Key:

**Option 1: Restore from Backup**
```bash
# If you have Age key backup (USB, password manager, etc.)
mkdir -p ~/.config/sops/age
chmod 700 ~/.config/sops/age

# Copy backed up key
cp /path/to/backup/keys.txt ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Test
sops --decrypt secrets/github.yaml
```

**Option 2: Use GPG Key Backup**
```bash
# Import GPG key from encrypted backup
sops --decrypt secrets/gpg-signing-key.yaml | \
  yq -r '.gpg_private_key' | \
  gpg --import

# Trust the key
gpg --edit-key FC8B68693AF4E0D9DC84A4D3B872E229ADE55151
# In GPG prompt: trust → 5 (ultimate) → quit

# Now you can decrypt with GPG
sops --decrypt secrets/github.yaml
```

**Option 3: Get Help from Another Machine**
```bash
# On machine WITH access:
# Generate new key for the lost machine
# Add to .sops.yaml
# Run: sops updatekeys secrets/*.yaml
# Push changes

# On machine WITHOUT access:
git pull  # Now you can decrypt with new key
```

### Lost ALL Keys:

**If you lose both Age AND GPG keys:**
- Secrets are **permanently lost** (this is security working correctly!)
- You'll need to recreate all secrets
- **Prevention:** Keep backups of Age key (USB, password manager)

## 🔒 Security Best Practices

### DO:
- ✅ Keep private keys secret (never commit)
- ✅ Backup Age key to secure location (USB, password manager)
- ✅ Use strong passphrases for GPG keys
- ✅ Commit encrypted secrets to Git (safe!)
- ✅ Share public keys freely (in `.sops.yaml`)
- ✅ Rotate keys periodically

### DON'T:
- ❌ Commit private keys to Git
- ❌ Share private keys with anyone
- ❌ Store unencrypted secrets in repository
- ❌ Forget to backup Age key
- ❌ Add someone's key without re-running `updatekeys`

## 🧪 Testing Decryption

```bash
# Test if you can decrypt
sops --decrypt secrets/github.yaml

# View which keys can decrypt a secret
sops --decrypt --extract '["sops"]["age"]' secrets/github.yaml

# Check GPG keys
sops --decrypt --extract '["sops"]["pgp"]' secrets/github.yaml
```

## 📚 Useful Commands

```bash
# Decrypt secret to stdout
sops --decrypt secrets/github.yaml

# Decrypt specific key
sops --decrypt --extract '["password"]' secrets/github.yaml

# Edit secret
sops secrets/github.yaml

# Re-encrypt all secrets (after changing .sops.yaml)
sops updatekeys secrets/*.yaml

# Encrypt existing plaintext file
sops --encrypt secrets/plaintext.yaml > secrets/encrypted.yaml

# Generate new Age key
nix run .#generate-age-key

# List your GPG keys
gpg --list-secret-keys
```

## 🔗 Additional Resources

- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [SOPS Documentation](https://github.com/mozilla/sops)
- [Age Encryption](https://age-encryption.org/)

## ❓ Troubleshooting

### "no matching key found"
- Your private key doesn't match any public key in the secret
- Solution: Ask someone with access to run `sops updatekeys` after adding your key

### "failed to decrypt"
- Age key file missing or corrupted
- Check: `ls ~/.config/sops/age/keys.txt`
- Solution: Restore from backup

### "decryption failed: no key could decrypt the data"
- None of your private keys match
- Check what keys are in the secret: `grep "recipient:" secrets/file.yaml`
- Solution: Ask someone to add your key and re-encrypt

### Secrets not available during activation
- Timing issue with sops-nix activation
- Check: `journalctl -u home-manager-vino.service`
- Usually resolves on next rebuild

---

**Last Updated:** 2026-02-07
**Maintainer:** 6FaNcY9
