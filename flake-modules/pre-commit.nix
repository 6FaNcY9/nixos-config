{pkgsFor, ...}: {
  perSystem = {
    system,
    config,
    ...
  }: let
    pkgs = pkgsFor system;
  in {
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
  };
}
