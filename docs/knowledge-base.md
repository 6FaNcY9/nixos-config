# NixOS Config Knowledge Base

Comprehensive reference for all technologies used in this repository.
Generated from deep research — covers advanced patterns, not basics.

---

## 1. Nix Language & Flakes

### Priority System (Module Option Merging)

| Function | Priority Number | Wins Over |
|----------|----------------|-----------|
| `mkVMOverride` | 10 | Everything |
| `mkForce` | 50 | Normal, mkDefault |
| Normal (bare value) | 100 | mkDefault |
| `mkDefault` | 1000 | mkOptionDefault |
| `mkOptionDefault` | 1500 | Nothing |

- **Lower number = higher priority = wins**
- Equal priority + non-mergeable types = **ERROR** (conflict)
- Equal priority + mergeable types (lists, attrs) = merged
- Custom: `mkOverride 900 value` sets priority 900

### Fixed-Point Evaluation

```nix
# lib.fix: self-referencing attrset
fix = f: let x = f x; in x;

# Overlays use extends: compose overlay chains
extends = overlay: f: final:
  let prev = f final;
  in prev // overlay final prev;

# makeExtensible: package sets with .extend
pkgs = makeExtensible (self: { foo = 1; bar = self.foo + 1; });
pkgs.extend (final: prev: { foo = 10; })  # bar becomes 11
```

### Module System Internals

| Arg Mechanism | Available When | Use For |
|--------------|----------------|---------|
| `specialArgs` | During imports resolution (BEFORE eval) | Conditional imports |
| `_module.args` | In module bodies (AFTER imports) | Runtime config values |
| `extraSpecialArgs` | HM equivalent of specialArgs | Passing inputs to HM |

```nix
# mkIf: lazy conditional — doesn't eval RHS if false
# USE for config.* references (safe with missing options)
config = lib.mkIf cfg.enable { ... };

# optionalAttrs: EAGER — evaluates RHS always
# USE only when RHS is always valid (no config.* refs to missing options)
config = lib.optionalAttrs (builtins.pathExists ./foo) { ... };
```

### Underused Builtins

```nix
# genericClosure: transitive dependency resolution
builtins.genericClosure {
  startSet = [{ key = "a"; deps = ["b" "c"]; }];
  operator = item: map (d: { key = d; deps = getDeps d; }) item.deps;
}

# zipAttrsWith: multi-way merge with conflict resolution
lib.zipAttrsWith (name: values: lib.last values) [ attrA attrB attrC ]

# foldl': strict fold (prevents stack overflow on large lists)
builtins.foldl' (acc: x: acc + x) 0 largeList
```

### Flake Lock & Caching

- `narHash` = SHA256 of NAR serialization (content-addressed integrity)
- `follows` unifies inputs (single version); independent allows version skew
- Eval cache: `~/.cache/nix/eval-cache-v5/` (SQLite)
- Cache invalidated by: flake.lock changes, file mtime changes
- `--option eval-cache false` to bypass

### Overlay Order

- Applied left-to-right, **last wins**
- Debug: add logging overlay that compares `prev` vs `final` versions

### 2026 Updates

- Nix 2.31+: flake schemas (experimental), content-addressed derivations
- RFC 92 (flake schemas) accepted, RFC 158 (lazy trees) draft
- nixfmt-rfc-style v2.0 = official NixOS formatter

---

## 2. Flake-Parts

### Two Evaluation Contexts

| Context | Scope | Key Args |
|---------|-------|----------|
| **Top-Level** | Flake-wide | `self`, `inputs`, `withSystem`, `moduleWithSystem` |
| **perSystem** | Per-system | `system`, `pkgs`, `self'`, `inputs'`, `config` |

Transposition auto-maps: `perSystem.packages` → `flake.packages.<system>`

### Dev Partitions (Performance Optimization)

```nix
# Separate dev inputs from production builds
partitions.dev = {
  extraInputsFlake = ./dev;  # dev/flake.nix with treefmt, pre-commit inputs
  module.imports = [ ./dev/flake-module.nix ];
};
partitionedAttrs = {
  devShells = "dev";
  checks = "dev";
  formatter = "dev";
};
```

Prevents fetching treefmt/pre-commit inputs during `nixos-rebuild`.

### Writing Custom Modules

