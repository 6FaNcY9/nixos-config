# nix-starter-configs: Pattern Reference Guide

Quick lookup for specific patterns from nix-starter-configs that may be useful for your refactor.

---

## Pattern: Three-Overlay Convention

**File**: `standard/overlays/default.nix`

**Purpose**: Separate concerns in overlay management

**Code**:
```nix
{inputs, ...}: {
  # Overlay 1: Custom packages from ./pkgs
  additions = final: _prev: import ../pkgs final.pkgs;
  
  # Overlay 2: Modifications to existing packages
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec { ... });
  };
  
  # Overlay 3: Access to unstable nixpkgs
  unstable-packages = final: _prev: {
    unstablePkgs = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
```

**When to use**: When you have multiple types of package modifications

**Benefit**: Clear separation, easy to understand what each overlay does

**Your config**: Consider if you want to split `overlays/custom-packages.nix`

---

## Pattern: Custom Packages Registry

**File**: `standard/pkgs/default.nix`

**Purpose**: Define custom packages that can be built with `nix build .#package-name`

**Code**:
```nix
pkgs: {
  example = pkgs.callPackage ./example { };
}
```

**When to use**: When you have custom packages to distribute

**Benefit**: Packages available in overlays, can be built independently

**Your config**: Similar pattern likely already in use

---

## Pattern: Module Registry Aggregation

**File**: `standard/modules/nixos/default.nix` and `standard/modules/home-manager/default.nix`

**Purpose**: Central registry for reusable modules

**Code**:
```nix
# Add your reusable modules to this directory, on their own file
# These should be stuff you would like to share with others, not personal configs
{
  # my-module = import ./my-module.nix;
}
```

**When to use**: Always (for organizing reusable modules)

**Benefit**: Clear separation between reusable and personal config

**Your config**: Already using this pattern

---

## Pattern: Flake Outputs with Exports

**File**: `standard/flake.nix:37-49`

**Purpose**: Export packages, overlays, and modules for reuse

**Code**:
```nix
outputs = {self, nixpkgs, home-manager, ...} @ inputs: let
  systems = ["aarch64-linux" "i686-linux" "x86_64-linux" "aarch64-darwin" "x86_64-darwin"];
  forAllSystems = nixpkgs.lib.genAttrs systems;
in {
  packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
  formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  
  overlays = import ./overlays {inherit inputs;};
  nixosModules = import ./modules/nixos;
  homeManagerModules = import ./modules/home-manager;
  
  nixosConfigurations.your-hostname = ...;
  homeConfigurations."your-username@your-hostname" = ...;
};
```

**When to use**: When you want to export reusable components

**Benefit**: Other flakes can use your packages, overlays, and modules

**Your config**: Likely already using similar pattern

---

## Pattern: Overlay Application in NixOS

**File**: `standard/nixos/configuration.nix:28-32`

**Purpose**: Apply overlays at system level

**Code**:
```nix
nixpkgs = {
  overlays = [
    inputs.self.overlays.additions
    inputs.self.overlays.modifications
    inputs.self.overlays.unstable-packages
  ];
  config.allowUnfree = true;
};
```

**When to use**: Always (to apply overlays)

**Benefit**: All packages see the overlays

**Your config**: Likely already doing this

---

## Pattern: Overlay Application in Home Manager

**File**: `standard/home-manager/home.nix:24-28`

**Purpose**: Apply overlays at user level

**Code**:
```nix
nixpkgs = {
  overlays = [
    inputs.self.overlays.additions
    inputs.self.overlays.modifications
    inputs.self.overlays.unstable-packages
  ];
  config.allowUnfree = true;
};
```

**When to use**: Always (to apply overlays)

**Benefit**: User packages see the overlays

**Your config**: Likely already doing this

---

## Pattern: Opinionated Nix Settings

**File**: `standard/nixos/configuration.nix:54-59`

**Purpose**: Enforce flakes-first philosophy

**Code**:
```nix
nix = {
  settings = {
    experimental-features = "nix-command flakes";
    flake-registry = "";  # Disable global registry
  };
  channel.enable = false;  # Disable channels
};
```

**When to use**: Always (for modern Nix experience)

**Benefit**: No legacy channel confusion, explicit flakes-only

**Your config**: Likely already doing this

---

## Pattern: Flake Inputs Injection

**File**: `standard/flake.nix:55-56` (NixOS), `standard/flake.nix:70-71` (HM)

**Purpose**: Make flake inputs available to all modules

