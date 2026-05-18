# dustinlyons/nixos-config — Architecture & Patterns Analysis

**Repository**: https://github.com/dustinlyons/nixos-config  
**Latest commit**: d2bc630e4800c682b3ff89f86d1458514f7084e9  
**Analysis date**: May 13, 2026

---

## 1. TOP-LEVEL LAYOUT

```
dustin-nixos/
├── flake.nix                 # Main entry point (184 lines)
├── flake.lock               # Locked dependencies
├── README.md                # Extensive onboarding docs
├── LICENSE
├── apps/                    # Flake apps (build/apply/clean scripts)
│   ├── x86_64-linux/
│   ├── aarch64-linux/       # Symlink to x86_64-linux
│   ├── x86_64-darwin/
│   ├── aarch64-darwin/      # Symlink to x86_64-darwin
│   └── README.md
├── hosts/                   # Configuration entry points per OS
│   ├── darwin/
│   │   └── default.nix      # Darwin (macOS) root config
│   └── nixos/
│       ├── default.nix      # Generic NixOS root config
│       ├── garfield/        # Host-specific overrides (x86_64-linux)
│       └── firmware/        # (directory, likely host-specific)
├── modules/                 # Reusable feature modules
│   ├── shared/              # Cross-platform modules
│   │   ├── default.nix      # Overlay loader + nixpkgs config
│   │   ├── packages.nix     # Shared package list
│   │   ├── home-manager.nix # Shared HM programs (502 lines)
│   │   ├── emacs.nix        # Custom Emacs build
│   │   ├── fonts.nix        # Font definitions
│   │   ├── files.nix        # Shared dotfiles
│   │   ├── cachix/          # Cachix config
│   │   ├── config/          # Shared config files (p10k.zsh, etc.)
│   │   └── README.md
│   ├── nixos/               # NixOS-only modules
│   │   ├── home-manager.nix # NixOS HM integration (262 lines)
│   │   ├── packages.nix     # NixOS-specific packages
│   │   ├── kde-config.nix   # KDE Plasma config (303 lines)
│   │   ├── systemd.nix      # Systemd services/timers
│   │   ├── secrets.nix      # Agenix secrets (NixOS)
│   │   ├── github-runner.nix # GitHub Actions runner
│   │   ├── home-assistant.nix
│   │   ├── n8n.nix          # Automation platform
│   │   ├── atlas.nix        # (unknown service)
│   │   ├── files.nix        # NixOS-specific dotfiles
│   │   ├── garfield-packages.nix # Host-specific packages
│   │   ├── scripts/         # Helper scripts
│   │   ├── github-runner/   # GitHub runner submodules
│   │   └── README.md
│   └── darwin/              # macOS-only modules
│       ├── home-manager.nix # Darwin HM integration (96 lines)
│       ├── packages.nix     # Darwin-specific packages
│       ├── secrets.nix      # Agenix secrets (Darwin)
│       ├── casks.nix        # Homebrew casks
│       ├── files.nix        # Darwin-specific dotfiles
│       ├── dock/            # macOS dock configuration (80 lines)
│       └── README.md
├── overlays/                # Custom package overlays
│   ├── cider-appimage.nix
│   ├── obsidian-appimage.nix
│   ├── tableplus-appimage.nix
│   ├── wowup-appimage.nix
│   ├── playwright.nix
│   ├── phpstorm.nix
│   ├── linear-cli.nix
│   ├── newrelic-cli.nix
│   ├── sentry-cli.nix
│   └── README.md
├── systemd/                 # Systemd service definitions
│   ├── bitcoin-noobs-crypto.service
│   ├── bitcoin-noobs-crypto.timer
│   ├── bitcoin-noobs-news.service
│   └── bitcoin-noobs-news.timer
├── templates/               # Flake templates for users
│   ├── starter/             # Minimal starter config
│   └── starter-with-secrets/
├── tests/                   # Test suite
│   └── garage-analyzer/
└── .github/                 # GitHub Actions workflows
```

**Key insight**: Clear separation of concerns with **platform-specific (darwin/nixos) + shared (shared/)** pattern. Overlays are auto-loaded.

---

## 2. HOST/USER SPLIT PATTERN

### Darwin (macOS) Configuration
**Entry**: `hosts/darwin/default.nix`

```nix
{ agenix, config, pkgs, ... }:
let 
  user = "dustin";
  myEmacs = import ../../modules/shared/emacs.nix { inherit pkgs; };
in
{
  imports = [
    ../../modules/darwin/secrets.nix
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
    agenix.darwinModules.default
  ];
  # ... nix.settings, environment.systemPackages, system.defaults, etc.
}
```

