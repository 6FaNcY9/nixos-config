# nix-starter-configs Architecture Analysis

**Repository**: https://github.com/Misterio77/nix-starter-configs  
**Analysis Date**: May 13, 2026  
**Scope**: Flake layout, module organization, patterns, and refactor-relevant insights

---

## REPOSITORY STRUCTURE

### Top-Level Layout
```
nix-starter-configs/
├── flake.nix                 # Template registry (exports minimal/ and standard/)
├── flake.lock
├── minimal/                  # Minimal starter template
│   ├── flake.nix            # Bare-bones flake
│   ├── nixos/
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   └── home-manager/
│       └── home.nix
└── standard/                # Feature-rich starter template
    ├── flake.nix
    ├── nixos/
    │   ├── configuration.nix
    │   └── hardware-configuration.nix
    ├── home-manager/
    │   └── home.nix
    ├── modules/
    │   ├── nixos/
    │   │   └── default.nix   # Reusable NixOS modules registry
    │   └── home-manager/
    │       └── default.nix   # Reusable HM modules registry
    ├── overlays/
    │   └── default.nix       # Three overlay patterns (additions, modifications, unstable)
    └── pkgs/
        └── default.nix       # Custom package definitions
```

### Key Distinction: Minimal vs Standard

**Minimal** (`minimal/`):
- Single `flake.nix` with inline `nixosConfigurations` and `homeConfigurations`
- No custom packages, overlays, or module infrastructure
- Direct file references: `./nixos/configuration.nix`, `./home-manager/home.nix`
- Use case: Quick migration from legacy configs, learning flakes

**Standard** (`standard/`):
- Separate `flake.nix` with exported attributes for reusability
- Full infrastructure: `packages`, `overlays`, `nixosModules`, `homeManagerModules`
- Designed for sharing and extending
- Use case: Long-term configs with custom packages and community modules

---

## FLAKE ARCHITECTURE PATTERNS

### Minimal Flake Pattern (minimal/flake.nix)
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

**Observations**:
- **No `forAllSystems`**: Minimal doesn't abstract over architectures
- **Hardcoded `x86_64-linux`**: User must manually edit for their system
- **Direct module paths**: No intermediate aggregation layer
- **`specialArgs` vs `extraSpecialArgs`**: NixOS uses `specialArgs`, HM uses `extraSpecialArgs`

### Standard Flake Pattern (standard/flake.nix)
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

**Key Patterns**:
- **`forAllSystems` abstraction**: Enables multi-architecture support
- **Exported `overlays`, `nixosModules`, `homeManagerModules`**: Designed for flake composition
- **`import ./overlays {inherit inputs;}`**: Passes inputs to overlay registry
- **`import ./pkgs nixpkgs.legacyPackages.${system}`**: Curries pkgs into custom package definitions

---

## MODULE ORGANIZATION PATTERNS

### Overlay Registry Pattern (overlays/default.nix)
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

**Pattern Insights**:
- **Three-overlay convention**: Separates concerns (new packages, modifications, unstable access)
- **`final` vs `_prev`**: Uses underscore to signal unused parameter
- **`unstablePkgs` namespace**: Avoids collision with stable packages
- **Receives `inputs` at registry level**: Enables flake input access in overlays

### Custom Packages Pattern (pkgs/default.nix)
```nix
pkgs: {
  # example = pkgs.callPackage ./example { };
}
```

**Pattern Insights**:
- **Curried function**: Receives `pkgs` from overlay context
- **Uses `callPackage`**: Standard nixpkgs pattern for package definitions
- **Minimal boilerplate**: Single file for all custom packages

### Module Registries (modules/nixos/default.nix, modules/home-manager/default.nix)
```nix
# Add your reusable modules to this directory, on their own file
# These should be stuff you would like to share with others, not personal configs
{
  # my-module = import ./my-module.nix;
}
```

**Pattern Insights**:
- **Explicit intent**: Comments clarify these are for sharing, not personal config
- **One file per module**: Encourages modular design
- **Registry pattern**: Central `default.nix` aggregates all modules
- **Flat structure**: No nested subdirectories (keeps it simple)

---

## CONFIGURATION ENTRY POINTS

### NixOS Configuration (nixos/configuration.nix)
```nix
{inputs, lib, config, pkgs, ...}: {
  imports = [
    # inputs.self.nixosModules.example
    # inputs.hardware.nixosModules.common-cpu-amd
    # ./users.nix
    ./hardware-configuration.nix
  ];
  
  nixpkgs = {
    overlays = [
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };
  
  nix = {
    settings.experimental-features = "nix-command flakes";
    settings.flake-registry = "";  # Disable global registry
    channel.enable = false;         # Disable channels
  };
  
  networking.hostName = "your-hostname";
  users.users.your-username = {
    isNormalUser = true;
    initialPassword = "correcthorsebatterystaple";
    openssh.authorizedKeys.keys = [];
  };
}
```