**Code**:
```nix
# NixOS
nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
  specialArgs = {inherit inputs;};
  modules = [./nixos/configuration.nix];
};

# Home Manager
homeConfigurations."your-username@your-hostname" = 
  home-manager.lib.homeManagerConfiguration {
    extraSpecialArgs = {inherit inputs;};
    modules = [./home-manager/home.nix];
  };
```

**When to use**: Always (to enable module composition)

**Benefit**: Modules can reference `inputs.hardware`, `inputs.nix-colors`, etc.

**Your config**: Likely already using this

---

## Pattern: Hardware Config Separation

**File**: `standard/nixos/configuration.nix:23`

**Purpose**: Keep generated hardware config separate from hand-written config

**Code**:
```nix
imports = [
  ./hardware-configuration.nix
];
```

**When to use**: Always (for maintainability)

**Benefit**: Prevents accidental overwrites during config rewrites

**Your config**: Consider extracting to separate file

---

## Pattern: Unstable Packages Access

**File**: `standard/overlays/default.nix:16-23`

**Purpose**: Make unstable packages available as `pkgs.unstablePkgs`

**Code**:
```nix
unstable-packages = final: _prev: {
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = final.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
};
```

**Usage**:
```nix
home.packages = with pkgs; [
  unstablePkgs.neovim
];
```

**When to use**: When you need unstable packages

**Benefit**: Clean namespace, no separate nixpkgs instance

**Your config**: Consider if you need this

---

## Pattern: Multi-Architecture Support

**File**: `standard/flake.nix:24-33`

**Purpose**: Support multiple architectures in flake outputs

**Code**:
```nix
let
  systems = [
    "aarch64-linux"
    "i686-linux"
    "x86_64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
  forAllSystems = nixpkgs.lib.genAttrs systems;
in {
  packages = forAllSystems (system: ...);
  formatter = forAllSystems (system: ...);
};
```

**When to use**: When you want to support multiple architectures

**Benefit**: Packages and formatters available on all platforms

**Your config**: Likely already using similar pattern

---

## Pattern: Minimal Flake (Learning Reference)

**File**: `minimal/flake.nix`

**Purpose**: Show simplest possible flake structure

**Code**:
```nix
outputs = {self, nixpkgs, home-manager, ...} @ inputs: let
in {
  nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
    specialArgs = {inherit inputs;};
    modules = [./nixos/configuration.nix];
  };
  
  homeConfigurations."your-username@your-hostname" = 
    home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit inputs;};
      modules = [./home-manager/home.nix];
    };
};
```

**When to use**: As reference for minimal viable flake

**Benefit**: Shows what's essential vs. optional

**Your config**: Your config is more complex (intentionally)

---

## Comparison: Your Patterns vs nix-starter-configs

| Aspect | nix-starter-configs | Your nixos-config | Status |
|--------|-------------------|-------------------|--------|
| Module aggregation | `modules/nixos/default.nix` | `nixos-modules/default.nix` | ✅ Same |
| Overlay convention | Three overlays | Single `custom-packages.nix` | 🔄 Consider adopting |
| Hardware config | Separate file | Likely inline | 🔄 Consider separating |
| Host support | Single host | Multiple hosts | ✅ Your strength |
| User support | Single user | Multiple users | ✅ Your strength |
| Host overrides | N/A | `home-configurations/vino/hosts/` | ✅ Your strength |
| Shared modules | None | `shared-modules/` | ✅ Your strength |
| Lib utilities | None | `lib/` | ✅ Your strength |
| Flake modules | None | `flake-modules/` | ✅ Your strength |
| Secrets management | None | sops-nix | ✅ Your strength |

---

## Quick Decision Tree

**Q: Should I adopt the three-overlay convention?**
- If you have multiple types of package modifications → YES
- If you only have custom packages → NO (current approach is fine)

**Q: Should I separate hardware config?**
- If you regenerate hardware config often → YES
- If you rarely touch hardware config → NO (current approach is fine)

**Q: Should I add unstable packages access?**
- If you need bleeding-edge packages → YES
- If you're happy with stable → NO (not needed)

**Q: Should I simplify my config to match nix-starter-configs?**
- NO. Your config is more sophisticated and that's intentional.
- Keep your multi-host, multi-user, and secrets management.

---

## Files to Reference

- **Full analysis**: `docs/nix-starter-configs-analysis.md`
- **Executive summary**: `docs/nix-starter-refactor-summary.md`
- **This file**: `docs/nix-starter-patterns-reference.md`

