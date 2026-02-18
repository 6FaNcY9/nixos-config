# Keeping NixOS Up-to-Date

Your system is configured to use **nixos-unstable** (latest packages).

## Quick Update Commands

### Update flake inputs + rebuild system
```bash
cd ~/src/nixos-config
nix flake update
nh os switch
```

### Or in one command
```bash
cd ~/src/nixos-config && nix flake update && nh os switch
```

### Check what will be updated (without applying)
```bash
cd ~/src/nixos-config
nix flake update
nh os build  # builds but doesn't switch
```

### See what changed between boots
```bash
nvd diff /run/booted-system /run/current-system
```

## What's Configured

- **System channel**: nixos-unstable (flake.nix line 21)
- **Stable fallback**: nixos-25.11 available as `pkgs.stable.*`
- **SSL certificates**: Fixed via environment variables in home-configurations/vino/default.nix
- **Build tool**: `nh` (Nix Helper) with nom build output

## Troubleshooting

### SSL Certificate Errors
If you see OpenSSL certificate errors, verify:
```bash
echo $SSL_CERT_FILE
# Should output: /etc/ssl/certs/ca-bundle.crt
```

If empty, restart your terminal or source the profile:
```bash
source /etc/profiles/per-user/vino/etc/profile.d/hm-session-vars.sh
```

### Check Current Generation
```bash
nix-env --list-generations --profile /nix/var/nix/profiles/system
```