**Pattern Insights**:
- **Receives `inputs` as special arg**: Enables access to flake inputs
- **Overlays applied at system level**: All overlays available to all packages
- **Opinionated nix settings**: Disables channels and global registry (flakes-first philosophy)
- **Hardware config separation**: Keeps generated config separate from hand-written config
- **Commented examples**: Shows how to import custom modules and hardware profiles

### Home-Manager Configuration (home-manager/home.nix)
```nix
{inputs, lib, config, pkgs, ...}: {
  imports = [
    # inputs.self.homeManagerModules.example
    # inputs.nix-colors.homeManagerModules.default
    # ./nvim.nix
  ];
  
  nixpkgs = {
    overlays = [
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.unstable-packages
    ];
    config.allowUnfree = true;
  };
  
  home = {
    username = "your-username";
    homeDirectory = "/home/your-username";
  };
  
  programs.home-manager.enable = true;
  programs.git.enable = true;
  home.stateVersion = "25.11";
}
```

**Pattern Insights**:
- **Mirrors NixOS structure**: Same `imports`, `nixpkgs.overlays` pattern
- **Separate `home` attribute**: Sets username and homeDirectory
- **`stateVersion` tracking**: Prevents accidental downgrades
- **Minimal defaults**: Only enables home-manager and git by default

---

## KEY ARCHITECTURAL DECISIONS

### 1. **Two-Template Strategy**
- **Minimal**: Lowest barrier to entry, teaches flakes fundamentals
- **Standard**: Provides infrastructure for real-world configs
- **Benefit**: Users can start simple and graduate to standard
- **Trade-off**: Requires maintaining two separate flake.nix files

### 2. **Overlay-First Package Management**
- Custom packages defined in `pkgs/`, exposed via overlay
- Overlays applied at both NixOS and HM level
- Enables `pkgs.unstablePkgs` access pattern
- **Benefit**: Consistent package resolution across system and user
- **Trade-off**: Requires understanding overlay mechanics

### 3. **Module Registry Pattern**
- `modules/nixos/default.nix` and `modules/home-manager/default.nix` aggregate modules
- Encourages one-module-per-file structure
- Modules marked as "for sharing" (not personal config)
- **Benefit**: Clear separation between reusable and personal config
- **Trade-off**: Extra indirection for simple configs

### 4. **Flake Inputs Injection via `specialArgs`**
- NixOS: `specialArgs = {inherit inputs;}`
- HM: `extraSpecialArgs = {inherit inputs;}`
- Enables access to flake inputs in all modules
- **Benefit**: Modules can reference other flake inputs (e.g., `inputs.hardware`)
- **Trade-off**: Couples modules to flake structure

### 5. **Opinionated Nix Settings**
```nix
nix.settings.experimental-features = "nix-command flakes";
nix.settings.flake-registry = "";      # Disable global registry
nix.channel.enable = false;             # Disable channels
```
- Flakes-first philosophy
- Prevents accidental use of legacy commands
- **Benefit**: Clear, modern Nix experience
- **Trade-off**: Breaks compatibility with channel-based workflows

### 6. **Hardware Configuration Separation**
- `hardware-configuration.nix` kept separate from `configuration.nix`
- Generated by `nixos-generate-config`, not hand-edited
- Imported into main config
- **Benefit**: Preserves hardware config across config rewrites
- **Trade-off**: Adds one more file to manage

---

## COMPARISON WITH YOUR CURRENT STRUCTURE

### Your Structure (nixos-config)
```
nixos-config/
├── flake.nix
├── nixos-configurations/
│   └── bandit/default.nix
├── nixos-modules/
│   └── default.nix (aggregator)
├── home-configurations/
│   ├── vino/default.nix
│   └── vino/hosts/bandit.nix
├── home-modules/
│   └── default.nix (aggregator)
├── overlays/
│   └── custom-packages.nix
├── lib/
├── flake-modules/
└── shared-modules/
```

### Key Differences

| Aspect | nix-starter-configs | Your nixos-config |
|--------|-------------------|-------------------|
| **Flake inputs** | Minimal (nixpkgs, home-manager) | Extended (likely more inputs) |
| **Module organization** | Flat (`modules/nixos/`, `modules/home-manager/`) | Hierarchical (`nixos-modules/`, `home-modules/`, `shared-modules/`) |
| **Custom packages** | Single `pkgs/default.nix` | Single `overlays/custom-packages.nix` |
| **Host configuration** | Single `nixosConfigurations.your-hostname` | Multi-host (`nixos-configurations/bandit/`) |
| **User configuration** | Single `homeConfigurations."user@host"` | Multi-user + host-specific overrides (`home-configurations/vino/hosts/`) |
| **Lib utilities** | None (uses nixpkgs.lib) | Custom `lib/` directory |
| **Flake modules** | None | `flake-modules/` for modular flake.nix |
| **Secrets** | None | sops-nix integration |