**Pattern**:
- Single user hardcoded: `user = "dustin"`
- Imports are **explicit** (not auto-discovered)
- Secrets via agenix (optional)
- Home Manager integrated via `home-manager.darwinModules.home-manager`

### NixOS Configuration
**Entry**: `hosts/nixos/default.nix` (generic) + `hosts/nixos/garfield/` (host-specific)

```nix
{ config, lib, pkgs, modulesPath, user, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../modules/shared
    ../../modules/nixos/systemd.nix
  ];
  # Hardware config, boot settings, filesystems
}
```

**Host-specific override**: `hosts/nixos/garfield/` (separate directory for host-specific tweaks)

**Pattern**:
- Generic NixOS config in `default.nix`
- Host-specific configs in subdirectories (e.g., `garfield/`)
- Flake outputs define **both platform-based + named host configs**:
  ```nix
  nixosConfigurations = 
    # Platform-based (x86_64-linux, aarch64-linux)
    nixpkgs.lib.genAttrs linuxSystems (system: ...)
    // # Named hosts (garfield, firmware, etc.)
    { garfield = nixpkgs.lib.nixosSystem { ... }; }
  ```

**Takeaway**: Dual approach—platform-generic + named hosts. Allows `nix flake show` to list both `nixosConfigurations.x86_64-linux` and `nixosConfigurations.garfield`.

---

## 3. MODULE ORGANIZATION & PATTERNS

### 3.1 Shared Modules (`modules/shared/`)

**Auto-loaded overlays** in `modules/shared/default.nix`:
```nix
overlays = let
  path = ../../overlays;
  hostname = config.networking.hostName or "";
  excludeForHost = {
    "garfield" = [ "cider-appimage.nix" "obsidian-appimage.nix" "curseforge-appimage.nix" ];
  };
  excludedFiles = excludeForHost.${hostname} or [];
in with builtins;
map (n: import (path + ("/" + n)))
    (filter (n: (match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix"))) 
             && !(elem n excludedFiles))
            (attrNames (readDir path)))
```

**Key**: Overlays are **dynamically discovered** from filesystem + **host-aware exclusions**.

### 3.2 Home-Manager Integration

**Shared HM programs** (`modules/shared/home-manager.nix`, 502 lines):
- Defines common programs: zsh, direnv, git, etc.
- Platform-aware using `lib.mkIf pkgs.stdenv.hostPlatform.isLinux` / `.isDarwin`
- Imported by both NixOS and Darwin HM configs

**NixOS HM** (`modules/nixos/home-manager.nix`, 262 lines):
- Merges shared programs: `shared-programs // { gpg.enable = true; ... }`
- Adds platform-specific: rofi, KDE Plasma config, Playwright env vars
- Imports shared files: `shared-files // import ./files.nix { ... }`

**Darwin HM** (`modules/darwin/home-manager.nix`, 96 lines):
- Much smaller—mostly delegates to shared
- Adds Darwin-specific programs (e.g., dock configuration)

**Pattern**: **Composition over inheritance**—shared config is imported as a set, then merged with `//` operator.

### 3.3 Package Management

**Shared packages** (`modules/shared/packages.nix`, 138 lines):
- Defines custom Python/PHP with extensions
- Alphabetically sorted list of ~100 packages
- Reused by both platforms

**Platform-specific packages**:
- `modules/nixos/packages.nix`: Adds NixOS-only (rofi, KDE tools, custom scripts)
- `modules/darwin/packages.nix`: Adds Darwin-only (dockutil, fswatch)

**Pattern**: `shared-packages ++ [ platform-specific-packages ]`

### 3.4 Secrets Management (Agenix)

**NixOS secrets** (`modules/nixos/secrets.nix`):
```nix
{ config, pkgs, agenix, secrets, ... }:
let user = "dustin"; in
{
  age = {
    identityPaths = [ "/home/${user}/.ssh/id_ed25519" ];
    secrets = {
      "syncthing-cert" = {
        symlink = true;
        path = "/home/${user}/.config/syncthing/cert.pem";
        file = "${secrets}/felix-syncthing-cert.age";
        mode = "600";
        owner = "${user}";
        group = "users";
      };
      # ... more secrets
    };
  };
}
```

**Darwin secrets** (`modules/darwin/secrets.nix`):
- Same pattern, but paths use `/Users/${user}/Library/...`
- Groups use `staff` instead of `users`

