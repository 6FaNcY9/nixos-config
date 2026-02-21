#!/usr/bin/env bash
set -euo pipefail
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
cd "$repo_root"
treefmt --no-cache
statix check .
deadnix -f .
pre-commit run --all-files --config "$PRECOMMIT_CONFIG"
nix flake check --option warn-dirty false

git add -A

# IMPORTANT: --no-verify bypasses pre-commit hooks intentionally.
# QA checks already ran above; hooks would be redundant and slow.
# If you need hooks, run: git commit (without this app)
git commit --no-verify

rm -f result result-*