---

## STRONGEST TAKEAWAYS FOR YOUR REFACTOR

### 1. **Overlay Registry Pattern is Elegant**
The three-overlay convention (`additions`, `modifications`, `unstable-packages`) is clean and separates concerns well. Your single `overlays/custom-packages.nix` could benefit from this structure if you have multiple overlay types.

**Applicable to your config**: YES
- Separate custom packages, modifications, and unstable access
- Makes intent explicit
- Easier to understand what each overlay does

### 2. **Module Registry Aggregation is Simple**
Using `default.nix` as a registry that imports individual modules is straightforward and scales well. Your `nixos-modules/default.nix` and `home-modules/default.nix` already follow this pattern.

**Applicable to your config**: ALREADY USING
- Your pattern: `nixos-modules/default.nix` aggregates modules
- No changes needed here

### 3. **Hardware Config Separation is Important**
Keeping `hardware-configuration.nix` separate from `configuration.nix` prevents accidental overwrites during config rewrites.

**Applicable to your config**: PARTIALLY
- Your `nixos-configurations/bandit/default.nix` likely includes hardware config
- Consider extracting to `nixos-configurations/bandit/hardware.nix`

### 4. **Flake Inputs Injection Enables Module Reusability**
Using `specialArgs = {inherit inputs;}` allows modules to reference other flake inputs. This is powerful for composing external modules (e.g., `inputs.hardware`, `inputs.nix-colors`).

**Applicable to your config**: YES
- Enables modules to use `inputs.self.nixosModules.*` patterns
- Allows importing external flake modules without coupling

### 5. **Two-Template Strategy Shows Graduation Path**
The minimal/standard split shows users a clear progression from simple to complex. Your refactor could benefit from thinking about "what's the minimal viable config?" vs. "what's the full-featured config?"

**Applicable to your config**: MAYBE
- Your config is already full-featured
- Consider documenting a "minimal subset" for onboarding

### 6. **Opinionated Nix Settings are Explicit**
The flakes-first philosophy (disabling channels, global registry) is clear and prevents confusion.

**Applicable to your config**: YES
- Your config likely already does this
- Document why these settings matter

### 7. **Host-Specific Overrides Pattern**
Your `home-configurations/vino/hosts/bandit.nix` pattern is more sophisticated than nix-starter-configs. This is a strength you should keep.

**Applicable to your config**: ALREADY USING
- Your pattern: `home-configurations/vino/` + `hosts/bandit.nix` for overrides
- More flexible than nix-starter-configs's single `homeConfigurations` entry

### 8. **Shared Modules Directory is Powerful**
Your `shared-modules/` directory (not in nix-starter-configs) is a good addition for code reuse between NixOS and HM.

**Applicable to your config**: ALREADY USING
- Keep this pattern
- Document what goes in shared-modules vs. nixos-modules vs. home-modules

### 9. **Lib Directory for Custom Functions**
Your `lib/` directory (not in nix-starter-configs) is valuable for utility functions and custom derivations.

**Applicable to your config**: ALREADY USING
- Document what functions live here
- Consider organizing by category (e.g., `lib/builders/`, `lib/helpers/`)

### 10. **Flake Modules for Modular Flake.nix**
Your `flake-modules/` directory (not in nix-starter-configs) is a sophisticated pattern for breaking up `flake.nix`. This is a strength.

**Applicable to your config**: ALREADY USING
- Document how flake-modules are composed
- Show examples of what goes in each module

---

## WHAT DOESN'T TRANSFER WELL

### 1. **Single-Host, Single-User Assumption**
nix-starter-configs assumes one host and one user. Your config supports multiple hosts and users. Don't simplify to match nix-starter-configs.

### 2. **No Secrets Management**
nix-starter-configs has no sops-nix integration. Your config does. This is a good addition that nix-starter-configs doesn't cover.

### 3. **No Dev Shell or Testing**
nix-starter-configs doesn't include dev shells or testing patterns. Your config may have these. Don't remove them.

### 4. **No Justfile or Scripts**
nix-starter-configs has no build automation. Your `justfile` and `scripts/` are valuable. Keep them.

---

## OPINIONATED CHOICES IN NIX-STARTER-CONFIGS

