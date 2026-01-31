# Module Development Guide

This guide explains how to create, structure, and integrate new modules into this NixOS configuration.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Module Types](#module-types)
3. [Module Structure Conventions](#module-structure-conventions)
4. [Option Definition Best Practices](#option-definition-best-practices)
5. [Using _module.args](#using-_moduleargs)
6. [Integration with ez-configs](#integration-with-ez-configs)
7. [Testing Modules](#testing-modules)
8. [Examples](#examples)
9. [Common Patterns](#common-patterns)
10. [Troubleshooting](#troubleshooting)

---

## Quick Start

### NixOS Module (System-Level)

```bash
# 1. Create module file
$EDITOR nixos-modules/my-feature.nix

# 2. Add to aggregator
$EDITOR nixos-modules/default.nix
# Add: ./my-feature.nix

# 3. Enable in host config
$EDITOR nixos-configurations/bandit/default.nix
# Add: myFeature.enable = true;

# 4. Test
nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath
nh os test -H bandit
```

### Home Manager Module (User-Level)

```bash
# 1. Create module file
$EDITOR home-modules/my-tool.nix

# 2. Add to aggregator
$EDITOR home-modules/default.nix
# Add: ./my-tool.nix

# 3. Enable in user config
$EDITOR home-configurations/vino/default.nix
# Add: programs.myTool.enable = true;

# 4. Test
nh home switch -c vino@bandit
```

---

## Module Types

### NixOS Modules (System-Level)

**Location**: `nixos-modules/`

**Purpose**: System-wide configuration
- Services (SSH, Prometheus, backups)
- Hardware settings (power management, drivers)
- Security (firewall, hardening)
- Boot configuration
- Network settings

**Activation**: Runs as root during `nixos-rebuild switch`

**Example Use Cases**:
- Enable SSH server
- Configure automatic backups
- Set up monitoring (Prometheus/Grafana)
- Manage power profiles

---

### Home Manager Modules (User-Level)

**Location**: `home-modules/`

**Purpose**: Per-user configuration
- Desktop environment (i3, polybar)
- User applications (Firefox, Alacritty)
- Shell configuration (fish, starship)
- Editor setup (nixvim)
- User services (syncthing, mpd)

**Activation**: Runs as user during `home-manager switch`

**Example Use Cases**:
- Configure i3 window manager
- Set up neovim plugins
- Customize shell prompt
- Theme applications

---

### Shared Modules

**Location**: `shared-modules/`

**Purpose**: Shared between NixOS and Home Manager
- Stylix theme (colors, fonts)
- Workspace definitions
- Shared constants

**Import**: Referenced from both NixOS and HM modules

---

## Module Structure Conventions

### Simple Module (Single File)

For small features with < 150 lines:

```nix
# nixos-modules/my-feature.nix
{ lib, config, pkgs, ... }: {
  options.myFeature = {
    enable = lib.mkEnableOption "my awesome feature";
    
    setting = lib.mkOption {
      type = lib.types.str;
      default = "default-value";
      description = "A configurable setting";
    };
  };
  
  config = lib.mkIf config.myFeature.enable {
    environment.systemPackages = [ pkgs.some-package ];
    
    services.some-service = {
      enable = true;
      extraConfig = config.myFeature.setting;
    };
  };
}
```

---

### Complex Module (Directory)

For large features with 150+ lines, split into directory:

```
home-modules/features/editor/my-editor/
├── default.nix       # Main entry point with imports
├── options.nix       # Option definitions
├── config.nix        # Main configuration
├── plugins.nix       # Plugin-specific config
└── keymaps.nix       # Keybinding configuration
```

**default.nix** (orchestrator):
```nix
{ ... }: {
  imports = [
    ./options.nix
    ./config.nix
    ./plugins.nix
    ./keymaps.nix
  ];
}
```

**options.nix** (option definitions):
```nix
{ lib, ... }: {
  options.programs.myEditor = {
    enable = lib.mkEnableOption "my editor";
    
    theme = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Editor theme";
    };
  };
}
```

**config.nix** (implementation):
```nix
{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.programs.myEditor.enable {
    programs.myEditor = {
      # ... configuration
    };
  };
}
```

---

## Option Definition Best Practices

### Enable Options

```nix
# GOOD: mkEnableOption (generates proper type + description)
myFeature.enable = lib.mkEnableOption "my feature";

# BAD: Manual boolean
myFeature.enable = lib.mkOption {
  type = lib.types.bool;
  default = false;
  description = "Enable my feature";
};
```

---

### Simple Types

```nix
# String
setting = lib.mkOption {
  type = lib.types.str;
  default = "value";
  description = "A string setting";
};

# Integer
port = lib.mkOption {
  type = lib.types.port;  # Special type for ports (1-65535)
  default = 8080;
  description = "Port number";
};

# Boolean
flag = lib.mkOption {
  type = lib.types.bool;
  default = true;
  description = "Enable feature";
};

# Path
file = lib.mkOption {
  type = lib.types.path;
  default = ./config.yaml;
  description = "Configuration file path";
};
```

---

### Complex Types

```nix
# List of strings
excludePatterns = lib.mkOption {
  type = lib.types.listOf lib.types.str;
  default = [ "*.tmp" ".cache" ];
  description = "Patterns to exclude";
};

# Attribute set
colors = lib.mkOption {
  type = lib.types.attrs;
  default = { red = "#FF0000"; blue = "#0000FF"; };
  description = "Color definitions";
};

# Enum (one of several values)
logLevel = lib.mkOption {
  type = lib.types.enum [ "debug" "info" "warn" "error" ];
  default = "info";
  description = "Logging level";
};

# Nullable type
domain = lib.mkOption {
  type = lib.types.nullOr lib.types.str;
  default = null;
  description = "Domain name (null = localhost only)";
};
```

---

### Submodules (Nested Options)

```nix
backup.repositories = lib.mkOption {
  type = lib.types.attrsOf (lib.types.submodule {
    options = {
      repository = lib.mkOption {
        type = lib.types.str;
        description = "Repository URL";
      };
      
      passwordFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to password file";
      };
      
      paths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "/home" ];
        description = "Paths to backup";
      };
    };
  });
  default = {};
  description = "Backup repository configurations";
};
```

**Usage**:
```nix
backup.repositories.home = {
  repository = "/mnt/backup";
  passwordFile = /run/secrets/restic_password;
  paths = [ "/home" ];
};
```

---

### Defaults and Overrides

```nix
# mkDefault: Can be overridden by user
bluetooth.enable = lib.mkDefault true;

# mkForce: Cannot be overridden (use sparingly)
networking.firewall.enable = lib.mkForce false;

# mkOverride: Custom priority (100 = default, 10 = high, 1000 = low)
services.xserver.enable = lib.mkOverride 50 true;
```

**Priority Order** (lower number = higher priority):
1. `mkForce` (50)
2. Custom `mkOverride` (user-defined)
3. User config (100, default)
4. `mkDefault` (1000)
5. Module default (1500)

---

## Using _module.args

### What is _module.args?

Shared variables injected into ALL modules without explicit passing.

**Definition** (in host config):
```nix
# home-configurations/vino/default.nix
_module.args = {
  c = config.lib.stylix.colors;  # Color shortcuts
  palette = config.stylix.base16Scheme;  # Full palette
  stylixFonts = config.stylix.fonts;  # Fonts
  i3Pkg = config.xsession.windowManager.i3.package;
  workspaces = import ../../shared-modules/workspaces.nix;
};
```

**Usage** (in any module):
```nix
# home-modules/features/desktop/i3/config.nix
{ c, workspaces, ... }: {
  xsession.windowManager.i3.config = {
    colors.focused = {
      background = c.base0D;  # Direct access to colors
      border = c.base0D;
    };
  };
}
```

---

### When to Use _module.args

**GOOD use cases**:
- Theme colors (shared across many modules)
- Font configuration (used everywhere)
- Workspace definitions (i3, polybar)
- Common helper functions

**BAD use cases**:
- Module-specific data (use `let` bindings instead)
- Mutable state (Nix is purely functional)
- Heavy computations (evaluated for every module)

---

### Creating Reusable Helpers

```nix
# lib/default.nix
{ lib }: {
  # Generate i3 workspace bindings
  mkWorkspaceBindings = { mod, workspaces, commandPrefix }: 
    lib.listToAttrs (
      lib.forEach workspaces (ws: {
        name = "${mod}+${ws.key}";
        value = "${commandPrefix} ${ws.name}";
      })
    );
  
  # Validate secret files
  validateSecretExists = path:
    if !builtins.pathExists path
    then throw "Secret file not found: ${path}"
    else true;
}
```

**Usage**:
```nix
# In any module
let
  cfgLib = import ../../../../lib { inherit lib; };
  
  workspaceBindings = cfgLib.mkWorkspaceBindings {
    inherit mod workspaces;
    commandPrefix = "workspace";
  };
in { ... }
```

---

## Integration with ez-configs

### How ez-configs Works

1. **Auto-imports**: `nixos-modules/default.nix` and `home-modules/default.nix` automatically imported
2. **Module discovery**: All modules listed in `default.nix` are loaded
3. **Host configuration**: Host files only contain overrides

**No need to manually import modules in flake.nix!**

---

### Adding a NixOS Module

**Step 1**: Create module file

```bash
$EDITOR nixos-modules/my-service.nix
```

```nix
{ lib, config, pkgs, ... }: {
  options.myService = {
    enable = lib.mkEnableOption "my custom service";
  };
  
  config = lib.mkIf config.myService.enable {
    systemd.services.my-service = {
      description = "My Custom Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.my-package}/bin/my-service";
      };
    };
  };
}
```

**Step 2**: Add to aggregator

```nix
# nixos-modules/default.nix
{ inputs, ... }: {
  imports = [
    # ... existing imports
    ./my-service.nix  # ADD THIS LINE
  ];
}
```

**Step 3**: Enable in host config

```nix
# nixos-configurations/bandit/default.nix
{
  # ... existing config
  myService.enable = true;
}
```

**Done!** ez-configs automatically imports `nixos-modules/default.nix` for every host.

---

### Adding a Home Manager Module

**Step 1**: Create module file

```bash
$EDITOR home-modules/my-tool.nix
```

```nix
{ lib, config, pkgs, ... }: {
  options.programs.myTool = {
    enable = lib.mkEnableOption "my custom tool";
  };
  
  config = lib.mkIf config.programs.myTool.enable {
    home.packages = [ pkgs.my-tool ];
    
    xdg.configFile."my-tool/config.yaml".text = ''
      setting: value
    '';
  };
}
```

**Step 2**: Add to aggregator

```nix
# home-modules/default.nix
{
  imports = [
    # ... existing imports
    ./my-tool.nix  # ADD THIS LINE
  ];
}
```

**Step 3**: Enable in user config

```nix
# home-configurations/vino/default.nix
{
  # ... existing config
  programs.myTool.enable = true;
}
```

**Done!** ez-configs automatically imports `home-modules/default.nix` for every user.

---

### Directory-Based Modules

For complex modules with multiple files:

**Step 1**: Create directory structure

```bash
mkdir -p home-modules/features/terminal/my-shell
cd home-modules/features/terminal/my-shell
touch default.nix config.nix plugins.nix
```

**Step 2**: Create `default.nix` (entry point)

```nix
# home-modules/features/terminal/my-shell/default.nix
{ ... }: {
  imports = [
    ./config.nix
    ./plugins.nix
  ];
}
```

**Step 3**: Add directory to aggregator

```nix
# home-modules/default.nix
{
  imports = [
    # ... existing imports
    ./features/terminal/my-shell  # Points to default.nix
  ];
}
```

ez-configs automatically finds `default.nix` in the directory.

---

## Testing Modules

### Quick Validation

```bash
# 1. Check syntax (fast)
nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath

# 2. Dry-run build (no activation)
nh os test -H bandit

# 3. Check specific option value
nix eval .#nixosConfigurations.bandit.config.myFeature.setting
```

---

### Full Testing Workflow

```bash
# 1. Format code
nix fmt

# 2. Lint (static analysis)
nix develop --command statix check .

# 3. Dead code detection
nix develop --command deadnix -f .

# 4. Evaluate configuration
nix eval .#nixosConfigurations.bandit.config.system.build.toplevel.drvPath

# 5. Build without activation
nh os test -H bandit

# 6. Apply changes
nh os switch -H bandit

# 7. Verify service
systemctl status my-service

# 8. Check logs
journalctl -u my-service -f
```

---

### Testing Option Defaults

```bash
# Test default value
nix eval .#nixosConfigurations.bandit.config.myFeature.setting
# Output: "default-value"

# Test with override (in host config)
nix eval .#nixosConfigurations.bandit.config.myFeature.setting
# Output: "custom-value"
```

---

### Testing Conditional Logic

```nix
# Module with conditional config
config = lib.mkIf config.myFeature.enable {
  # This should only activate when enabled
  systemd.services.my-service.enable = true;
};
```

**Test**:
```bash
# When disabled
nix eval .#nixosConfigurations.bandit.config.systemd.services.my-service.enable
# Output: false

# When enabled
nix eval .#nixosConfigurations.bandit.config.systemd.services.my-service.enable
# Output: true
```

---

## Examples

### Example 1: Simple Service Module

```nix
# nixos-modules/auto-upgrade.nix
{ lib, config, ... }: {
  options.autoUpgrade = {
    enable = lib.mkEnableOption "automatic system upgrades";
    
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "When to run auto-upgrade (systemd calendar format)";
    };
  };
  
  config = lib.mkIf config.autoUpgrade.enable {
    system.autoUpgrade = {
      enable = true;
      dates = config.autoUpgrade.schedule;
      allowReboot = false;
    };
  };
}
```

**Usage**:
```nix
autoUpgrade = {
  enable = true;
  schedule = "daily";
};
```

---

### Example 2: Desktop Module with Options

```nix
# home-modules/features/desktop/my-compositor.nix
{ lib, config, pkgs, ... }: {
  options.programs.myCompositor = {
    enable = lib.mkEnableOption "my compositor";
    
    backend = lib.mkOption {
      type = lib.types.enum [ "glx" "xrender" ];
      default = "glx";
      description = "Rendering backend";
    };
    
    opacity = lib.mkOption {
      type = lib.types.float;
      default = 0.9;
      description = "Window opacity (0.0-1.0)";
    };
  };
  
  config = lib.mkIf config.programs.myCompositor.enable {
    home.packages = [ pkgs.picom ];
    
    xdg.configFile."picom/picom.conf".text = ''
      backend = "${config.programs.myCompositor.backend}";
      opacity-rule = [
        "${toString (config.programs.myCompositor.opacity * 100)}:class_g = 'Alacritty'"
      ];
    '';
    
    # Auto-start with X11
    xsession.windowManager.i3.config.startup = [
      { command = "${pkgs.picom}/bin/picom"; notification = false; }
    ];
  };
}
```

**Usage**:
```nix
programs.myCompositor = {
  enable = true;
  backend = "glx";
  opacity = 0.85;
};
```

---

### Example 3: Hardware Module with Role Integration

```nix
# nixos-modules/roles/workstation.nix
{ lib, config, pkgs, ... }: {
  options.roles.workstation = lib.mkEnableOption "workstation features (performance, development tools)";
  
  config = lib.mkIf config.roles.workstation {
    # CPU performance
    powerManagement.cpuFreqGovernor = "performance";
    
    # Development packages
    environment.systemPackages = with pkgs; [
      gcc
      gdb
      valgrind
      docker-compose
    ];
    
    # Docker
    virtualisation.docker.enable = true;
    users.users.vino.extraGroups = [ "docker" ];
    
    # Disable power-saving features
    services.power-profiles-daemon.enable = lib.mkForce false;
  };
}
```

**Usage**:
```nix
roles.workstation = true;
```

---

### Example 4: Module with Submodules

See `nixos-modules/backup.nix` for a complete example of submodules.

**Key pattern**:
```nix
repositories = lib.mkOption {
  type = lib.types.attrsOf (lib.types.submodule {
    options = {
      # Define options for each repository
    };
  });
};
```

**Usage**:
```nix
backup.repositories = {
  home = { repository = "/mnt/backup"; paths = [ "/home" ]; };
  data = { repository = "s3:..."; paths = [ "/data" ]; };
};
```

---

## Common Patterns

### Pattern 1: Conditional Service

```nix
config = lib.mkIf config.myFeature.enable {
  systemd.services.my-service = {
    description = "My Service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.my-package}/bin/my-service";
      Restart = "on-failure";
    };
  };
};
```

---

### Pattern 2: Generate Config File

```nix
config = lib.mkIf config.programs.myTool.enable {
  xdg.configFile."my-tool/config.yaml".text = lib.generators.toYAML {} {
    setting1 = config.programs.myTool.setting1;
    setting2 = config.programs.myTool.setting2;
  };
};
```

---

### Pattern 3: Merge Multiple Conditions

```nix
config = lib.mkMerge [
  # Always active
  {
    environment.systemPackages = [ pkgs.base-package ];
  }
  
  # Conditional on feature A
  (lib.mkIf config.featureA.enable {
    services.service-a.enable = true;
  })
  
  # Conditional on feature B
  (lib.mkIf config.featureB.enable {
    services.service-b.enable = true;
  })
];
```

---

### Pattern 4: Role-Based Defaults

```nix
# Set different defaults based on role
services.openssh.enable = lib.mkDefault config.roles.server;
services.xserver.enable = lib.mkDefault config.roles.desktop;
hardware.bluetooth.enable = lib.mkDefault config.roles.laptop;
```

---

### Pattern 5: Helper Function for Bindings

```nix
let
  mkBindings = keys: command:
    lib.listToAttrs (
      map (key: {
        name = "${mod}+${key}";
        value = command;
      }) keys
    );
in {
  xsession.windowManager.i3.config.keybindings =
    mkBindings [ "h" "j" "k" "l" ] "focus";
}
```

---

## Troubleshooting

### Module Not Found

**Error**: `error: attribute 'myFeature' missing`

**Solution**: Check module is imported in `default.nix`:
```nix
# nixos-modules/default.nix or home-modules/default.nix
imports = [
  ./my-feature.nix  # Make sure this exists
];
```

---

### Option Not Recognized

**Error**: `The option 'myFeature.setting' does not exist`

**Solution**: Verify option is defined in module:
```nix
options.myFeature.setting = lib.mkOption { ... };
```

---

### Infinite Recursion

**Error**: `error: infinite recursion encountered`

**Cause**: Circular dependency between options.

**Solution**: Use `config` parameter, not `options`:
```nix
# BAD
config.services.my-service.port = options.myFeature.port.value;

# GOOD
config.services.my-service.port = config.myFeature.port;
```

---

### Type Mismatch

**Error**: `value is a string while a set was expected`

**Solution**: Check option type matches usage:
```nix
# Option defined as string
myFeature.setting = lib.mkOption { type = lib.types.str; };

# But used as attrset (WRONG)
config.myFeature.setting.nested = "value";

# Fix: Change type to attrs
myFeature.setting = lib.mkOption { type = lib.types.attrs; };
```

---

### Path Errors in Split Modules

**Error**: `error: file not found` when importing lib

**Cause**: Incorrect relative path depth.

**Solution**: Count directory levels carefully:
```nix
# From home-modules/features/desktop/i3/keybindings.nix
# i3/ → desktop/ → features/ → home-modules/ → lib/
cfgLib = import ../../../../lib { inherit lib; };
```

---

## Checklist: Adding a New Module

- [ ] Created module file (`.nix` or directory with `default.nix`)
- [ ] Defined `options` (with types, defaults, descriptions)
- [ ] Implemented `config` (with `lib.mkIf` for conditionals)
- [ ] Added import to `nixos-modules/default.nix` or `home-modules/default.nix`
- [ ] Enabled in host config (`myFeature.enable = true`)
- [ ] Ran `nix fmt` (formatting)
- [ ] Ran `statix check .` (linting)
- [ ] Tested evaluation (`nix eval .#nixosConfigurations.bandit...`)
- [ ] Tested build (`nh os test`)
- [ ] Applied and verified (`nh os switch`, check service/config)
- [ ] Committed changes with descriptive message
- [ ] Updated documentation (if complex module)

---

## Additional Resources

- [NixOS Module System Manual](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- [Home Manager Modules](https://nix-community.github.io/home-manager/index.xhtml#ch-writing-modules)
- [Nix Language Basics](https://nix.dev/tutorials/nix-language)
- [ez-configs Documentation](https://github.com/ehllie/ez-configs)
- [Example Modules in This Repo](../nixos-modules/)

---

**Last Updated**: 2026-01-31  
**System**: Framework 13 AMD (bandit)  
**NixOS Version**: unstable (26.05)
