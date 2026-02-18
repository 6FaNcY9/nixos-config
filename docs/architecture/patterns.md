# Architectural Patterns

This document describes the core architectural patterns used in this NixOS configuration. Each pattern includes its intent, location in the codebase, implementation details, and examples.

---

## 1. Flake Composition (flake-parts + ez-configs)

**Intent:** Automatically discover and wire host configurations while maintaining modularity and avoiding boilerplate.

**Why:** Managing multiple hosts and users in a monorepo becomes tedious with manual imports. Auto-discovery scales cleanly as new hosts/users are added, following the principle of convention over configuration.

**Where:**
- `flake.nix` — orchestrator, imports flake-parts and ez-configs
- `flake-modules/` — perSystem modules (devshells, apps, checks)
- `nixos-configurations/` — per-host NixOS configs (auto-discovered)
- `home-configurations/` — per-user Home Manager configs (auto-discovered)

**How:**
1. `flake-parts` provides `mkFlake` for composable flake structure
2. `ez-configs.flakeModule` scans `{nixos,home}-configurations/` directories
3. `globalArgs` makes common values (inputs, username, repoRoot) available everywhere
4. Host-user relationships defined in `ezConfigs.nixos.hosts.<host>.userHomeModules`

**Example:**
```nix
# flake.nix
flake-parts.lib.mkFlake { inherit inputs; } ({ ... }: {
  imports = [
    inputs.ez-configs.flakeModule
    ./flake-modules  # Auto-imports all perSystem modules
  ];

  ezConfigs = {
    root = ./.;
    globalArgs = {
      inherit inputs username repoRoot;  # Available in ALL modules
    };
    nixos.hosts.${primaryHost}.userHomeModules = [ "vino" ];
  };
});
```

**Benefits:**
- New hosts: create `nixos-configurations/<hostname>/default.nix` (auto-wired)
- New users: create `home-configurations/<username>/default.nix` (auto-wired)
- Shared args flow through all layers without manual plumbing

---

## 2. Module Aggregator Topology (default.nix collectors)

**Intent:** Centralize imports in a single `default.nix` per directory to create a clean module namespace.

**Why:** Instead of importing dozens of scattered files individually, each logical grouping (nixos-modules, home-modules, shared-modules) has a single entry point. This makes the import tree readable and enforces a clear separation of concerns.

**Where:**
- `nixos-modules/default.nix` — system-level modules
- `home-modules/default.nix` — user-level modules
- `flake-modules/default.nix` — perSystem modules

**How:**
Each `default.nix` acts as an aggregator: it imports all module files in its directory (and subdirectories via nested aggregators), then exposes them as a single import. Host/user configs import only the top-level `default.nix`.

**Example:**
```nix
# nixos-modules/default.nix
{ inputs, ... }:
{
  imports = [
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
    ../shared-modules/stylix-common.nix
    ./core.nix
    ./storage.nix
    ./services.nix
    ./secrets.nix
    ./roles  # Subdirectory with its own default.nix
    ./desktop.nix
    ./home-manager.nix
  ];
}

# nixos-configurations/bandit/default.nix
{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
  ];
  # ALL nixos-modules are automatically imported via ez-configs
}
```

**Benefits:**
- Single source of truth for module organization
- Easy to see what's included at a glance
- Subdirectories can nest their own aggregators (e.g. `roles/default.nix`)
- Host configs remain focused on host-specific settings

---

## 3. Arg Injection / Shared Context (_module.args at multiple levels)

**Intent:** Make frequently-used values (colors, helpers, packages) available as function arguments throughout the configuration without manual threading.

**Why:** Passing data via `specialArgs`, `extraSpecialArgs`, or config references becomes tedious and error-prone. The `_module.args` pattern establishes a "context layer" where values are injected once and accessed naturally via function arguments.

**Where:**
- `flake.nix` — top-level args for perSystem modules (primaryHost, username, repoRoot, pkgsFor)
- `flake-modules/_common.nix` — perSystem args (cfgLib, commonDevPackages, mkApp, opencodePkg)
- `nixos-modules/home-manager.nix` — bridge NixOS args to Home Manager via `extraSpecialArgs`
- `home-configurations/vino/default.nix` — home-module args (palette, c, workspaces, stylixFonts, cfgLib)