### 1. **Flakes-First Philosophy**
- Disables channels: `nix.channel.enable = false;`
- Disables global registry: `nix.settings.flake-registry = "";`
- **Opinion**: Modern, explicit, no legacy baggage
- **Risk**: Breaks compatibility with channel-based workflows

### 2. **Three-Overlay Convention**
- Separates additions, modifications, unstable
- **Opinion**: Clear separation of concerns
- **Risk**: Opinionated; some users may want different organization

### 3. **Module Registry Pattern**
- One module per file, aggregated in `default.nix`
- **Opinion**: Simple, scalable
- **Risk**: Requires discipline; easy to add modules to wrong place

### 4. **Minimal vs Standard Split**
- Two separate templates
- **Opinion**: Caters to different user levels
- **Risk**: Maintenance burden; must keep both in sync

---

## SPECIFIC PATHS AND EXAMPLES

### Overlay Application Pattern
```nix
# In nixos/configuration.nix
nixpkgs.overlays = [
  inputs.self.overlays.additions
  inputs.self.overlays.modifications
  inputs.self.overlays.unstable-packages
];
```

**Location**: `standard/nixos/configuration.nix:28-32`

### Custom Package Definition
```nix
# In pkgs/default.nix
pkgs: {
  example = pkgs.callPackage ./example { };
}
```

**Location**: `standard/pkgs/default.nix:3-4`

### Module Import Pattern
```nix
# In nixos/configuration.nix
imports = [
  inputs.self.nixosModules.example
  inputs.hardware.nixosModules.common-cpu-amd
  ./hardware-configuration.nix
];
```

**Location**: `standard/nixos/configuration.nix:11-24`

### Unstable Packages Access
```nix
# In overlays/default.nix
unstable-packages = final: _prev: {
  unstablePkgs = import inputs.nixpkgs-unstable {
    system = final.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
};
```

**Location**: `standard/overlays/default.nix:16-23`

### Usage in Config
```nix
# Access unstable packages as pkgs.unstablePkgs.package-name
home.packages = with pkgs; [
  unstablePkgs.neovim
];
```

---

## MAINTAINABILITY TRADEOFFS

### Strengths
1. **Minimal boilerplate**: Two templates show clear progression
2. **Clear intent**: Comments explain what each section does
3. **Modular design**: Overlays, packages, and modules are separate
4. **Reusability**: Exported `overlays`, `nixosModules`, `homeManagerModules` enable composition
5. **Flakes-first**: No legacy channel baggage

### Weaknesses
1. **Hardcoded architecture in minimal**: Users must manually edit `x86_64-linux`
2. **Duplicate flake.nix**: Minimal and standard have similar but different flake.nix files
3. **No multi-host/multi-user support**: Assumes single host and user
4. **No secrets management**: No sops-nix or similar integration
5. **No dev shell**: No development environment defined
6. **Limited documentation**: Comments are helpful but sparse

---

## RECOMMENDATIONS FOR YOUR REFACTOR

### Keep
1. Your `shared-modules/` pattern (not in nix-starter-configs)
2. Your `lib/` directory with custom functions
3. Your `flake-modules/` for modular flake.nix
4. Your host-specific overrides pattern (`home-configurations/vino/hosts/`)
5. Your sops-nix integration for secrets

### Consider Adopting
1. Three-overlay convention (`additions`, `modifications`, `unstable-packages`)
2. Explicit hardware config separation
3. Opinionated nix settings (flakes-first)
4. Module registry pattern (you already use this)

### Don't Adopt
1. Minimal/standard split (your config is already full-featured)
2. Single-host assumption (you support multiple hosts)
3. Lack of secrets management (you have sops-nix)

---

## EXACT FILE REFERENCES

| File | Purpose | Key Pattern |
|------|---------|------------|
| `standard/flake.nix:37` | Custom packages export | `packages = forAllSystems (system: import ./pkgs ...)` |
| `standard/flake.nix:43` | Overlay export | `overlays = import ./overlays {inherit inputs;}` |
| `standard/flake.nix:46-49` | Module exports | `nixosModules = import ./modules/nixos` |
| `standard/overlays/default.nix:5` | Additions overlay | `additions = final: _prev: import ../pkgs final.pkgs` |
| `standard/overlays/default.nix:18-23` | Unstable packages | `unstablePkgs = import inputs.nixpkgs-unstable ...` |
| `standard/nixos/configuration.nix:28-32` | Overlay application | `overlays = [inputs.self.overlays.*]` |
| `standard/nixos/configuration.nix:54-59` | Nix settings | `nix.settings.experimental-features`, `flake-registry`, `channel.enable` |
| `standard/modules/nixos/default.nix` | Module registry | Empty template for user-defined modules |
| `standard/pkgs/default.nix` | Custom packages | `pkgs: { example = pkgs.callPackage ./example { }; }` |