```nix
# Simple transposed option
mkTransposedPerSystemModule {
  name = "myOutput";
  option = mkOption { type = types.lazyAttrsOf types.package; };
  file = ./my-module.nix;
}

# Use lazyAttrsOf (not attrsOf) for deferred evaluation
```

### Debugging

```nix
# Enable REPL inspection
debug = true;
# Then: nix repl .#debug.aarch64-linux.options.packages.definitions
```

---

## 3. Ez-Configs

### Core Options

| Option | Purpose |
|--------|---------|
| `root` | Path for auto-discovery |
| `globalArgs` | Injected to ALL configs via specialArgs |
| `earlyModuleArgs` | Injected BEFORE module export |
| `nixos.modulesDirectory` | Where NixOS modules live |
| `nixos.configurationsDirectory` | Where host configs live |
| `home.modulesDirectory` | Where HM modules live |
| `userHomeModules` | Map users to HM configs per host |

### Auto-Discovery Convention

- `foo.nix` → module `foo`
- `foo/default.nix` → module `foo`
- `default.nix` auto-imported unless `importDefault = false`
- Linux hosts also auto-import `linux.nix`

### globalArgs Flow

```
globalArgs → nixos.specialArgs → nixosSystem { specialArgs }
           → home.extraSpecialArgs → homeManagerConfiguration { extraSpecialArgs }
```

### Multi-Host User Mapping

```nix
# Simple: same user config everywhere
userHomeModules = ["vino"];

# Advanced: different config per host
userHomeModules = { alice = "alice-workstation"; };
```

---

## 4. Home-Manager

### Activation Script Ordering

```
checkLinkTargets → writeBoundary → linkGeneration → reloadSystemd
```

Use `lib.hm.dag.entryAfter ["writeBoundary"] ''...''` for custom activations.

**Since 22.11**: PATH is reset during activation — use absolute paths:
```nix
"${pkgs.coreutils}/bin/mkdir" NOT "mkdir"
```

### File Management Decision Matrix

| API | Location | When to Use |
|-----|----------|-------------|
| `programs.*` | App-specific | Type-checked, managed (PREFERRED) |
| `xdg.configFile` | `~/.config/` | XDG-compliant app config |
| `home.file` | Anywhere in `$HOME` | Non-standard locations |
| `config.lib.file.mkOutOfStoreSymlink` | Any | Mutable symlinks |

### Integration Modes

| Mode | `useGlobalPkgs` | `useUserPackages` | Effect |
|------|-----------------|-------------------|--------|
| Isolated | false | false | Separate nixpkgs eval |
| Shared (recommended) | true | true | Shared eval, better cache |
| Hybrid | true | false | Shared pkgs, user PATH |

### Debugging

```bash
home-manager build  # Inspect result/activate
nix store diff-closures /nix/var/nix/profiles/per-user/$USER/home-manager  # Generation diff
```

---

## 5. Nixvim

### Plugin Management

| Approach | When | Example |
|----------|------|---------|
| Built-in nixvim option | Plugin has nixvim module | `plugins.telescope.enable = true;` |
| extraPlugins | Nixpkgs plugin, no nixvim module | `extraPlugins = [pkgs.vimPlugins.X];` |
| Custom build | Not in nixpkgs | `pkgs.vimUtils.buildVimPlugin { ... }` |

### Lazy Loading (lz.n)

```nix
plugins.telescope = {
  enable = true;
  lazyLoad.settings = {
    cmd = ["Telescope"];           # Load on command
    keys = [{ __unkeyed = "<leader>ff"; }];  # Load on keymap
  };
};
```

### Performance

- `performance.byteCompileLua.enable = true` + `configs = true`
- `extraConfigLuaPre` for early setup (before plugins)
- Lazy-load non-essential plugins (telescope, neo-tree)

### Raw Lua in Nix

```nix
# __raw escapes to Lua
keymaps = [{
  key = "<leader>f";
  action.__raw = ''function() require("telescope.builtin").find_files() end'';
}];
```

---

## 6. Stylix

### Base16 Color Slots

| Slot | Role (Dark Theme) |
|------|-------------------|
| base00-03 | Background shades (darkest → lightest) |
| base04-07 | Foreground shades (lightest → darkest) |
| base08 | Red (variables, errors) |
| base09 | Orange (integers, constants) |
| base0A | Yellow (classes, search) |
| base0B | Green (strings, success) |
| base0C | Cyan (support, regex) |
| base0D | Blue (functions, headings) |
| base0E | Purple (keywords, tags) |
| base0F | Brown (deprecated, embedded) |

