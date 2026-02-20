set -euo pipefail
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
cd "$repo_root"
rm -f result result-*