**Key insight**: Secrets are **imported as a separate module**, not mixed into home-manager or system config. Agenix input is a **separate git+ssh repo** (`git+ssh://git@github.com/dustinlyons/nix-secrets.git`).

---

## 4. FLAKE ARCHITECTURE

### Inputs (17 dependencies)
```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  home-manager.url = "github:nix-community/home-manager";
  agenix.url = "github:ryantm/agenix";
  darwin.url = "github:LnL7/nix-darwin/master";
  plasma-manager.url = "github:nix-community/plasma-manager";
  nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  disko.url = "github:nix-community/disko";
  chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  secrets = { url = "git+ssh://git@github.com/dustinlyons/nix-secrets.git"; flake = false; };
  # ... homebrew taps (non-flake)
  # ... claude-desktop, claude-code, plasma-manager
};
```

### Outputs
```nix
outputs = { self, darwin, home-manager, nixpkgs, ... } @inputs:
  let
    user = "dustin";
    linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
    darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
  in
  {
    templates = { starter = ...; starter-with-secrets = ...; };
    devShells = forAllSystems devShell;
    apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;
    darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system: darwin.lib.darwinSystem { ... });
    nixosConfigurations = 
      nixpkgs.lib.genAttrs linuxSystems (system: nixpkgs.lib.nixosSystem { ... })
      // { garfield = nixpkgs.lib.nixosSystem { ... }; };
  };
```

**Key patterns**:
- **`specialArgs = inputs // { inherit user; }`** — passes all flake inputs + hardcoded user to modules
- **Dual nixosConfigurations**: platform-generic + named hosts
- **Apps per system**: build/apply/clean/install scripts

---

## 5. OVERLAYS PATTERN

**Auto-discovery** in `modules/shared/default.nix`:
- Scans `overlays/` directory
- Loads `.nix` files or `default.nix` in subdirectories
- Host-aware exclusions (e.g., exclude gaming apps on server)
- Fetches emacs-overlay from GitHub (hardcoded SHA)
- Adds claude-code overlay

**Overlay examples**:
- **AppImage wrappers** (Cider, Obsidian, WowUp): Use `appimageTools.wrapType2`
- **CLI wrappers** (linear-cli): Use `writeShellScriptBin`
- **Package overrides** (phpstorm, playwright): Override nixpkgs versions

**Takeaway**: Overlays are **modular, discoverable, and host-aware**. No manual registration needed.

---

## 6. STRENGTHS (ELEGANT PATTERNS)

### ✅ 1. **Clear Platform Separation**
- `modules/shared/` vs `modules/darwin/` vs `modules/nixos/`
- Easy to understand what runs where
- Shared code is genuinely reusable

### ✅ 2. **Composition-Based HM Integration**
- Shared HM programs defined once, merged with `//` operator
- No inheritance complexity
- Platform-specific additions are explicit