### Override Rules

- Stylix sets values at **default priority (1000)**
- Non-color options (padding, timeout) → plain values work (priority 100 < 1000)
- Color options (background, foreground, frame_color) → Stylix also sets at 1000 → **CONFLICT**
- Use `mkForce` (priority 50) to override Stylix colors

### Writing Custom Targets

```nix
mkTarget {
  name = "myApp";
  humanName = "My App";
  config = [
    (static (colors: { settings.colors = colors.withHashtag; }))
    (fonts: { settings.font = fonts.monospace.name; })
    (opacity: { settings.alpha = opacity.terminal; })
  ];
}
```

---

## 7. Sops-Nix

### Secret Definition

```nix
sops.secrets.my-secret = {
  sopsFile = ./secrets/secrets.yaml;
  format = "yaml";           # yaml|json|binary|ini|dotenv
  key = "nested/path";       # Path within file
  mode = "0440";
  owner = config.users.users.myuser.name;
  restartUnits = ["myservice.service"];  # Auto-restart on change
  neededForUsers = true;      # Decrypt BEFORE user creation
};
```

### Templates (Multi-Secret Config Files)

```nix
sops.templates."db-config".content = ''
  DB_HOST=localhost
  DB_PASSWORD=${config.sops.placeholder.db-password}
  API_KEY=${config.sops.placeholder.api-key}
'';
```

### Age Key Management

```nix
sops.age = {
  sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
  keyFile = "/var/lib/sops-nix/key.txt";
  generateKey = true;
};
```

### Key Rotation

```bash
# After updating .sops.yaml with new keys:
sops updatekeys secrets/secrets.yaml
```

---

## 8. Security Hardening

### Kernel Sysctl (Desktop)

```nix
boot.kernel.sysctl = {
  # Pointer/info leak prevention
  "kernel.kptr_restrict" = 2;
  "kernel.dmesg_restrict" = 1;
  "kernel.yama.ptrace_scope" = 1;

  # Disable dangerous features
  "kernel.kexec_load_disabled" = 1;
  "net.core.bpf_jit_enable" = false;

  # Network hardening
  "net.ipv4.conf.all.rp_filter" = 1;
  "net.ipv4.conf.all.accept_redirects" = 0;
  "net.ipv4.conf.all.send_redirects" = 0;
  "net.ipv4.conf.all.log_martians" = 1;
  "net.ipv4.tcp_syncookies" = 1;
  "net.ipv4.icmp_echo_ignore_broadcasts" = 1;

  # Filesystem protection
  "fs.protected_symlinks" = 1;
  "fs.protected_hardlinks" = 1;
  "kernel.randomize_va_space" = 2;
};
```

### Systemd Service Hardening Template

```nix
systemd.services.myservice.serviceConfig = {
  ProtectSystem = "strict";
  ProtectHome = true;
  PrivateTmp = true;
  DynamicUser = true;
  NoNewPrivileges = true;
  MemoryDenyWriteExecute = true;
  ProtectKernelTunables = true;
  ProtectKernelModules = true;
  ProtectControlGroups = true;
  RestrictNamespaces = true;
  SystemCallFilter = ["@system-service" "~@privileged"];
};
```

### Secure Boot (Lanzaboote)

```nix
boot.lanzaboote = {
  enable = true;
  pkiBundle = "/var/lib/sbctl";
};
boot.loader.systemd-boot.enable = lib.mkForce false;
```

---

## 9. Btrfs + Snapper

### Optimal Mount Options

| Subvolume | Options |
|-----------|---------|
| `/` | `noatime,compress=zstd:3,space_cache=v2,discard=async` |
| `/nix` | `noatime,compress=zstd:1` (fast compression for store) |
| `/home` | `compress=zstd:3` |
| `/swap` | `nodatacow,nocompress` (REQUIRED for swapfile) |

### Snapper Retention

```nix
services.snapper.configs.root = {
  SUBVOLUME = "/";
  TIMELINE_CREATE = true;
  TIMELINE_CLEANUP = true;
  TIMELINE_LIMIT_HOURLY = 10;
  TIMELINE_LIMIT_DAILY = 10;
  TIMELINE_LIMIT_WEEKLY = 0;
  TIMELINE_LIMIT_MONTHLY = 10;
  TIMELINE_LIMIT_YEARLY = 0;
  SPACE_LIMIT = "0.25";    # Max 25% disk for snapshots
};
```

