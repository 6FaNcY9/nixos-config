#!/usr/bin/env bash
set -euo pipefail

# Simple non-interactive bootstrap for new forks / contributors.
# - Verifies nix is installed and flakes enabled
# - Runs `nix flake check`
# - Prints next steps for switching or applying the configuration

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Repository root: ${repo_root}"

command -v nix >/dev/null 2>&1 || {
  echo "nix command not found. Install Nix first." >&2
  echo "See: https://nixos.org/download.html" >&2
  echo "Example (non-interactive): curl -L https://nixos.org/nix/install | sh" >&2
  exit 2
}

# Check flakes support
if ! nix show-config | grep -q "experimental-features = .*flakes"; then
  echo "Nix flakes does not appear to be enabled for this user." >&2
  echo "Enable flakes by setting experimental-features = [ \"nix-command\" \"flakes\" ]" >&2
  echo "For Nix < 2.4 you may need to set environment variables; see Nix docs." >&2
  # continue, because some users may have system-level flakes enabled
fi

echo "Running: nix flake check --print-build-logs"
pushd "${repo_root}" >/dev/null
nix flake check --print-build-logs
check_exit=$?
popd >/dev/null

if [ ${check_exit} -ne 0 ]; then
  echo "Some flake checks failed (exit=${check_exit}). Fix issues before applying." >&2
else
  echo "Flake checks passed." >&2
fi

# Try to detect host for guidance
detected_host="${NIXOS_CONFIG_HOST:-$(hostname)}"
detected_user="${NIXOS_CONFIG_USER:-${USER:-unknown}}"

echo
echo "Next steps"
echo "----------"
echo "If you intend to switch a NixOS system using nh (nixos-hardware helper):"
echo "  nh os switch -H ${detected_host}"
echo
echo "Or using nixos-rebuild from this machine (if this is the target host):"
echo "  sudo nixos-rebuild switch --flake .#${detected_host}"
echo
echo "To apply Home Manager for your user:"
echo "  nh home switch -c ${detected_user}@${detected_host}"

exit ${check_exit}