**How:**
1. **Top-level (flake):** `_module.args` makes values available to all perSystem flake-modules
2. **perSystem (_common.nix):** Additional args available across devshells, apps, packages
3. **NixOS → Home Manager bridge:** `extraSpecialArgs` forwards inputs/username/repoRoot
4. **Home config:** Injects semantic colors, workspace definitions, and helpers

**Example:**
```nix
# flake.nix (top-level)
_module.args = {
  inherit primaryHost username repoRoot pkgsFor;
};

# flake-modules/_common.nix (perSystem)
perSystem = { pkgs, inputs', ... }: {
  _module.args = {
    inherit cfgLib commonDevPackages mkApp opencodePkg;
  };
};

# nixos-modules/home-manager.nix (bridge to Home Manager)
home-manager.extraSpecialArgs = {
  inherit inputs username repoRoot;
};

# home-configurations/vino/default.nix (home-modules)
_module.args = {
  inherit (config.theme) palette;
  c = config.theme.colors;
  inherit (config) workspaces;
  inherit stylixFonts i3Pkg codexPkg opencodePkg;
  hostname = hostName;
  cfgLib = import ../../lib { inherit lib; };
};

# Usage in any home-module:
{ pkgs, palette, cfgLib, workspaces, ... }:
{
  # palette.accent, cfgLib.mkWorkspaceName, etc. directly available
}
```

