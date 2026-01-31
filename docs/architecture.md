# Architecture Documentation

This document explains the design decisions, patterns, and philosophies behind this NixOS configuration.

---

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Why These Choices](#why-these-choices)
3. [Module Organization](#module-organization)
4. [Secret Management Architecture](#secret-management-architecture)
5. [Backup Strategy](#backup-strategy)
6. [Monitoring Approach](#monitoring-approach)
7. [Development Workflow](#development-workflow)
8. [Multi-Host Strategy](#multi-host-strategy)
9. [Performance Considerations](#performance-considerations)
10. [Future Architecture](#future-architecture)

---

## Design Philosophy

### Core Principles

1. **Declarative Over Imperative**
   - Configuration as code, not manual setup
   - Reproducible across machines
   - Version-controlled history

2. **Modularity**
   - Small, focused modules
   - Feature-based organization
   - Easy to disable/enable components

3. **Community Alignment**
   - Follow proven patterns from high-quality configs
   - Use well-maintained inputs (nixpkgs-unstable, Home Manager, Stylix)
   - Leverage community binary caches (cachix)

4. **Hardware-Specific Optimizations**
   - Framework 13 AMD specific tuning
   - Power management for mobile use
   - WiFi/suspend stability fixes

5. **Defense in Depth**
   - BTRFS snapshots (filesystem level)
   - Restic backups (external storage)
   - NixOS generations (configuration level)
   - Git history (source control)

---

## Why These Choices

### Why ez-configs?

**Decision**: Use `ez-configs` instead of raw flake-parts or direct NixOS modules.

**Rationale**:
- **Auto-imports**: `nixos-modules/default.nix` and `home-modules/default.nix` automatically imported for every host/user
- **Less boilerplate**: No need to manually wire up every module in flake.nix
- **Cleaner structure**: Host entrypoints only contain host-specific overrides
- **Module discovery**: New modules just need to be added to `default.nix` aggregators

**Tradeoff**:
- Slight indirection (must understand ez-configs conventions)
- Less explicit (imports are "magical")

**Verdict**: Worth it for reduced maintenance and cleaner host files.

---

### Why Unstable-Primary + Stable Fallback?

**Decision**: Use `nixpkgs-unstable` as primary, `nixpkgs-25.11` as fallback via overlay.

**Rationale**:
- **Latest packages**: Unstable has newest software versions
- **Community standard**: Most high-quality configs use unstable
- **Binary cache**: nix-community.cachix.org has extensive unstable coverage
- **Safety net**: Stable overlay (`pkgs.stable.*`) available when unstable breaks

**Tradeoff**:
- Occasional breakage (mitigated by NixOS generations and rollback)
- More frequent updates (managed by weekly CI automation)

**Verdict**: Better developer experience outweighs stability concerns for a laptop.

**Implementation**:
```nix
# flake.nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
};

# overlays/default.nix
stable = final: _prev: {
  stable = import inputs.nixpkgs-stable {
    inherit (final) system;
    config.allowUnfree = true;
  };
};
```

**Usage**:
```nix
# Use unstable (default)
environment.systemPackages = [ pkgs.neovim ];

# Use stable (when needed)
environment.systemPackages = [ pkgs.stable.firefox ];
```

---

### Why Roles System?

**Decision**: Opt-in roles (`desktop`, `laptop`, `server`) instead of hardcoded configuration.

**Rationale**:
- **Flexibility**: Same config can build headless server or GUI laptop
- **Clear intent**: `roles.laptop = true` is self-documenting
- **Modularity**: Easy to add/remove role-specific features
- **Multi-host**: One repository supports multiple machine types

**Implementation**:
```nix
# nixos-modules/roles.nix
options.roles = {
  desktop = lib.mkEnableOption "desktop GUI (X11, i3, XFCE)";
  laptop = lib.mkEnableOption "laptop features (power management, bluetooth)";
  server = lib.mkEnableOption "server features (SSH, fail2ban)";
};

# nixos-modules/desktop.nix
config = lib.mkIf config.roles.desktop {
  services.xserver.enable = true;
  # ... desktop-specific config
};

# nixos-configurations/bandit/default.nix
roles = {
  desktop = true;
  laptop = true;
};
```

**Example Use Cases**:
- **Laptop (bandit)**: `desktop = true; laptop = true;`
- **Headless server**: `server = true;` (no desktop/laptop)
- **Desktop PC**: `desktop = true;` (no laptop power management)

---

### Why i3 + XFCE Services?

**Decision**: Use i3 window manager with XFCE session management (no XFWM).

**Rationale**:
- **i3 benefits**: Keyboard-driven, efficient, customizable
- **XFCE benefits**: Thunar file manager, power management, PolicyKit
- **Best of both**: Tiling WM + stable desktop services
- **Lightweight**: No redundant window manager (XFWM disabled)

**Tradeoff**:
- Slightly unusual setup (most use pure i3 or pure XFCE)
- Requires careful configuration to avoid conflicts

**Verdict**: Proven pattern from community configs, works great in practice.

**Implementation**:
```nix
services.xserver = {
  desktopManager.xfce = {
    enable = true;
    noDesktop = true;  # Don't draw desktop (i3 handles it)
    enableXfwm = false;  # Disable XFCE window manager
  };
  windowManager.i3.enable = true;
};
```

---

### Why Stylix?

**Decision**: Use Stylix for unified theming instead of manual per-app configuration.

**Rationale**:
- **Consistency**: One theme (Gruvbox Dark Pale) across all apps
- **Automatic**: Generates configs for i3, GTK, Qt, Firefox, etc.
- **Maintainable**: Change palette once, everything updates
- **Community standard**: Widely used in high-quality configs

**Tradeoff**:
- Less granular control (can be overridden if needed)
- Occasional styling quirks in specific apps

**Verdict**: Massive time saver, great default styling.

**Implementation**:
```nix
# shared-modules/stylix-common.nix
stylix = {
  enable = true;
  image = gruvboxWallpaper;
  base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-pale.yaml";
  polarity = "dark";
};

# Targets configured in home-configurations/vino/default.nix
stylix.targets = {
  gtk.enable = true;
  i3.enable = true;
  firefox.enable = true;
  # ... etc
};
```

---

### Why sops-nix?

**Decision**: Use sops-nix with age encryption instead of git-crypt, agenix, or plain secrets.

**Rationale**:
- **Secure**: Age encryption (modern, audited)
- **Flexible**: Per-secret permissions (owner, mode, path)
- **Validation**: Build-time checks ensure secrets exist and are encrypted
- **Standard**: Widely used in NixOS community

**Tradeoff**:
- Requires age key backup (CRITICAL - system won't decrypt without it)
- More complex than plain files (mitigated by helper functions)

**Verdict**: Industry-standard solution, worth the complexity.

See [Secret Management Architecture](#secret-management-architecture) for details.

---

### Why Restic + External USB?

**Decision**: Use Restic to local USB drive instead of cloud storage or no backups.

**Rationale**:
- **Incremental**: Fast, deduplicated backups
- **Encrypted**: Repository is encrypted at rest
- **Local**: No cloud costs, no internet dependency
- **Simple**: Single USB drive, auto-mount, daily backups

**Tradeoff**:
- No off-site protection (mitigated by git-based config backups)
- Requires manual drive connection (nofail mount option prevents boot issues)

**Verdict**: Good balance of simplicity and safety for laptop use.

See [Backup Strategy](#backup-strategy) for details.

---

### Why BTRFS?

**Decision**: Use BTRFS with subvolumes instead of ext4, ZFS, or LVM.

**Rationale**:
- **Snapshots**: Instant, space-efficient snapshots via Snapper
- **Compression**: zstd:3 saves significant disk space
- **Subvolumes**: Separate `/`, `/home`, `/nix`, `/var` with different policies
- **Scrubbing**: Monthly integrity checks catch corruption early
- **Modern**: Built-in features, good kernel support

**Tradeoff**:
- More complex than ext4 (mitigated by declarative NixOS config)
- RAID5/6 still unstable (not relevant for single-disk laptop)

**Verdict**: Best filesystem for NixOS laptops.

**Subvolume Strategy**:
```
/dev/nvme0n1p2 (BTRFS)
├── @ → / (root)
├── @home → /home
├── @nix → /nix (no snapshots needed, can be rebuilt)
├── @var → /var (logs, caches)
└── @swap → /swap (swapfile for hibernate)
```

---

## Module Organization

### Directory Structure Philosophy

**Principle**: Feature-based organization, not technical grouping.

**Before (Technical Grouping)**:
```
home-modules/
├── i3.nix (500 LOC monolith)
├── polybar.nix (300 LOC monolith)
└── nixvim.nix (600 LOC monolith)
```

**After (Feature Grouping)**:
```
home-modules/features/
├── desktop/
│   ├── i3/
│   │   ├── default.nix (orchestrator)
│   │   ├── keybindings.nix (focused)
│   │   ├── config.nix (window rules, colors)
│   │   ├── autostart.nix (startup apps)
│   │   └── workspace.nix (assignments)
│   └── polybar/
│       ├── default.nix
│       ├── colors.nix
│       └── modules.nix
└── editor/
    └── nixvim/
        ├── default.nix
        ├── options.nix (vim settings)
        ├── keymaps.nix (keybindings)
        ├── plugins.nix (plugin configs)
        └── extra-config.nix (raw Lua/Vimscript)
```

**Benefits**:
- **Easier navigation**: "I want to change i3 keybindings" → `features/desktop/i3/keybindings.nix`
- **Smaller files**: Each file < 200 LOC, easier to understand
- **Clear scope**: Each file has one responsibility
- **Better diffs**: Changes localized to relevant files

**Tradeoff**:
- More files (mitigated by clear naming and structure)
- Path arithmetic (`../../../../lib`) can be error-prone

**Convention**: Always use `default.nix` as the feature entry point with imports.

---

### Module Aggregation Pattern

**Pattern**: `default.nix` aggregators auto-imported by ez-configs.

**Implementation**:
```nix
# home-modules/default.nix
{
  imports = [
    ./profiles.nix
    ./devices.nix
    ./secrets.nix
    ./features/desktop/i3
    ./features/desktop/polybar
    ./features/editor/nixvim
    # ... more modules
  ];
}
```

**Benefits**:
- Single source of truth for module list
- Host configs only import what they need (via ez-configs auto-import)
- Easy to disable modules (comment out import)

**Host-Specific Overrides**:
```nix
# home-configurations/vino/hosts/bandit.nix
{ ... }: {
  # Only host-specific overrides here
  profiles.desktop = true;
  devices.networkInterface = "wlp1s0";
}
```

---

### Shared Arguments Pattern

**Pattern**: Use `_module.args` to inject shared variables across all modules.

**Implementation**:
```nix
# home-configurations/vino/default.nix
_module.args = {
  c = config.lib.stylix.colors;  # Color shortcuts
  palette = config.stylix.base16Scheme;  # Full palette
  stylixFonts = config.stylix.fonts;  # Font configuration
  i3Pkg = config.xsession.windowManager.i3.package;  # i3 package
  workspaces = import ../../shared-modules/workspaces.nix;  # Workspace list
};
```

**Usage in Modules**:
```nix
# home-modules/features/desktop/i3/config.nix
{ c, workspaces, ... }: {
  xsession.windowManager.i3.config = {
    colors.focused = {
      background = c.base0D;  # Uses injected color
      border = c.base0D;
    };
  };
}
```

**Benefits**:
- No need to thread variables through every import
- Cleaner function signatures
- Single source of truth for shared data

---

### Helper Library Pattern

**Pattern**: Centralized helper functions in `lib/default.nix`.

**Implementation**:
```nix
# lib/default.nix
{ lib }: {
  # Validate secret file exists
  validateSecretExists = path: builtins.pathExists path;
  
  # Validate secret is encrypted
  validateSecretEncrypted = path:
    let content = builtins.readFile path;
    in lib.hasPrefix "sops:" content || lib.hasPrefix "ENC[" content;
  
  # Generate i3 workspace bindings
  mkWorkspaceBindings = { mod, workspaces, commandPrefix }: ...;
}
```

**Usage**:
```nix
# nixos-modules/secrets.nix
let
  cfgLib = import ../lib { inherit lib; };
  validateAllSecrets =
    cfgLib.validateSecretExists githubSecretFile
    && cfgLib.validateSecretEncrypted githubSecretFile;
in { ... }
```

**Benefits**:
- DRY (Don't Repeat Yourself)
- Testable (helper functions can be unit tested)
- Reusable across NixOS and Home Manager modules

---

## Secret Management Architecture

### The Secret Chain

```
1. Age Key Generation
   ↓
2. Public Key → .sops.yaml
   ↓
3. Private Key → /var/lib/sops-nix/key.txt
   ↓
4. Secret Files → secrets/*.yaml (encrypted with sops)
   ↓
5. Build Time → Validation (cfgLib.validateSecretExists/Encrypted)
   ↓
6. Activation Time → Decryption (sops-nix)
   ↓
7. Runtime → /run/secrets/* (plaintext, restricted permissions)
   ↓
8. Service Access → Services read decrypted secrets
```

### Key Locations

| Component | Path | Purpose |
|-----------|------|---------|
| Age private key | `/var/lib/sops-nix/key.txt` | Decrypt secrets at activation |
| Age public key | `.sops.yaml` | Encrypt new secrets |
| Encrypted secrets | `secrets/*.yaml` | Version-controlled encrypted data |
| Decrypted secrets | `/run/secrets/*` | Runtime access for services |

### Build-Time Validation

**Problem**: sops-nix fails late (activation time) if secrets are missing or malformed.

**Solution**: Custom validation functions run at build time.

**Implementation**:
```nix
# lib/default.nix
validateSecretExists = path:
  if !builtins.pathExists path
  then throw "Secret file not found: ${path}"
  else true;

validateSecretEncrypted = path:
  let content = builtins.readFile path;
  in if !(lib.hasPrefix "sops:" content || lib.hasPrefix "ENC[" content)
     then throw "Secret file not encrypted: ${path}"
     else true;

# nixos-modules/secrets.nix
validateAllSecrets =
  cfgLib.validateSecretExists githubSecretFile
  && cfgLib.validateSecretEncrypted githubSecretFile
  && cfgLib.validateSecretExists resticSecretFile
  && cfgLib.validateSecretEncrypted resticSecretFile;

assertions = [
  {
    assertion = validateAllSecrets;
    message = "Secret validation passed";
  }
];
```

**Benefits**:
- Fails early (build time vs activation time)
- Clear error messages
- Prevents broken deployments

### Secret Permissions

Each secret is configured with specific ownership and permissions:

```nix
sops.secrets."github_ssh_key" = {
  sopsFile = githubSecretFile;
  owner = username;  # vino
  mode = "0600";  # Only owner can read/write
  path = "/home/${username}/.ssh/github";
};

sops.secrets."restic_password" = {
  sopsFile = resticSecretFile;
  key = "password";  # Extract specific key from YAML
  owner = "root";
  mode = "0400";  # Only root can read
};
```

### Disaster Recovery

**CRITICAL**: Without the age key, you CANNOT decrypt secrets!

**Backup Strategy**:
1. **Password manager** (1Password, Bitwarden) - Primary
2. **Encrypted USB drive** - Secondary
3. **Paper backup** (printed, stored in safe) - Emergency
4. **Trusted cloud** (encrypted before upload) - Off-site

See [docs/disaster-recovery.md](./disaster-recovery.md) for full procedures.

---

## Backup Strategy

### Multi-Layer Protection

| Layer | Tool | Scope | RTO | Purpose |
|-------|------|-------|-----|---------|
| **L1: Snapshots** | Snapper (BTRFS) | Filesystem | Minutes | Quick rollback, accidental deletions |
| **L2: Backups** | Restic | `/home` | Hours | Data recovery, longer retention |
| **L3: Generations** | NixOS | System config | Minutes | Configuration rollback |
| **L4: Git** | GitHub | Source code | Minutes | Config history, multi-host sync |

### Layer 1: BTRFS Snapshots (Snapper)

**Purpose**: Fast, local recovery for accidental deletions or config changes.

**Configuration**:
```nix
services.snapper.configs = {
  root = {
    SUBVOLUME = "/";
    TIMELINE_CREATE = false;  # Manual snapshots only
    TIMELINE_CLEANUP = true;
    TIMELINE_LIMIT_DAILY = "7";
  };
  home = {
    SUBVOLUME = "/home";
    NUMBER_LIMIT = "50";
  };
};

# Disable automatic timeline (reduces I/O)
systemd.timers.snapper-timeline.enable = false;
```

**Usage**:
```bash
# Manual snapshot before risky change
sudo snapper -c home create --description "Before refactor"

# List snapshots
sudo snapper -c home list

# Restore file
sudo cp /home/.snapshots/15/snapshot/vino/file.txt ~/
```

**Retention**: 7 daily (root), 50 total (home)

---

### Layer 2: Restic Backups

**Purpose**: Encrypted, incremental backups to external storage.

**Configuration**:
```nix
backup = {
  enable = true;
  repositories.home = {
    repository = "/mnt/backup/restic";  # 128GB USB drive (BTRFS)
    passwordFile = config.sops.secrets.restic_password.path;
    initialize = true;
    paths = ["/home"];
    exclude = [".cache" "node_modules" ".direnv" "target" ".snapshots"];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
      "--keep-yearly 3"
    ];
  };
};
```

**Schedule**: Daily at 00:03 with 1-hour random delay

**Why Local USB Instead of Cloud**:
- **Cost**: No recurring cloud storage fees
- **Speed**: No upload bottleneck, instant restore
- **Privacy**: Data never leaves device
- **Simplicity**: No account management, no internet dependency

**Tradeoff**: No off-site protection (acceptable for laptop with git-backed config)

**Future**: Consider adding S3/B2 for off-site disaster recovery.

---

### Layer 3: NixOS Generations

**Purpose**: System configuration rollback.

**How It Works**:
- Every `nixos-rebuild switch` creates a new generation
- Old generations kept until manually garbage collected
- GRUB bootloader lists all generations

**Usage**:
```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous
sudo nixos-rebuild switch --rollback

# Boot into specific generation (from GRUB menu)
```

**Retention**: Indefinite (until `nix-collect-garbage`)

---

### Layer 4: Git History

**Purpose**: Configuration source control, multi-host sync.

**Remote**: `https://github.com/6FaNcY9/nixos-config`

**Workflow**:
```bash
# Local changes
git add .
git commit -m "feat: add monitoring"
git push

# On another machine
git pull
nixos-rebuild switch --flake .#hostname
```

**Benefits**:
- Configuration backup (not just data)
- Audit trail (who changed what, when)
- Collaboration (PRs, reviews)
- Multi-host sharing (same modules, different hosts)

---

### Recovery Time Objectives

| Scenario | Layers Used | RTO |
|----------|-------------|-----|
| Accidentally deleted file | L1 (Snapshot) | 5 minutes |
| Broken config change | L3 (Generation) | 5 minutes |
| Lost data (1 week old) | L2 (Restic) | 15 minutes |
| Hardware failure | L2 (Restic) + L4 (Git) | 2-4 hours |
| Complete laptop loss | L4 (Git) + age key backup | 4-8 hours |

---

## Monitoring Approach

**Status**: Currently DISABLED for battery life (see rationale).

### Design

**Components**:
- **Prometheus**: Metrics collection
- **Grafana**: Visualization
- **node_exporter**: System metrics
- **Enhanced journald**: Structured logging

**Configuration**:
```nix
monitoring = {
  enable = false;  # DISABLED for battery life
  grafana.enable = false;
  logging.enhancedJournal = true;  # Keep enhanced logging (minimal overhead)
};
```

### Why Disabled?

**Impact Analysis**:
- **Battery drain**: 5-8% per hour (344MB RAM, constant CPU usage)
- **Use case**: Laptop, not server
- **Alternatives**: Manual checks with `journalctl`, `htop`, `iotop`

**Re-enable when**:
- Docked (AC power)
- Debugging performance issues
- Server deployment

**Access when enabled**:
- Grafana: `http://localhost:3000` (admin/admin)
- Prometheus: `http://localhost:9090`

### Future Enhancements

If monitoring is re-enabled:
- **Alerting**: Email/notification on critical events
- **Custom dashboards**: Application-specific metrics
- **Log aggregation**: Loki integration
- **Remote access**: Nginx reverse proxy + auth

---

## Development Workflow

### Local Development Loop

```bash
# 1. Make changes
$EDITOR nixos-modules/desktop.nix

# 2. Check formatting
nix fmt

# 3. Validate configuration
nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath

# 4. Test build (no activation)
nh os test -H bandit

# 5. Apply changes
nh os switch -H bandit

# 6. Verify
systemctl status <service>
journalctl -xe

# 7. Commit
git add .
git commit -m "feat: add X"
git push
```

### CI/CD Pipeline

**GitHub Actions** (`.github/workflows/check.yml`):

**On every PR/push**:
1. Format check (`nix fmt -- --check`)
2. Flake check (`nix flake check`)
3. Build system (`nix build .#nixosConfigurations.bandit.config.system.build.toplevel`)
4. Build home (`nix build .#homeConfigurations."vino@bandit".activationPackage`)

**Weekly** (`.github/workflows/update-flake.yml`):
1. Update flake inputs (`nix flake update`)
2. Create PR with updated `flake.lock`
3. Auto-merge if CI passes

**Benefits**:
- Early detection of broken changes
- No manual flake updates
- Confidence in main branch

---

### Branch Strategy

```
main (production-ready)
  ↑
  └─ dev (active development)
       ↑
       └─ feature/* (experiments)
```

**Workflow**:
1. Create feature branch from `dev`
2. Make changes, test locally
3. Push, create PR to `dev`
4. CI validates
5. Merge to `dev`
6. After testing, merge `dev` → `main`

**Worktrees** (current setup):
```
/home/vino/src/nixos-config       # main branch (stable)
/home/vino/src/nixos-config-dev   # dev branch (active)
```

---

## Multi-Host Strategy

### Current Setup (Single Host)

**Host**: `bandit` (Framework 13 AMD laptop)

**Configuration**:
```
nixos-configurations/bandit/
├── default.nix            # Host-specific overrides
└── hardware-configuration.nix  # Hardware detection (nixos-generate-config)
```

### Future Multi-Host Plan

**Planned Hosts**:
- `bandit` - Framework 13 AMD laptop (existing)
- `server-<name>` - Headless server (future)
- `droid-<name>` - Termux/nix-on-droid (future)

**Shared vs Host-Specific**:

| Config | Location | Scope |
|--------|----------|-------|
| Shared modules | `nixos-modules/` | All hosts |
| Role definitions | `nixos-modules/roles/*.nix` | Conditional (per role) |
| Host overrides | `nixos-configurations/<host>/` | Single host |
| Hardware config | `nixos-configurations/<host>/hardware-configuration.nix` | Single host |

**Example: Adding a Server**

```nix
# nixos-configurations/server-home/default.nix
{
  networking.hostName = "server-home";
  
  roles = {
    desktop = false;  # No GUI
    laptop = false;   # No power management
    server = true;    # SSH, fail2ban, monitoring
  };
  
  # Server-specific overrides
  monitoring.enable = true;  # Always-on monitoring
  backup.repositories.home.repository = "s3:...";  # Cloud backup
}
```

**Benefits**:
- One repo, multiple hosts
- Shared modules (desktop, backup, monitoring)
- Role-based inclusion (server gets SSH, laptop gets power management)
- Easy to add new hosts (copy template, adjust roles)

---

## Performance Considerations

### Build Time Optimization

**Strategy**: Maximize binary cache hits.

**Implementation**:
```nix
nix.settings = {
  substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];
  trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
};
```

**Impact**:
- **Before**: 30-45 minutes (full rebuild from source)
- **After**: 5-10 minutes (80%+ packages cached)

**Metrics**:
- nix-community has ~100k cached derivations
- Framework 13 specific packages pre-built
- Unstable channel = more cache coverage than stable

---

### Disk Space Management

**Strategy**: BTRFS compression + aggressive garbage collection.

**Implementation**:
```nix
# BTRFS mount options
options = [
  "compress=zstd:3"  # 30-50% space savings
  "noatime"          # Don't update access times
  "discard=async"    # SSD optimization
];

# Nix store optimization
nix.settings.auto-optimise-store = true;
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 30d";
};
```

**Impact**:
- BTRFS compression: ~40% space savings (25GB → 15GB for `/nix`)
- Garbage collection: Removes old generations after 30 days
- Store optimization: Hard-links identical files

---

### Memory Management

**Strategy**: zram for fast swap, swap-on-BTRFS for hibernate.

**Implementation**:
```nix
# zram (compressed RAM swap)
zramSwap = {
  enable = true;
  algorithm = "zstd";
  memoryPercent = 25;  # 25% of 32GB = 8GB compressed swap
};

# BTRFS swapfile (for hibernate)
swapDevices = [{ device = "/swap/swapfile"; }];

boot = {
  resumeDevice = "/dev/disk/by-uuid/...";
  kernelParams = ["resume_offset=1959063"];
};
```

**Benefits**:
- zram: 2-3x effective memory (32GB → ~40GB usable)
- Fast swap: In-memory, no disk I/O
- Hibernate: Swapfile on BTRFS, persists across reboots

---

### Battery Life Optimization

**Strategy**: Laptop-specific power management.

**Implementation**:
```nix
# Framework 13 AMD kernel params
boot.kernelParams = [
  "rtw89_pci.disable_aspm_l1=1"    # WiFi suspend fix
  "mem_sleep_default=s2idle"       # AMD sleep optimization
  "amdgpu.dcdebugmask=0x10"        # GPU stability
];

# Power profiles daemon
services.power-profiles-daemon.enable = true;

# Disable unused hardware
hardware.sensor.iio.enable = false;  # Light sensors, accelerometers

# Disable power-hungry services
monitoring.enable = false;  # 5-8% battery drain
systemd.timers.nixos-config-update.enable = false;  # Manual updates
```

**Impact**:
- Sleep mode: Stable suspend/resume
- WiFi: No connection drops after suspend
- Battery: ~8 hours mixed use (vs ~6 hours without optimizations)

---

## Future Architecture

### Planned Improvements

#### 1. Impermanence

**Goal**: Ephemeral root filesystem, persistent `/home` and `/nix`.

**Benefits**:
- Fresh system on every boot
- No state accumulation
- Easier debugging (always clean slate)

**Implementation**:
```nix
# Future: nixos-modules/impermanence.nix
environment.persistence."/persist" = {
  directories = [
    "/etc/nixos"
    "/var/lib/sops-nix"
    "/var/log"
  ];
  files = [
    "/etc/machine-id"
  ];
};

fileSystems."/" = {
  device = "tmpfs";
  fsType = "tmpfs";
  options = ["defaults" "size=2G" "mode=755"];
};
```

**Tradeoff**: Requires careful planning of what to persist.

---

#### 2. Flake Profiles

**Goal**: Multiple configurations from same flake (minimal, full, dev).

**Benefits**:
- Quick minimal install (no GUI, no extras)
- Full install with all features
- Dev install with tooling (compilers, debuggers)

**Implementation**:
```nix
# Future: flake.nix
nixosConfigurations = {
  bandit-minimal = { ... };  # Base system only
  bandit-full = { ... };     # All features enabled
  bandit-dev = { ... };      # + Development tools
};
```

---

#### 3. Off-Site Backups

**Goal**: Add cloud backup for disaster recovery.

**Implementation**:
```nix
# Future: nixos-configurations/bandit/default.nix
backup.repositories = {
  local = {
    repository = "/mnt/backup/restic";
    # ... existing config
  };
  cloud = {
    repository = "s3:s3.amazonaws.com/my-backups";
    environmentFile = "/run/secrets/aws-credentials";
    timerConfig.OnCalendar = "weekly";
  };
};
```

---

#### 4. Declarative User Secrets

**Goal**: Per-user secrets via Home Manager sops-nix module.

**Benefits**:
- User-specific SSH keys, GPG keys
- No need for NixOS-level secret permissions

**Implementation**:
```nix
# Future: home-configurations/vino/secrets.nix
sops.secrets."user_gpg_key" = {
  sopsFile = ../../secrets/vino.yaml;
  path = "${config.home.homeDirectory}/.gnupg/private.key";
};
```

---

#### 5. Automated Testing

**Goal**: Integration tests for critical functionality.

**Implementation**:
```nix
# Future: tests/default.nix
nixosTests.bandit = import ./bandit-test.nix {
  # Test: System boots, i3 starts, fingerprint works
};
```

**Benefits**:
- Catch regressions before deployment
- Confidence in major changes
- Documentation via tests

---

## Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Stylix Documentation](https://github.com/danth/stylix)
- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [ez-configs Documentation](https://github.com/ehllie/ez-configs)

---

**Last Updated**: 2026-01-31  
**System**: Framework 13 AMD (bandit)  
**NixOS Version**: unstable (26.05)
