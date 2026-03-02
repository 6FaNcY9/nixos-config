#!/usr/bin/env bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
cd "$repo_root"
treefmt --no-cache
statix check .
deadnix .
pre-commit run --all-files --config "$PRECOMMIT_CONFIG"
nix flake check --option warn-dirty false