**Benefits:**
- No prop-drilling through intermediate modules
- Type-safe access (function args enforce what's available)
- Clear separation: flake args vs perSystem args vs home-module args
- Easy to audit: grep for `_module.args` shows all injection points

---

## 4. Roles vs Profiles (system vs user feature flags)

**Intent:** Separate system-level capabilities (roles) from user-level package collections (profiles).

**Why:** A system can have hardware-dependent features (bluetooth, power management) independent of what packages a user wants installed. This separation enables:
- Reusing the same role across different users
- Different users on the same host having different profiles
- Clear boundary: roles = system services/drivers, profiles = user packages

**Where:**
- `nixos-modules/roles/default.nix` — role options (desktop, laptop, server, development)
- `nixos-modules/roles/*.nix` — role implementations
- `home-modules/profiles.nix` — profile options (core, dev, desktop, extras, ai)

**How:**
- **Roles:** Boolean options in NixOS modules. Enable services, drivers, or system configuration.
- **Profiles:** Boolean options in Home Manager. Control package installation via `lib.optionals`.

**Example:**
```nix
# nixos-modules/roles/default.nix
options.roles = {
  desktop = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable the desktop/GUI role for this host.";
  };
  laptop = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable laptop-specific behavior (bluetooth, power management).";
  };
  development = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable development tools (docker, direnv, build tools).";
  };
};

# nixos-configurations/bandit/default.nix
roles = {
  desktop = true;
  laptop = true;
  development = true;
};

# home-modules/profiles.nix
options.profiles = {
  core = cfgLib.mkProfile "core CLI tools" true;
  dev = cfgLib.mkProfile "development tools" true;
  desktop = cfgLib.mkProfile "desktop apps" true;
  ai = cfgLib.mkProfile "AI tools" false;
};

config.home.packages = lib.concatLists [
  (lib.optionals cfg.core corePkgs)
  (lib.optionals cfg.dev devPkgs)
  (lib.optionals cfg.desktop desktopPkgs)
  (lib.optionals cfg.ai aiPkgs)
];

# home-configurations/vino/default.nix (user opts in)
profiles = {
  core = true;
  dev = true;
  desktop = true;
  extras = false;
  ai = false;
};
```

**Benefits:**
- Host definitions are declarative: "this is a laptop with a desktop environment"
- Users control their own package sets without system rebuilds
- Profile changes only affect Home Manager, not NixOS
- Easy to add new roles/profiles without touching existing ones

---

## 5. Theming System (Stylix + semantic palette)

**Intent:** Centralize visual theming with semantic color names that remain stable across theme changes.

**Why:** Hardcoding `#262626` or `base00` in dozens of config files makes theme changes brittle. A semantic layer (`palette.bg`, `palette.accent`) decouples color *meaning* from color *value*, allowing theme swaps without editing application configs.

**Where:**
- `shared-modules/stylix-common.nix` — Stylix configuration (wallpaper, fonts, base16 scheme)
- `shared-modules/palette.nix` — semantic color mapping (bg, text, accent, warn, danger, muted)
- `home-configurations/vino/default.nix` — injects palette and raw colors (c) via `_module.args`

**How:**
1. **Stylix** generates base16 colors from a scheme (Gruvbox) and wallpaper
2. **palette.nix** reads Stylix colors and maps them to semantic names
3. Both `palette` (semantic) and `c` (raw base16) are injected as args
4. Application configs reference `palette.accent` instead of `c.base0B`

**Example:**
```nix
# shared-modules/stylix-common.nix
config.stylix = {
  enable = true;
  image = config.theme.wallpaper;
  polarity = "dark";
  base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-pale.yaml";
};

# shared-modules/palette.nix
options.theme.palette = lib.mkOption {
  type = lib.types.submodule {
    options = {
      bg = lib.mkOption {
        default = c.base00;
        description = "Primary background color.";
      };
      accent = lib.mkOption {
        default = c.base0B;
        description = "Primary accent color (green).";
      };
      warn = lib.mkOption {
        default = c.base0A;
        description = "Warning color (yellow).";
      };
      # ... more semantic colors
    };
  };
};

# Usage in i3 config:
{ palette, ... }:
{
  colors.focused = {
    background = palette.accent;
    border = palette.accent;
    text = palette.bg;
  };
}
```

**Two-tier color system:**
- **`palette.*`** (semantic) — Prefer for most UI code. Names reflect purpose.
- **`c.*`** (base16 raw) — Use for specific hues not covered by palette (e.g., `c.base07` for cream).

**Benefits:**
- Change theme: edit one line in `stylix-common.nix`
- No application config changes required
- Semantic names self-document color usage
- Fallback values ensure configs work even without Stylix

---

## 6. Secrets Management (sops-nix + validation)

**Intent:** Store encrypted secrets in Git and decrypt them at activation time, with compile-time validation to catch missing or unencrypted secrets.

**Why:** Secrets must never be committed in plaintext, but they need to be versioned and available during system builds. sops-nix handles encryption/decryption, while validation helpers prevent deploying a system with missing or corrupted secrets.

**Where:**
- `secrets/` — encrypted YAML files (github.yaml, restic.yaml, etc.)
- `nixos-modules/secrets.nix` — system-level secret definitions and validation
- `home-modules/secrets.nix` — user-level secret definitions and validation
- `lib/default.nix` — `validateSecretExists`, `validateSecretEncrypted`, `mkSecretValidation`

**How:**
1. Secrets are stored as `.yaml` files encrypted with `sops`
2. Each module defines `sops.secrets.<name>` with `sopsFile`, `owner`, `mode`, `path`
3. Validation helpers check at evaluation time that files exist and contain sops metadata
4. At activation, sops-nix decrypts secrets to paths like `/run/secrets/<name>`

**Example:**
```nix
# lib/default.nix
validateSecretEncrypted = secretPath:
  let
    content = builtins.readFile secretPath;
    isEncrypted = (lib.hasInfix "sops" content) && (lib.hasInfix "mac" content);
  in
  assert isEncrypted || throw "Secret file appears to be unencrypted: ${secretPath}";
  true;

mkSecretValidation = { secrets, label }:
  let
    valid = builtins.all (path: validateSecretExists path && validateSecretEncrypted path) secrets;
  in
  {
    inherit valid;
    assertions = [{
      assertion = valid;
      message = "${label}: one or more secret files are missing or unencrypted.";
    }];
  };

# nixos-modules/secrets.nix
let
  githubSecretFile = "${inputs.self}/secrets/github.yaml";
  secretValidation = cfgLib.mkSecretValidation {
    secrets = [ githubSecretFile ];
    label = "System";
  };
in
{
  inherit (secretValidation) assertions;  # Fails build if invalid

  sops.secrets."github_ssh_key" = {
    sopsFile = githubSecretFile;
    owner = username;
    mode = "0600";
    path = "/home/${username}/.ssh/github";
  };
}

# home-modules/secrets.nix
sops.secrets.github_mcp_pat = {
  sopsFile = githubMcpSecretFile;
  format = "yaml";
};

# Usage in shell config:
if test -r ${config.sops.secrets.github_mcp_pat.path}
  set -x GITHUB_MCP_PAT (cat ${config.sops.secrets.github_mcp_pat.path})
end
```

**Key validation features:**
- `validateSecretExists` — checks `builtins.pathExists`
- `validateSecretEncrypted` — checks for `sops` and `mac`/`enc` metadata
- `mkSecretValidation` — returns assertions for NixOS `config.assertions`
- Build fails early if secrets are missing or plaintext

**Benefits:**
- Secrets versioned in Git (encrypted)
- No plaintext secrets committed
- Validation at evaluation time (fail fast)
- Clear error messages with file paths
- Per-secret owner/mode control

---

## 7. Anti-Patterns (What to Avoid)

### ❌ Direct `extraSpecialArgs` at flake level
**Problem:** Pollutes the global namespace with values only needed in specific contexts.

**Instead:** Use `_module.args` at the appropriate scope (flake-level, perSystem, or home config).

---

### ❌ Hardcoded colors in application configs
```nix
# BAD
background = "#262626";

# GOOD
background = palette.bg;
```
**Problem:** Makes theme changes require editing dozens of files.

---

### ❌ Mixing roles and profiles
```nix
# BAD: putting user packages in NixOS role modules
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.alacritty pkgs.vscode ];
}

# GOOD: roles handle services, profiles handle packages
```
**Problem:** Forces system rebuilds for user preference changes.

---

### ❌ Manual import lists in host configs
```nix
# BAD
imports = [
  ../../nixos-modules/core.nix
  ../../nixos-modules/storage.nix
  ../../nixos-modules/services.nix
  # ... 20 more lines
];

# GOOD: already handled by ez-configs + default.nix
imports = [
  inputs.nixos-hardware.nixosModules.framework-13-7040-amd
  ./hardware-configuration.nix
];
```
**Problem:** Every new module requires updating every host.

---

### ❌ Using `c.base0B` everywhere instead of `palette.accent`
```nix
# BAD
borderColor = c.base0B;

# GOOD
borderColor = palette.accent;
```
**Problem:** If accent color changes to blue (`base0D`), all references must be updated.

---

### ❌ Skipping secret validation
```nix
# BAD
sops.secrets."my_secret" = {
  sopsFile = ./secrets/missing-file.yaml;  # Fails at activation, not eval
};

# GOOD
let
  secretValidation = cfgLib.mkSecretValidation {
    secrets = [ ./secrets/my-secret.yaml ];
  };
in
{
  inherit (secretValidation) assertions;  # Fails at eval time
}
```
**Problem:** Errors discovered late (at activation) instead of early (at build).

---

### ❌ Deeply nested `_module.args` in shared modules
```nix
# BAD: shared-modules/some-module.nix
{ ... }:
{
  _module.args.myCustomArg = "value";
  # ... other options
}
```
**Problem:** Args injected in shared modules can create hidden dependencies and make the evaluation order unclear.

**Instead:** Inject args in well-defined "boundaries" (flake level, perSystem, home config).

---

## Summary

These patterns work together to create a maintainable, scalable NixOS configuration:

1. **Flake composition** auto-discovers hosts and users
2. **Module aggregators** organize imports hierarchically
3. **Arg injection** makes shared context available without prop-drilling
4. **Roles and profiles** separate system concerns from user preferences
5. **Semantic theming** decouples color meaning from color values
6. **Secret validation** enforces encrypted secrets with early failure

When adding new features, ask:
- Does this belong at the system level (role) or user level (profile)?
- Should this value be injected via `_module.args` or passed explicitly?
- Am I using semantic names (`palette.accent`) or hardcoded values?
- Are my secrets validated at eval time?

Following these patterns keeps the configuration consistent, predictable, and easy to extend.
