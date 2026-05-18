# Refactor Quick Reference — dustinlyons/nixos-config Patterns

**Source**: https://github.com/dustinlyons/nixos-config (commit d2bc630)  
**Use this** to guide your own NixOS config refactoring.

---

## ARCHITECTURE AT A GLANCE

```
hosts/                          # OS-specific entry points
├── darwin/default.nix         # macOS root config
└── nixos/
    ├── default.nix            # Generic NixOS config
    └── garfield/              # Host-specific overrides

modules/                        # Reusable feature modules
├── shared/                     # Cross-platform (both Darwin + NixOS)
│   ├── default.nix           # Overlay auto-loader + nixpkgs config
│   ├── home-manager.nix      # Shared HM programs (502 lines)
│   ├── packages.nix          # Shared packages
│   ├── emacs.nix, fonts.nix, files.nix
│   └── config/               # Config files (p10k.zsh, etc.)
├── nixos/                     # NixOS-only
│   ├── home-manager.nix      # NixOS HM integration
│   ├── kde-config.nix        # KDE Plasma (303 lines)
│   ├── packages.nix, secrets.nix, systemd.nix
│   └── github-runner.nix, home-assistant.nix, n8n.nix
└── darwin/                    # macOS-only
    ├── home-manager.nix      # Darwin HM integration (96 lines)
    ├── packages.nix, secrets.nix, casks.nix
    └── dock/default.nix      # macOS dock config

overlays/                       # Custom package overlays (auto-discovered)
├── cider-appimage.nix
├── playwright.nix, phpstorm.nix
└── README.md                  # Overlay patterns

flake.nix                       # 184 lines, defines outputs + inputs
```

---

## KEY PATTERNS TO ADOPT

### 1. AUTO-DISCOVERED OVERLAYS

**File**: `modules/shared/default.nix` (lines 21-42)

```nix
overlays = let
  path = ../../overlays;
  hostname = config.networking.hostName or "";
  excludeForHost = {
    "garfield" = [ "cider-appimage.nix" "obsidian-appimage.nix" ];
  };
  excludedFiles = excludeForHost.${hostname} or [];
in with builtins;
map (n: import (path + ("/" + n)))
    (filter (n: (match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix")))
             && !(elem n excludedFiles))
            (attrNames (readDir path)))
```

**Benefit**: Add overlays without touching flake.nix. Host-aware exclusions.

---

### 2. COMPOSITION-BASED HOME-MANAGER

**Pattern**: Define shared programs once, merge with `//` operator.

**File**: `modules/nixos/home-manager.nix` (line 6-8)

```nix
let
  shared-programs = import ../shared/home-manager.nix { inherit config pkgs lib; };
  shared-files = import ../shared/files.nix { inherit config pkgs; };
in
{
  home = { ... };
  programs = shared-programs // { 
    gpg.enable = true;
    rofi = { ... };  # NixOS-specific additions
  };
}
```

**Benefit**: Shared config defined once, platform-specific additions are explicit.

---

### 3. DUAL NIXOS CONFIGURATIONS

**File**: `flake.nix` (lines 140-175)

```nix
nixosConfigurations = 
  # Platform-based (x86_64-linux, aarch64-linux)
  nixpkgs.lib.genAttrs linuxSystems (system:
    nixpkgs.lib.nixosSystem { ... }
  )
  // # Named host configurations (garfield, firmware)
  {
    garfield = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./hosts/nixos/garfield ];
    };
  };
```

**Benefit**: Support both generic platforms + specific machines. Both appear in `nix flake show`.

---

### 4. ISOLATED SECRETS MODULE

**File**: `modules/nixos/secrets.nix`

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
    };
  };
}
```

**Benefit**: Secrets isolated in one module. Easy to disable or swap for sops-nix.

---

### 5. PLATFORM-SPECIFIC PACKAGES

**File**: `modules/nixos/packages.nix` (line 1-5)

```nix
{ pkgs, inputs, config ? null }:
with pkgs;
let
  shared-packages = import ../shared/packages.nix { inherit pkgs; };
  hostname = if config != null then (config.networking.hostName or "") else "";
in
shared-packages ++ [
  # NixOS-specific packages
  rofi
  kdePackages.kde-cli-tools
]
```

**Benefit**: Shared packages imported, platform-specific packages appended.

---

## PATTERNS TO AVOID

### ❌ 1. Hardcoded Users

**Current**: `let user = "dustin";` hardcoded in multiple files

**Better**: Parameterize via flake inputs or module options
```nix
# In flake.nix
specialArgs = inputs // { inherit user; };