### Recovery

```bash
snapper -c root rollback 123         # Quick rollback
mount -o subvol=/.snapshots/123/snapshot /mnt  # Mount snapshot
```

---

## 10. Restic Backup

### NixOS Module

```nix
services.restic.backups.daily = {
  repository = "s3:s3.amazonaws.com/bucket";
  passwordFile = config.sops.secrets.restic-password.path;
  environmentFile = config.sops.secrets.restic-env.path;
  paths = ["/home" "/etc" "/var/lib"];
  exclude = ["/nix" "/tmp" "**/.cache" "**/node_modules"];
  timerConfig = {
    OnCalendar = "daily";
    RandomizedDelaySec = "1h";
    Persistent = true;
  };
  pruneOpts = ["--keep-daily 7" "--keep-weekly 5" "--keep-monthly 12"];
  createWrapper = true;  # Adds restic-daily to PATH
  initialize = true;
};
```

---

## 11. Tailscale

### Key Options

```nix
services.tailscale = {
  enable = true;
  port = 41641;
  useRoutingFeatures = "client";  # none|client|server|both
  # client = loose rp_filter
  # server = IP forwarding
  # both = both
};

networking.firewall.trustedInterfaces = ["tailscale0"];
```

### Features

- **Exit node**: `useRoutingFeatures = "server"` + `--advertise-exit-node`
- **Subnet routing**: `--advertise-routes=192.168.1.0/24`
- **MagicDNS**: Auto with systemd-resolved (`hostname.tailnet.ts.net`)
- **Tailscale SSH**: `--ssh` flag (uses Tailscale ACLs)

---

## 12. Devshell + Treefmt + Pre-Commit

### Devshell Commands

```nix
devshells.default = {
  commands = [
    { name = "fmt"; command = "treefmt"; help = "Format code"; category = "formatters"; }
    { name = "check"; command = "nix flake check"; help = "Run checks"; category = "build"; }
  ];
  packages = [ pkgs.git pkgs.jq ];
  env = [
    { name = "EDITOR"; value = "nvim"; }
  ];
};
```

### Treefmt: Alejandra vs nixfmt-rfc-style

- **nixfmt-rfc-style**: Official NixOS formatter (RFC 166), recommended for new projects
- **Alejandra**: Community formatter, less active since 2023, fine for existing projects
- Keep alejandra if already using it; switch for nixpkgs contributions

### Pre-Commit + Treefmt Integration

Use treefmt hook instead of individual formatters to avoid double-formatting:
```nix
pre-commit.hooks = {
  treefmt.enable = true;    # Formats everything
  statix.enable = true;     # Linter (not formatter)
  deadnix.enable = true;    # Dead code detector
};
```

---

## 13. Desktop Stack

### i3 Advanced Features

- **Scratchpads**: `move scratchpad` + `scratchpad show` + criteria matching
- **Marks**: `mark --toggle X` + `[con_mark=X] focus` + `swap container with mark X`
- **IPC scripting**: `i3-msg`, python i3ipc library for reactive automation
- **Criteria**: `[class="Firefox" urgent=latest]` for window targeting

### Polybar Performance

- Increase poll-interval on battery (60s for scripts, 2s for CPU)
- `throttle-output = 50ms` for high-frequency modules
- IPC modules: `polybar-msg hook <name> <hook-num>` for event-driven updates

### Rofi Script Modi

```bash
# Power menu as custom modi
rofi -show power -modi "power:~/.config/rofi/power-menu.sh"
```

### Tmux Plugin Management (Nix, not tpm)

```nix
programs.tmux.plugins = with pkgs.tmuxPlugins; [
  sensible vim-tmux-navigator yank
  { plugin = resurrect; extraConfig = "set -g @resurrect-capture-pane-contents 'on'"; }
  { plugin = continuum; extraConfig = "set -g @continuum-save-interval '15'"; }
];
```

---

## 14. CI/CD for NixOS Flakes

### GitHub Actions Template

```yaml
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@v14
      - uses: DeterminateSystems/magic-nix-cache-action@v8
      - run: nix flake check --all-systems
      - run: nix build
```

### Cachix Strategy

- Push on merge to main only (not every PR)
- Cache: devShells, packages, flake check outputs
- `nix build .#X --json | jq -r '.[].outputs.out' | cachix push cache-name`