### ✅ 3. **Auto-Discovered Overlays**
- Overlays loaded dynamically from filesystem
- Host-aware exclusions (don't load gaming apps on servers)
- No manual registration in flake.nix

### ✅ 4. **Dual Host Strategy**
- Platform-generic configs (`x86_64-linux`, `aarch64-darwin`)
- Named host configs (`garfield`) for specific machines
- Both available in `nix flake show`

### ✅ 5. **Secrets as Separate Module**
- Agenix config isolated in `modules/*/secrets.nix`
- Secrets are a separate git+ssh input
- Easy to disable or swap out

### ✅ 6. **Extensive Documentation**
- README with step-by-step install instructions
- Per-directory READMEs (overlays, apps, modules)
- Flake templates for new users

### ✅ 7. **Custom Scripts in Overlays**
- Rofi launcher, cheatsheet viewer, etc. defined as `writeShellScriptBin`
- Packaged as overlays, not scattered in configs

---

## 7. WEAKNESSES & TRADEOFFS

### ⚠️ 1. **Hardcoded User**
- User is hardcoded as `"dustin"` in multiple places
- Not suitable for multi-user systems without refactoring
- Would need to parameterize via flake inputs or module options

### ⚠️ 2. **Large Monolithic Modules**
- `modules/shared/home-manager.nix`: 502 lines
- `modules/nixos/kde-config.nix`: 303 lines
- No internal structure (no sub-modules within these files)
- Hard to find specific settings

### ⚠️ 3. **Platform Detection via Hostname**
- Overlay exclusions use `config.networking.hostName`
- Requires hostname to be set before overlays load
- Fragile if hostname changes or is not set

### ⚠️ 4. **No Feature Flags/Options**
- No `options.features.*.enable` pattern
- Everything is imported and enabled by default
- Hard to selectively disable features

### ⚠️ 5. **Secrets Repo is Separate SSH**
- Requires SSH key setup before first build
- Not suitable for CI/CD without additional tooling
- Complicates onboarding for new users

### ⚠️ 6. **Limited Test Coverage**
- Only one test directory (`tests/garage-analyzer/`)
- No validation of module outputs
- No regression tests for configurations

### ⚠️ 7. **Mixing Concerns in Home-Manager**
- HM config includes both program settings + dotfiles + systemd services
- Hard to reason about what's HM vs system config

---

## 8. REFACTOR-RELEVANT INSIGHTS

### For Your NixOS Config Refactor

#### **Pattern to Adopt**
1. **Explicit module imports** (Darwin approach) — easier to track than auto-discovery
2. **Composition-based HM** — use `//` merging instead of inheritance
3. **Separate secrets module** — isolate agenix config
4. **Named host configs** — support both generic + specific machines
5. **Auto-discovered overlays** — reduces boilerplate in flake.nix

#### **Pattern to Avoid**
1. **Hardcoded users** — parameterize from the start
2. **Monolithic modules** — break into sub-modules at ~150 lines
3. **Hostname-based feature detection** — use explicit options instead
4. **No feature flags** — add `options.features.*.enable` pattern early

#### **Specific Techniques to Borrow**
- **Overlay auto-discovery**: Use `builtins.readDir` + `filter` + `map` (see `modules/shared/default.nix`)
- **Host-aware exclusions**: Store exclusions in a set keyed by hostname
- **Custom scripts as overlays**: Package shell scripts via `writeShellScriptBin` in overlays
- **Dual nixosConfigurations**: Use `genAttrs` for platforms + `//` to merge named hosts
- **Flake templates**: Provide starter configs for new users

---

## 9. SPECIFIC FILE REFERENCES

| File | Lines | Purpose | Refactor Relevance |
|------|-------|---------|-------------------|
| `flake.nix` | 184 | Main entry point | Study dual nixosConfigurations pattern |
| `modules/shared/default.nix` | 44 | Overlay loader | Adopt auto-discovery pattern |
| `modules/shared/home-manager.nix` | 502 | Shared HM programs | Break into sub-modules |
| `modules/shared/packages.nix` | 138 | Shared packages | Alphabetical sorting + custom derivations |
| `modules/nixos/home-manager.nix` | 262 | NixOS HM integration | Study composition pattern |
| `modules/nixos/kde-config.nix` | 303 | KDE Plasma config | Break into sub-modules |
| `modules/nixos/secrets.nix` | ~40 | Agenix setup | Adopt secrets isolation pattern |
| `modules/darwin/home-manager.nix` | 96 | Darwin HM integration | Study minimal HM config |
| `overlays/README.md` | — | Overlay documentation | Document your overlay patterns |
| `hosts/nixos/default.nix` | ~150 | Generic NixOS config | Study hardware + boot patterns |
| `hosts/darwin/default.nix` | ~100 | Darwin config | Study macOS-specific settings |

---

## 10. TOP 5 TAKEAWAYS FOR YOUR REFACTOR

1. **Use explicit module imports** (not auto-discovery) for clarity, but **auto-discover overlays** to reduce flake.nix boilerplate.

2. **Parameterize the user** from the start—don't hardcode. Use `specialArgs` to pass user from flake inputs or command line.

3. **Break monolithic modules** at ~150 lines. Use sub-modules or separate files for distinct concerns (e.g., `kde-config/` subdirectory).

4. **Adopt composition-based HM** — define shared programs once, merge with `//` operator in platform-specific configs.

5. **Isolate secrets** in a separate module + input. Make agenix optional (can be disabled or swapped for sops-nix).

---

## REPO METADATA

- **License**: MIT (inferred from LICENSE file)
- **Last commit**: d2bc630 (May 2026)
- **Platforms**: macOS (darwin) + NixOS (linux)
- **Flake inputs**: 17 (nixpkgs, home-manager, darwin, agenix, disko, chaotic, etc.)
- **Module count**: ~30 .nix files
- **Total LoC**: ~2,875 lines (modules only, excludes flake.nix + hosts)
- **Largest module**: `modules/shared/home-manager.nix` (502 lines)