# In modules, receive as argument
{ config, pkgs, user, ... }:
```

---

### ❌ 2. Monolithic Modules

**Current**: `modules/shared/home-manager.nix` is 502 lines

**Better**: Break into sub-modules at ~150 lines
```
modules/shared/home-manager/
├── default.nix          # Imports all sub-modules
├── shell.nix            # zsh, direnv, etc.
├── git.nix              # git config
├── editor.nix           # vim, emacs, etc.
└── dev-tools.nix        # node, python, etc.
```

---

### ❌ 3. Hostname-Based Feature Detection

**Current**: Overlay exclusions use `config.networking.hostName`

**Better**: Use explicit feature flags
```nix
options.features.gaming.enable = lib.mkEnableOption "Gaming packages";
config = lib.mkIf cfg.gaming.enable { ... };
```

---

### ❌ 4. No Feature Flags

**Current**: Everything is imported and enabled by default

**Better**: Add `options.features.*.enable` pattern early
```nix
options.features = {
  kde.enable = lib.mkEnableOption "KDE Plasma";
  gaming.enable = lib.mkEnableOption "Gaming tools";
  devops.enable = lib.mkEnableOption "DevOps tools";
};
```

---

## CONCRETE EXAMPLES FROM THE REPO

### Custom Script as Overlay

**File**: `modules/nixos/packages.nix` (lines 7-20)

```nix
rofi-launcher = pkgs.writeShellScriptBin "rofi-launcher" ''
  ${pkgs.kdePackages.kde-cli-tools}/bin/kstart5 --window "rofi" -- \
  ${pkgs.rofi}/bin/rofi -show drun
'';

cheatsheet-viewer = pkgs.writeShellScriptBin "cheatsheet-viewer" ''
  CHEATSHEET_DIR="$HOME/cheatsheets"
  # ... script logic
'';
```

**Pattern**: Package shell scripts as `writeShellScriptBin`, include in packages list.

---

### AppImage Overlay

**File**: `overlays/obsidian-appimage.nix`

```nix
self: super: with super; {
  obsidian = appimageTools.wrapType2 rec {
    pname = "obsidian";
    version = "1.x.x";
    src = fetchurl {
      url = "https://github.com/obsidianmd/obsidian-releases/releases/download/...";
      sha256 = "...";
    };
    extraPkgs = pkgs: [ pkgs.libxkbcommon ];
  };
}
```

**Pattern**: Use `appimageTools.wrapType2` for AppImage packages.

---

### Platform-Specific Home-Manager Config

**File**: `modules/shared/home-manager.nix` (lines 150-160)

```nix
programs = {
  zsh = {
    initContent = lib.mkBefore ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '';
  };
  
  # Platform-specific
  (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    rofi.enable = true;
  })
};
```

**Pattern**: Use `lib.mkIf` for platform-specific settings within shared modules.

---

## REFACTOR CHECKLIST

- [ ] **Parameterize user** — Don't hardcode; use `specialArgs`
- [ ] **Break monolithic modules** — Split at ~150 lines
- [ ] **Add feature flags** — `options.features.*.enable` pattern
- [ ] **Auto-discover overlays** — Use `builtins.readDir` + `filter`
- [ ] **Isolate secrets** — Separate `secrets.nix` module
- [ ] **Composition-based HM** — Use `//` merging, not inheritance
- [ ] **Dual nixosConfigurations** — Support both platforms + named hosts
- [ ] **Document overlays** — Create `overlays/README.md`
- [ ] **Add tests** — Even basic validation helps
- [ ] **Create templates** — Provide starter configs for new users

---

## GITHUB PERMALINKS (EXACT REFERENCES)

| Pattern | File | Lines | URL |
|---------|------|-------|-----|
| Auto-discovered overlays | `modules/shared/default.nix` | 21-42 | https://github.com/dustinlyons/nixos-config/blob/d2bc630/modules/shared/default.nix#L21-L42 |
| Composition-based HM | `modules/nixos/home-manager.nix` | 6-8 | https://github.com/dustinlyons/nixos-config/blob/d2bc630/modules/nixos/home-manager.nix#L6-L8 |
| Dual nixosConfigurations | `flake.nix` | 140-175 | https://github.com/dustinlyons/nixos-config/blob/d2bc630/flake.nix#L140-L175 |
| Isolated secrets | `modules/nixos/secrets.nix` | 1-50 | https://github.com/dustinlyons/nixos-config/blob/d2bc630/modules/nixos/secrets.nix#L1-L50 |
| Custom script overlay | `modules/nixos/packages.nix` | 7-20 | https://github.com/dustinlyons/nixos-config/blob/d2bc630/modules/nixos/packages.nix#L7-L20 |

---

## NEXT STEPS FOR YOUR REFACTOR

1. **Read** `REFACTOR_RESEARCH.md` for full context
2. **Study** the GitHub permalinks above
3. **Adopt** patterns 1-5 incrementally
4. **Avoid** anti-patterns 1-4
5. **Test** each change with `nix flake check`
6. **Document** your own patterns in `CLAUDE.md`

