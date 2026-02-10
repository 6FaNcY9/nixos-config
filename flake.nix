# flake.nix (keep on SSD at: nixos-config/flake.nix)
{
  description = "Framework 13 AMD: NixOS unstable + i3 + XFCE services + Home Manager + Stylix Gruvbox";

  nixConfig = {
    extra-experimental-features = "nix-command flakes";
  };

  inputs = {
    # Primary: Unstable (latest packages, community standard pattern)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Fallback: Stable 25.11 (when unstable breaks)
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Codex (always up-to-date flake)
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenCode (track upstream; update via `nix flake update opencode`)
    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware quirks for Framework
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };
    # Home Manager follows unstable (community pattern)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim (Home Manager module) - use unstable for latest features
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Stylix theming - use unstable
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secrets management (sops)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pre-commit tooling
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake composition
    flake-parts.url = "github:hercules-ci/flake-parts";
    ez-configs.url = "github:ehllie/ez-configs";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mission-control.url = "github:Platonic-Systems/mission-control";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-root.url = "github:srid/flake-root";

    # Wallpaper
    gruvbox-wallpaper.url = "github:AngelJumbo/gruvbox-wallpapers";
  };

  outputs = inputs @ {flake-parts, ...}: let
    system = "x86_64-linux";
    primaryHost = "bandit";
    username = "vino";
    repoRoot = "/home/${username}/src/nixos-config";

    overlays = import ./overlays {inherit inputs;};

    pkgsFor = system:
      import inputs.nixpkgs {
        inherit system;
        overlays = [overlays.default];
        config.allowUnfree = true;
      };
  in
    flake-parts.lib.mkFlake {inherit inputs;} ({self, ...}: {
      systems = [system];

      # Enable flake-parts debug mode for development (adds allSystems/currentSystem outputs)
      # Keep false in normal builds to avoid "unknown flake output" warnings.
      debug = false;

      imports = [
        inputs.ez-configs.flakeModule
        inputs.pre-commit-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.mission-control.flakeModule
        inputs.devshell.flakeModule
        inputs.flake-root.flakeModule
      ];

      ezConfigs = {
        root = ./.;
        globalArgs = {
          inherit inputs username repoRoot;
        };

        nixos.hosts.${primaryHost}.userHomeModules = ["vino"];
      };

      perSystem = {
        system,
        config,
        lib,
        ...
      }: let
        pkgs = pkgsFor system;
        opencodePkg = pkgs.opencode;
        missionControlWrapper = config.mission-control.wrapper;
        maintenancePackages = [pkgs.pre-commit pkgs.nix missionControlWrapper] ++ config.pre-commit.settings.enabledPackages;

        # Import our custom library helpers
        cfgLib = import ./lib {inherit lib;};

        # Common utilities for project devShells (CLI tools only, no flake management)
        commonDevPackages = with pkgs; [
          git
          gh # GitHub CLI
          jq
          yq-go
          curl
          wget
          htop
          btop
          ripgrep
          fd
          fzf
          eza
          bat
          tree
          # Nix linting tools
          statix
          deadnix
        ];

        # Maintenance packages include mission-control for flake management
        maintenanceDevPackages = maintenancePackages ++ commonDevPackages ++ [config.packages.mission-control-completions];

        repoRootCmd = ''repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"'';

        # Shared startup configuration for devshells (DRY principle)
        devshellStartup = {
          load-mission-control-completions.text = ''
            # Load mission-control completions
            export MISSION_CONTROL_COMPLETIONS="${config.packages.mission-control-completions}"
            # For bash: source completion if bash-completion is available
            if [ -n "$BASH_VERSION" ] && [ -f "$MISSION_CONTROL_COMPLETIONS/share/bash-completion/completions/," ]; then
              source "$MISSION_CONTROL_COMPLETIONS/share/bash-completion/completions/,"
            fi
          '';
          show-devshell-info.text = ''
            # Show useful context information
            if command -v git >/dev/null 2>&1; then
              REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
              if [ -n "$REPO_ROOT" ]; then
                BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
                DIRTY=$(git status --porcelain 2>/dev/null | wc -l)
                echo "📦 Repository: $(basename "$REPO_ROOT")"
                if [ "$DIRTY" -gt 0 ]; then
                  echo "🌿 Branch: $BRANCH (''${DIRTY} uncommitted changes)"
                else
                  echo "🌿 Branch: $BRANCH (clean)"
                fi
              fi
            fi
            if [ -n "''${DIRENV_DIR:-}" ]; then
              echo "🔄 Direnv: active"
            fi
            echo ""
          '';
        };

        mkApp = name: runtimeInputs: description: text: {
          type = "app";
          program = "${pkgs.writeShellApplication {inherit name runtimeInputs text;}}/bin/${name}";
          meta = {inherit description;};
        };
      in {
        treefmt = {
          projectRootFile = "flake.nix";
          programs.alejandra.enable = true;
          flakeCheck = true;
        };

        formatter = config.treefmt.build.wrapper;

        mission-control = {
          scripts = {
            fmt = {
              description = "Format Nix files";
              exec = config.treefmt.build.wrapper;
              category = "Dev Tools";
            };
            qa = {
              description = "Format, lint, and flake check";
              exec = "nix run .#qa";
              category = "Dev Tools";
            };
            update = {
              description = "Update flake inputs";
              exec = "nix run .#update";
              category = "Dev Tools";
            };
            clean = {
              description = "Remove result symlinks";
              exec = "nix run .#clean";
              category = "Dev Tools";
            };
            sysinfo = {
              description = "System diagnostics and status";
              exec = "nix run .#sysinfo";
              category = "Analysis";
            };
            tree = {
              description = "Visualize nix dependencies";
              exec = "nix-tree";
              category = "Analysis";
            };
            web = {
              description = "Enter web development shell";
              exec = "nix develop .#web";
              category = "Dev Shells";
            };
            rust = {
              description = "Enter Rust development shell";
              exec = "nix develop .#rust";
              category = "Dev Shells";
            };
            go = {
              description = "Enter Go development shell";
              exec = "nix develop .#go";
              category = "Dev Shells";
            };
            flask = {
              description = "Enter Flask development shell";
              exec = "nix develop .#flask";
              category = "Dev Shells";
            };
            agents = {
              description = "Enter Agent Tools shell";
              exec = "nix develop .#agents";
              category = "Dev Shells";
            };
            database = {
              description = "Enter Database development shell";
              exec = "nix develop .#database";
              category = "Dev Shells";
            };
          };
        };

        # nix eval fix (wrap outPath as a derivation)
        packages = {
          gruvboxWallpaperOutPath = pkgs.writeText "gruvbox-wallpaper-outPath" inputs.gruvbox-wallpaper.outPath;

          # Shell completions for mission-control (,) command
          # Dynamically generated from config.mission-control.scripts
          mission-control-completions = let
            inherit (config.mission-control) scripts;
            scriptNames = builtins.attrNames scripts;
            # Generate fish completions
            fishCompletions =
              lib.concatMapStrings (name: ''
                complete -c ',' -f -a "${name}" -d "${scripts.${name}.description}"
              '')
              scriptNames;
            # Generate bash command list
            bashCommands = lib.concatStringsSep " " scriptNames;
          in
            pkgs.symlinkJoin {
              name = "mission-control-completions";
              paths = [
                # Fish completions
                (pkgs.writeTextFile {
                  name = "mission-control-fish-completions";
                  destination = "/share/fish/vendor_completions.d/mission-control.fish";
                  text = ''
                    # Fish shell completions for mission-control (,) command
                    # Auto-generated from flake mission-control configuration
                    ${fishCompletions}
                  '';
                })
                # Bash completions
                (pkgs.writeTextFile {
                  name = "mission-control-bash-completions";
                  destination = "/share/bash-completion/completions/,";
                  text = ''
                    # Bash completion for mission-control (,) command
                    # Auto-generated from flake mission-control configuration
                    _mission_control_completion() {
                      local cur="''${COMP_WORDS[COMP_CWORD]}"
                      local commands="${bashCommands}"
                      COMPREPLY=($(compgen -W "$commands" -- "$cur"))
                    }
                    complete -F _mission_control_completion ','
                  '';
                })
              ];
            };
        };

        pre-commit = {
          check.enable = true;
          settings.hooks = {
            treefmt = {
              enable = true;
              package = config.treefmt.build.wrapper;
            };
            statix.enable = true;
            deadnix.enable = true;
            shellcheck.enable = true;
            shfmt.enable = true;

            # Security: Prevent committing unencrypted secrets
            detect-unencrypted-secrets = {
              enable = true;
              name = "Detect unencrypted secrets";
              entry = "${pkgs.writeShellScript "detect-unencrypted-secrets" ''
                set -euo pipefail
                # Check for unencrypted YAML files in secrets/ directory
                if [ -d secrets ]; then
                  for file in secrets/*.yaml secrets/*.yml; do
                    [ -e "$file" ] || continue
                    if ! grep -q "^sops:" "$file" 2>/dev/null; then
                      echo "❌ ERROR: Unencrypted secret detected: $file"
                      echo "   All secrets must be encrypted with sops."
                      echo "   Run: sops secrets/$(basename "$file")"
                      exit 1
                    fi
                  done
                fi
              ''}";
              files = "^secrets/.*\\.(yaml|yml)$";
              pass_filenames = false;
            };

            # Security: Detect hardcoded credentials and tokens
            detect-secrets = {
              enable = true;
              name = "Detect hardcoded secrets";
              entry = "${pkgs.writeShellScript "detect-hardcoded-secrets" ''
                set -euo pipefail
                # Patterns to detect (exclude false positives)
                PATTERNS=(
                  'password\s*=\s*["\x27][^"\x27]{8,}'
                  'api[_-]?key\s*=\s*["\x27][A-Za-z0-9]{20,}'
                  'secret\s*=\s*["\x27][^"\x27]{12,}'
                  'token\s*=\s*["\x27][A-Za-z0-9]{20,}'
                  'AKIA[0-9A-Z]{16}'  # AWS Access Key
                  'ghp_[0-9a-zA-Z]{36}'  # GitHub Personal Access Token
                )

                EXIT_CODE=0
                for file in "$@"; do
                  # Skip encrypted files, lock files, and secrets directory
                  if [[ "$file" =~ (flake\.lock|.*\.age|.*\.gpg|secrets/|\.git/) ]]; then
                    continue
                  fi

                  # Only check text files
                  if [[ ! "$file" =~ \.(nix|sh|bash|fish|yaml|yml|json|toml|env)$ ]]; then
                    continue
                  fi

                  for pattern in "''${PATTERNS[@]}"; do
                    if grep -iE "$pattern" "$file" >/dev/null 2>&1; then
                      echo "❌ WARNING: Potential hardcoded secret in: $file"
                      echo "   Pattern matched: $pattern"
                      echo "   Please use sops-nix for secrets or environment variables."
                      EXIT_CODE=1
                    fi
                  done
                done
                exit $EXIT_CODE
              ''}";
              files = ".*";
            };

            # Performance: Warn about large binary files
            check-large-files = {
              enable = true;
              name = "Check for large files";
              entry = "${pkgs.writeShellScript "check-large-files" ''
                set -euo pipefail
                MAX_SIZE_KB=500  # 500KB threshold
                EXIT_CODE=0

                for file in "$@"; do
                  # Skip lock files and git directory
                  if [[ "$file" =~ (flake\.lock|\.git/) ]]; then
                    continue
                  fi

                  if [ -f "$file" ] && [ ! -h "$file" ]; then
                    size_kb=$(du -k "$file" | cut -f1)
                    if [ "$size_kb" -gt "$MAX_SIZE_KB" ]; then
                      echo "⚠️  WARNING: Large file detected: $file ($size_kb KB)"
                      echo "   Consider:"
                      echo "   - Using Git LFS for binaries"
                      echo "   - Adding to .gitignore if temporary"
                      echo "   - Compressing if possible"
                      EXIT_CODE=1
                    fi
                  fi
                done
                exit $EXIT_CODE
              ''}";
              files = ".*";
            };
          };
        };

        apps = {
          update = mkApp "update" [pkgs.coreutils pkgs.git pkgs.nix] "Update flake inputs" ''
            set -euo pipefail
            ${repoRootCmd}
            cd "$repo_root"
            nix flake update
          '';

          clean = mkApp "clean" [pkgs.coreutils pkgs.git] "Remove result symlinks" ''
            set -euo pipefail
            ${repoRootCmd}
            cd "$repo_root"
            rm -f result result-*
          '';

          qa =
            mkApp "qa" [
              pkgs.alejandra
              pkgs.coreutils
              pkgs.deadnix
              pkgs.git
              pkgs.nix
              pkgs.pre-commit
              pkgs.statix
              config.treefmt.build.wrapper
            ] "Format, lint, and run flake checks" ''
              set -euo pipefail
              ${repoRootCmd}
              cd "$repo_root"
              treefmt --no-cache
              statix check .
              deadnix -f .
              pre-commit run --all-files --config ${config.pre-commit.settings.configFile}
              nix flake check --option warn-dirty false
            '';

          commit =
            mkApp "commit" [
              pkgs.alejandra
              pkgs.coreutils
              pkgs.deadnix
              pkgs.git
              pkgs.nix
              pkgs.pre-commit
              pkgs.statix
              config.treefmt.build.wrapper
            ] "Run QA, stage, and commit with editor" ''
              set -euo pipefail
              ${repoRootCmd}
              cd "$repo_root"
              treefmt --no-cache
              statix check .
              deadnix -f .
              pre-commit run --all-files --config ${config.pre-commit.settings.configFile}
              nix flake check --option warn-dirty false

              git add -A

              # Use git commit with editor (like normal git workflow)
              # This properly handles multi-line messages
              git commit --no-verify

              rm -f result result-*
            '';

          generate-age-key =
            mkApp "generate-age-key" [
              pkgs.age
              pkgs.coreutils
            ] "Generate Age key for sops-nix encryption" ''
              set -euo pipefail

              KEY_DIR="$HOME/.config/sops/age"
              KEY_FILE="$KEY_DIR/keys.txt"

              echo "🔑 Age Key Generation for sops-nix"
              echo "=================================="
              echo ""

              # Check if key already exists
              if [ -f "$KEY_FILE" ]; then
                echo "⚠️  Age key already exists at: $KEY_FILE"
                echo ""
                echo "Current public key:"
                grep "public key:" "$KEY_FILE" || echo "(Could not read public key)"
                echo ""
                read -p "Generate a new key anyway? This will backup the old one. [y/N] " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                  echo "Aborted."
                  exit 0
                fi
                # Backup existing key
                BACKUP="$KEY_FILE.backup.$(date +%Y%m%d-%H%M%S)"
                cp "$KEY_FILE" "$BACKUP"
                echo "✅ Backed up existing key to: $BACKUP"
                echo ""
              fi

              # Create directory
              mkdir -p "$KEY_DIR"
              chmod 700 "$KEY_DIR"

              # Generate new key
              echo "Generating new Age key..."
              age-keygen -o "$KEY_FILE"
              chmod 600 "$KEY_FILE"

              echo ""
              echo "✅ Age key generated successfully!"
              echo ""
              echo "📍 Location: $KEY_FILE"
              echo ""
              echo "📋 Your public key (add this to .sops.yaml):"
              echo "───────────────────────────────────────────────"
              grep "public key:" "$KEY_FILE"
              echo "───────────────────────────────────────────────"
              echo ""
              echo "📖 Next steps:"
              echo "  1. Add the public key above to .sops.yaml"
              echo "  2. Run: sops updatekeys secrets/*.yaml"
              echo "  3. Commit the updated secrets"
              echo ""
            '';

          sysinfo =
            mkApp "sysinfo" [
              pkgs.coreutils
              pkgs.gnupg
              pkgs.git
              pkgs.nix
              pkgs.gnugrep
              pkgs.gawk
            ] "System diagnostics and configuration status" ''
              set -euo pipefail

              # Color codes for output
              RED='\033[0;31m'
              GREEN='\033[0;32m'
              YELLOW='\033[1;33m'
              BLUE='\033[0;34m'
              NC='\033[0m' # No Color

              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo "   NixOS Configuration Diagnostics"
              echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
              echo ""

              # ========================================
              # Hardware Device Detection
              # ========================================
              echo -e "''${BLUE}🖥️  Hardware Devices''${NC}"
              echo "────────────────────────────────────────────"

              # Battery detection
              if BAT_DEVICE=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -type l -printf '%f\n' 2>/dev/null | head -1); then
                if [ -n "$BAT_DEVICE" ]; then
                  echo -e "''${GREEN}✓''${NC} Battery: $BAT_DEVICE"
                else
                  echo -e "''${YELLOW}⚠''${NC} Battery: Not detected (desktop system?)"
                fi
              else
                echo -e "''${YELLOW}⚠''${NC} Battery: Not detected (desktop system?)"
              fi

              # Backlight detection
              if BACKLIGHT_DEVICE=$(find /sys/class/backlight -maxdepth 1 -mindepth 1 -type l -printf '%f\n' 2>/dev/null | head -1); then
                if [ -n "$BACKLIGHT_DEVICE" ]; then
                  echo -e "''${GREEN}✓''${NC} Backlight: $BACKLIGHT_DEVICE"
                else
                  echo -e "''${YELLOW}⚠''${NC} Backlight: Not detected (desktop system?)"
                fi
              else
                echo -e "''${YELLOW}⚠''${NC} Backlight: Not detected (desktop system?)"
              fi

              echo ""

              # ========================================
              # Secrets Management Status
              # ========================================
              echo -e "''${BLUE}🔐 Secrets Management''${NC}"
              echo "────────────────────────────────────────────"

              # Age key check
              AGE_KEY="$HOME/.config/sops/age/keys.txt"
              if [ -f "$AGE_KEY" ]; then
                echo -e "''${GREEN}✓''${NC} Age key: Present ($AGE_KEY)"
                if AGE_PUB=$(grep "public key:" "$AGE_KEY" 2>/dev/null); then
                  echo "  Public: $(echo "$AGE_PUB" | awk '{print $NF}')"
                fi
              else
                echo -e "''${RED}✗''${NC} Age key: Missing"
                echo "  Run: nix run .#generate-age-key"
              fi

              # GPG key check
              GPG_KEY="FC8B68693AF4E0D9DC84A4D3B872E229ADE55151"
              if gpg --list-secret-keys "$GPG_KEY" >/dev/null 2>&1; then
                echo -e "''${GREEN}✓''${NC} GPG signing key: Imported ($GPG_KEY)"
              else
                echo -e "''${YELLOW}⚠''${NC} GPG signing key: Not imported"
                echo "  Key will auto-import on next home-manager activation"
              fi

              # Secrets directory check
              SECRETS_DIR="$HOME/.config/sops-nix/secrets"
              if [ -d "$SECRETS_DIR" ]; then
                SECRET_COUNT=$(find "$SECRETS_DIR" -type f -o -type l 2>/dev/null | wc -l)
                if [ "$SECRET_COUNT" -gt 0 ]; then
                  echo -e "''${GREEN}✓''${NC} Decrypted secrets: $SECRET_COUNT available"
                else
                  echo -e "''${YELLOW}⚠''${NC} Decrypted secrets: Directory exists but empty"
                fi
              else
                echo -e "''${YELLOW}⚠''${NC} Decrypted secrets: Not yet activated"
                echo "  Run: nh os switch"
              fi

              echo ""

              # ========================================
              # Git Repository Status
              # ========================================
              echo -e "''${BLUE}📦 Repository Status''${NC}"
              echo "────────────────────────────────────────────"

              ${repoRootCmd}
              cd "$repo_root"

              # Git status
              if git diff-index --quiet HEAD -- 2>/dev/null; then
                echo -e "''${GREEN}✓''${NC} Git status: Clean"
              else
                DIRTY_COUNT=$(git status --porcelain | wc -l)
                echo -e "''${YELLOW}⚠''${NC} Git status: $DIRTY_COUNT uncommitted changes"
                echo "  Run: git status"
              fi

              # Current branch
              BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
              echo "  Branch: $BRANCH"

              # Last commit
              LAST_COMMIT=$(git log -1 --format="%h - %s" 2>/dev/null || echo "unknown")
              echo "  Last commit: $LAST_COMMIT"

              echo ""

              # ========================================
              # System Information
              # ========================================
              echo -e "''${BLUE}💻 System Information''${NC}"
              echo "────────────────────────────────────────────"

              # Hostname
              HOSTNAME=$(hostname)
              echo "  Hostname: $HOSTNAME"

              # NixOS version
              if [ -f /etc/os-release ]; then
                NIXOS_VERSION=$(grep "VERSION=" /etc/os-release | cut -d'"' -f2 || echo "unknown")
                echo "  NixOS: $NIXOS_VERSION"
              fi

              # Current generation
              if [ -e /run/current-system ]; then
                CURRENT_GEN=$(readlink /run/current-system | grep -oP 'system-\K[0-9]+-link' || echo "unknown")
                echo "  Generation: $CURRENT_GEN"
              fi

              echo ""

              # ========================================
              # Nix Store Status
              # ========================================
              echo -e "''${BLUE}🗄️  Nix Store Status''${NC}"
              echo "────────────────────────────────────────────"

              # Store size
              if STORE_SIZE=$(du -sh /nix/store 2>/dev/null | awk '{print $1}'); then
                echo "  Store size: $STORE_SIZE"
              fi

              # Check if optimization is beneficial
              if command -v nix-store >/dev/null 2>&1; then
                echo "  Optimization: Run 'sudo nix-store --optimise' to deduplicate"
              fi

              # Generation count
              if [ -d /nix/var/nix/profiles ]; then
                GEN_COUNT=$(find /nix/var/nix/profiles -maxdepth 1 -name 'system-*-link' 2>/dev/null | wc -l)
                echo "  Generations: $GEN_COUNT (clean old: nh clean all --keep 5)"
              fi

              echo ""

              # ========================================
              # Quick Actions
              # ========================================
              echo -e "''${BLUE}⚡ Quick Actions''${NC}"
              echo "────────────────────────────────────────────"
              echo "  Update system: nh os switch"
              echo "  Update inputs: nix flake update"
              echo "  Run QA checks: nix run .#qa"
              echo "  Clean old gens: nh clean all --keep 5"
              echo "  Optimize store: sudo nix-store --optimise"
              echo ""
            '';

          cachix-push =
            mkApp "cachix-push" [
              pkgs.cachix
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.nix
            ] "Push current system build to Cachix" ''
              set -euo pipefail

              CACHE_NAME="vino-nixos-config"
              TOKEN_PATH="$HOME/.config/sops-nix/secrets/cachix_auth_token"

              echo "🚀 Cachix Push Utility"
              echo "======================"
              echo ""

              # Check if token exists
              if [ ! -f "$TOKEN_PATH" ]; then
                echo "❌ ERROR: Cachix auth token not found at: $TOKEN_PATH"
                echo ""
                echo "Make sure secrets are activated:"
                echo "  nh home switch"
                exit 1
              fi

              # Export token for cachix
              CACHIX_AUTH_TOKEN=$(cat "$TOKEN_PATH")
              export CACHIX_AUTH_TOKEN

              echo "📦 Building current system configuration..."
              SYSTEM_PATH=$(nix build --no-link --print-out-paths .#nixosConfigurations.${primaryHost}.config.system.build.toplevel 2>&1 | tail -1)

              if [ -z "$SYSTEM_PATH" ]; then
                echo "❌ ERROR: Failed to build system"
                exit 1
              fi

              echo "✅ Built: $SYSTEM_PATH"
              echo ""
              echo "⬆️  Pushing to Cachix cache: $CACHE_NAME"
              echo ""

              # Push to cachix
              cachix push "$CACHE_NAME" "$SYSTEM_PATH"

              echo ""
              echo "✅ Successfully pushed to $CACHE_NAME!"
              echo ""
              echo "Your cache URL: https://$CACHE_NAME.cachix.org"
            '';
        };

        # Maintenance: static checks + eval targets
        checks = {
          nixos-bandit = self.nixosConfigurations.${primaryHost}.config.system.build.toplevel;
          home-vino = self.homeConfigurations."${username}@${primaryHost}".activationPackage;
        };

        devshells = {
          maintenance = {
            packages = maintenanceDevPackages;
            devshell = {
              motd = cfgLib.mkDevshellMotd {
                title = "Maintenance Shell";
                description = ''
                  Type ',' to see all available commands
                  Quick actions: fmt, qa, update, clean, sysinfo

                  Bash users: source $MISSION_CONTROL_COMPLETIONS/share/bash-completion/completions/,
                '';
              };
              startup = devshellStartup;
            };
          };

          default = {
            packages = maintenanceDevPackages;
            devshell = {
              motd = cfgLib.mkDevshellMotd {
                title = "Development Shell";
                description = ''
                  Type ',' to see all available commands
                  Services: nix run .#services (postgres, redis)
                  Quick shells: devweb, devrust, devgo, devflask

                  Bash users: source $MISSION_CONTROL_COMPLETIONS/share/bash-completion/completions/,
                '';
              };
              startup = devshellStartup;
            };
          };

          flask = {
            packages =
              commonDevPackages
              ++ (with pkgs; [
                python3
                python3Packages.flask
                python3Packages.requests
                python3Packages.virtualenv
                python3Packages.pip
                poetry
              ]);
            devshell.motd = cfgLib.mkDevshellMotd {
              title = "Flask Development Shell";
              emoji = "🐍";
              description = "Python: ${pkgs.python3.version}";
            };
          };

          web = {
            packages =
              commonDevPackages
              ++ (with pkgs; [
                nodejs # Includes npm by default
                pnpm # Standalone, no nodejs conflict
                yarn # Standalone, no nodejs conflict
                nodePackages.typescript
                nodePackages.typescript-language-server
              ]);
            devshell.motd = cfgLib.mkDevshellMotd {
              title = "Web Development Shell";
              emoji = "🌐";
              description = ''
                Node: ${pkgs.nodejs.version}
                npm, pnpm, yarn, TypeScript available
              '';
            };
          };

          agents = {
            packages =
              commonDevPackages
              ++ [
                opencodePkg
              ]
              ++ (with pkgs; [
                nodejs
                pnpm
                bun
              ]);
            devshell.motd = cfgLib.mkDevshellMotd {
              title = "Agent Tools Shell";
              emoji = "🤖";
              description = ''
                opencode + vercel CLI
                oh-my-opencode: bunx oh-my-opencode install
                agent-browser: npx @vercel/agent-browser
                If Playwright browsers missing: npx playwright install
              '';
            };
          };

          rust = {
            packages =
              commonDevPackages
              ++ (with pkgs; [
                rustc
                cargo
                rustfmt
                clippy
                rust-analyzer
                cargo-watch
                cargo-edit
              ]);
            devshell.motd = cfgLib.mkDevshellMotd {
              title = "Rust Development Shell";
              emoji = "🦀";
              description = "Rustc: ${pkgs.rustc.version}";
            };
          };

          go = {
            packages =
              commonDevPackages
              ++ (with pkgs; [
                go
                gopls # Go language server
                delve # Go debugger
                go-tools # staticcheck, etc.
                gotools # goimports, etc.
                gomodifytags
                impl
                gotests
              ]);
            devshell.motd = cfgLib.mkDevshellMotd {
              title = "Go Development Shell";
              emoji = "🐹";
              description = ''
                Go: ${pkgs.go.version}
                gopls, delve, staticcheck available
              '';
            };
          };

          pentest = {
            packages =
              commonDevPackages
              ++ (with pkgs; [
                nmap
                wireshark
                tcpdump
                netcat
                socat
                sqlmap
                john
                hashcat
                metasploit
                burpsuite
                nikto
                dirb
                gobuster
                ffuf
                hydra
              ]);
            devshell.motd = cfgLib.mkDevshellMotd {
              title = "Penetration Testing Shell";
              emoji = "🔐";
              description = ''
                Security testing tools available
                nmap, wireshark, metasploit, burpsuite, etc.
              '';
            };
          };

          database = {
            packages =
              commonDevPackages
              ++ (with pkgs; [
                # Database servers
                postgresql
                mysql80
                sqlite
                redis
                mongodb-tools
                pgcli
                mycli
                litecli
                mongosh
                dbeaver-bin
              ]);
            devshell.motd = cfgLib.mkDevshellMotd {
              title = "Database Development Shell";
              emoji = "🗄️";
              description = ''
                Database clients and tools available
                PostgreSQL, MySQL 8.0, SQLite, Redis, MongoDB
              '';
            };
          };

          nix-debug = {
            packages =
              commonDevPackages
              ++ (with pkgs; [
                # Interactive Nix tools
                nix-tree # Visual dependency tree explorer (nix-tree /run/current-system)
                nix-diff # Compare derivations (nix-diff drv1.drv drv2.drv)
                nix-output-monitor # Better build output (nom build ...)
                nix-eval-jobs # Parallel evaluation
                # Documentation and exploration
                manix # Search Nix documentation (manix <term>)
                nurl # Generate Nix fetcher calls from URLs
                nix-prefetch-git # Prefetch git repositories
                nix-prefetch-github # Prefetch GitHub repositories
                # Analysis tools
                nixpkgs-review # Review nixpkgs PRs
                nixfmt
                nixd # Nix language server
              ]);
            devshell.motd = cfgLib.mkDevshellMotd {
              title = "Nix Debugging & Analysis Shell";
              emoji = "🔍";
              description = ''
                Interactive Nix exploration and debugging tools:
                • nix repl         - Interactive Nix REPL (:lf . to load flake)
                • nix-tree         - Visual dependency explorer
                • nix-diff         - Compare derivations
                • nom              - Better build output (nom build ...)
                • manix            - Search Nix documentation
                • nurl             - Generate fetcher calls from URLs
                • nixpkgs-review   - Review nixpkgs PRs

                Try: nix repl → :lf . → outputs.nixosConfigurations
              '';
            };
          };
        };
      };

      flake = {
        inherit overlays;
      };
    });
}
