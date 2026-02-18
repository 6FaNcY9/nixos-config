# Apps are for `nix run .#<name>` from outside devshells (standalone, self-contained).
# For in-shell equivalents, use `just <recipe>` (see justfile).
{ primaryHost, ... }:
{
  perSystem =
    {
      pkgs,
      mkApp,
      config,
      ...
    }:
    let
      repoRootCmd = ''repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"'';
      qaBody = ''
        set -euo pipefail
        ${repoRootCmd}
        cd "$repo_root"
        treefmt --no-cache
        statix check .
        deadnix -f .
        pre-commit run --all-files --config ${config.pre-commit.settings.configFile}
        nix flake check --option warn-dirty false
      '';
    in
    {
      apps = {
        update = mkApp "update" [ pkgs.coreutils pkgs.git pkgs.nix ] "Update flake inputs" ''
          set -euo pipefail
          ${repoRootCmd}
          cd "$repo_root"
          nix flake update
        '';

        clean = mkApp "clean" [ pkgs.coreutils pkgs.git ] "Remove result symlinks" ''
          set -euo pipefail
          ${repoRootCmd}
          cd "$repo_root"
          rm -f result result-*
        '';

        qa = mkApp "qa" [
          pkgs.coreutils
          pkgs.deadnix
          pkgs.git
          pkgs.nix
          pkgs.pre-commit
          pkgs.statix
          config.treefmt.build.wrapper
        ] "Format, lint, and run flake checks" qaBody;

        commit =
          mkApp "commit"
            [
              pkgs.coreutils
              pkgs.deadnix
              pkgs.git
              pkgs.nix
              pkgs.pre-commit
              pkgs.statix
              config.treefmt.build.wrapper
            ]
            "Run QA, stage, and commit with editor"
            ''
              ${qaBody}

              git add -A

              # Use git commit with editor (like normal git workflow)
              # This properly handles multi-line messages
              git commit --no-verify

              rm -f result result-*
            '';

        generate-age-key =
          mkApp "generate-age-key"
            [
              pkgs.age
              pkgs.coreutils
            ]
            "Generate Age key for sops-nix encryption"
            ''
              set -euo pipefail

              KEY_DIR="$HOME/.config/sops/age"
              KEY_FILE="$KEY_DIR/keys.txt"

              echo "Age Key Generation for sops-nix"
              echo "=================================="
              echo ""

              # Check if key already exists
              if [ -f "$KEY_FILE" ]; then
                echo "Age key already exists at: $KEY_FILE"
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
                echo "Backed up existing key to: $BACKUP"
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
              echo "Age key generated successfully!"
              echo ""
              echo "Location: $KEY_FILE"
              echo ""
              echo "Your public key (add this to .sops.yaml):"
              echo "-------------------------------------------"
              grep "public key:" "$KEY_FILE"
              echo "-------------------------------------------"
              echo ""
              echo "Next steps:"
              echo "  1. Add the public key above to .sops.yaml"
              echo "  2. Run: sops updatekeys secrets/*.yaml"
              echo "  3. Commit the updated secrets"
              echo ""
            '';

        sysinfo =
          mkApp "sysinfo"
            [
              pkgs.coreutils
              pkgs.gnupg
              pkgs.git
              pkgs.nix
              pkgs.gnugrep
              pkgs.gawk
            ]
            "System diagnostics and configuration status"
            ''
              set -euo pipefail

              # Color codes for output
              RED='\033[0;31m'
              GREEN='\033[0;32m'
              YELLOW='\033[1;33m'
              BLUE='\033[0;34m'
              NC='\033[0m' # No Color

              echo "================================================"
              echo "   NixOS Configuration Diagnostics"
              echo "================================================"
              echo ""

              # ========================================
              # Hardware Device Detection
              # ========================================
              echo -e "''${BLUE}Hardware Devices''${NC}"
              echo "--------------------------------------------"

              # Battery detection
              if BAT_DEVICE=$(find /sys/class/power_supply -maxdepth 1 -name 'BAT*' -type l -printf '%f\n' 2>/dev/null | head -1); then
                if [ -n "$BAT_DEVICE" ]; then
                  echo -e "''${GREEN}OK''${NC} Battery: $BAT_DEVICE"
                else
                  echo -e "''${YELLOW}--''${NC} Battery: Not detected (desktop system?)"
                fi
              else
                echo -e "''${YELLOW}--''${NC} Battery: Not detected (desktop system?)"
              fi

              # Backlight detection
              if BACKLIGHT_DEVICE=$(find /sys/class/backlight -maxdepth 1 -mindepth 1 -type l -printf '%f\n' 2>/dev/null | head -1); then
                if [ -n "$BACKLIGHT_DEVICE" ]; then
                  echo -e "''${GREEN}OK''${NC} Backlight: $BACKLIGHT_DEVICE"
                else
                  echo -e "''${YELLOW}--''${NC} Backlight: Not detected (desktop system?)"
                fi
              else
                echo -e "''${YELLOW}--''${NC} Backlight: Not detected (desktop system?)"
              fi

              echo ""

              # ========================================
              # Secrets Management Status
              # ========================================
              echo -e "''${BLUE}Secrets Management''${NC}"
              echo "--------------------------------------------"

              # Age key check
              AGE_KEY="$HOME/.config/sops/age/keys.txt"
              if [ -f "$AGE_KEY" ]; then
                echo -e "''${GREEN}OK''${NC} Age key: Present ($AGE_KEY)"
                if AGE_PUB=$(grep "public key:" "$AGE_KEY" 2>/dev/null); then
                  echo "  Public: $(echo "$AGE_PUB" | awk '{print $NF}')"
                fi
              else
                echo -e "''${RED}MISSING''${NC} Age key: Missing"
                echo "  Run: nix run .#generate-age-key"
              fi

              # GPG key check
              GPG_KEY="FC8B68693AF4E0D9DC84A4D3B872E229ADE55151"
              if gpg --list-secret-keys "$GPG_KEY" >/dev/null 2>&1; then
                echo -e "''${GREEN}OK''${NC} GPG signing key: Imported ($GPG_KEY)"
              else
                echo -e "''${YELLOW}--''${NC} GPG signing key: Not imported"
                echo "  Key will auto-import on next home-manager activation"
              fi

              # Secrets directory check
              SECRETS_DIR="$HOME/.config/sops-nix/secrets"
              if [ -d "$SECRETS_DIR" ]; then
                SECRET_COUNT=$(find "$SECRETS_DIR" -type f -o -type l 2>/dev/null | wc -l)
                if [ "$SECRET_COUNT" -gt 0 ]; then
                  echo -e "''${GREEN}OK''${NC} Decrypted secrets: $SECRET_COUNT available"
                else
                  echo -e "''${YELLOW}--''${NC} Decrypted secrets: Directory exists but empty"
                fi
              else
                echo -e "''${YELLOW}--''${NC} Decrypted secrets: Not yet activated"
                echo "  Run: nh os switch"
              fi

              echo ""

              # ========================================
              # Git Repository Status
              # ========================================
              echo -e "''${BLUE}Repository Status''${NC}"
              echo "--------------------------------------------"

              ${repoRootCmd}
              cd "$repo_root"

              # Git status
              if git diff-index --quiet HEAD -- 2>/dev/null; then
                echo -e "''${GREEN}OK''${NC} Git status: Clean"
              else
                DIRTY_COUNT=$(git status --porcelain | wc -l)
                echo -e "''${YELLOW}--''${NC} Git status: $DIRTY_COUNT uncommitted changes"
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
              echo -e "''${BLUE}System Information''${NC}"
              echo "--------------------------------------------"

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
              echo -e "''${BLUE}Nix Store Status''${NC}"
              echo "--------------------------------------------"

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
              echo -e "''${BLUE}Quick Actions''${NC}"
              echo "--------------------------------------------"
              echo "  Update system: nh os switch"
              echo "  Update inputs: nix flake update"
              echo "  Run QA checks: nix run .#qa"
              echo "  Clean old gens: nh clean all --keep 5"
              echo "  Optimize store: sudo nix-store --optimise"
              echo ""
            '';

        cachix-push =
          mkApp "cachix-push"
            [
              pkgs.cachix
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.nix
            ]
            "Push current system build to Cachix"
            ''
              set -euo pipefail

              CACHE_NAME="vino-nixos-config"
              TOKEN_PATH="$HOME/.config/sops-nix/secrets/cachix_auth_token"

              echo "Cachix Push Utility"
              echo "======================"
              echo ""

              # Check if token exists
              if [ ! -f "$TOKEN_PATH" ]; then
                echo "ERROR: Cachix auth token not found at: $TOKEN_PATH"
                echo ""
                echo "Make sure secrets are activated:"
                echo "  nh home switch"
                exit 1
              fi

              # Export token for cachix
              CACHIX_AUTH_TOKEN=$(cat "$TOKEN_PATH")
              export CACHIX_AUTH_TOKEN

              echo "Building current system configuration..."
              SYSTEM_PATH=$(nix build --no-link --print-out-paths .#nixosConfigurations.${primaryHost}.config.system.build.toplevel 2>&1 | tail -1)

              if [ -z "$SYSTEM_PATH" ]; then
                echo "ERROR: Failed to build system"
                exit 1
              fi

              echo "Built: $SYSTEM_PATH"
              echo ""
              echo "Pushing to Cachix cache: $CACHE_NAME"
              echo ""

              # Push to cachix
              cachix push "$CACHE_NAME" "$SYSTEM_PATH"

              echo ""
              echo "Successfully pushed to $CACHE_NAME!"
              echo ""
              echo "Your cache URL: https://$CACHE_NAME.cachix.org"
            '';
      };
    };
}
