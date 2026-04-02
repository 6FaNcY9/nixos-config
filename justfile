# NixOS Config — task runner (replaces mission-control)
# Run `just` to see all available recipes.

# Derive host and user from environment for portability. Falls back to hostname/USER.
# Use NIXOS_CONFIG_HOST / NIXOS_CONFIG_USER to override.
host := `sh -c 'printf "%s" "${NIXOS_CONFIG_HOST:-$(hostname)}"'`
user := `sh -c 'printf "%s" "${NIXOS_CONFIG_USER:-${USER}}"'`

# ── Dev Tools ────────────────────────────────────────────

# Format all Nix files
fmt:
    nix fmt

# Format, lint, and run flake checks
qa:
    nix run .#qa

# Update flake inputs
update:
    nix flake update

# Remove result symlinks
clean:
    rm -f result result-*

# ── Services ─────────────────────────────────────────────

# Open dev services TUI (PostgreSQL + Redis, start with F7)
services:
    nix run .#dev-services

# Start project-local PostgreSQL (data in ./data/pg1/)
db:
    nix run .#web-db

# ── Analysis ─────────────────────────────────────────────

# System diagnostics and configuration status
sysinfo:
    nix run .#sysinfo

# Visualize Nix dependency tree
tree:
    nix-tree

# ── Build / Deploy ───────────────────────────────────────

# Rebuild and switch NixOS (nh)
rebuild:
    nh os switch -H {{host}}

# Test rebuild without switching (nh)
rebuild-test:
    nh os test -H {{host}}

# Rebuild and switch Home Manager (nh)
home-switch:
    nh home switch -c {{user}}@{{host}}

# ── Dev Shells ───────────────────────────────────────────

# Enter web development shell
web:
    nix develop .#web

# Enter Rust development shell
rust:
    nix develop .#rust

# Enter Go development shell
go:
    nix develop .#go

# Enter AI agent tools shell
agents:
    nix develop .#agents

# Enter Nix debugging & analysis shell
nix-debug:
    nix develop .#nix-debug

# ── Utilities ────────────────────────────────────────────

# Generate Age key for sops-nix
generate-age-key:
    nix run .#generate-age-key

# Push current system build to Cachix
cachix-push:
  nix run .#cachix-push

# ── Git ────────────────────────────────────────────

# Commit all changes
commit:
  nix run .#commit

# Bootstrap local setup
# Runs the repository bootstrap script to verify prerequisites and run flake checks
bootstrap:
  bash ./scripts/bootstrap.sh

# ── Security ─────────────────────────────────────────────

# Scan home directory for viruses (moves infected files to /var/lib/clamav-quarantine)
scan-home:
    clamav-scan home

# Scan entire system for viruses (moves infected files to /var/lib/clamav-quarantine)
scan-system:
    clamav-scan system

# Scan a specific path: just scan ~/Downloads
scan PATH:
    clamav-scan '{{PATH}}'

# Toggle transparent Tor routing on/off
# Active state persists until toggled off or machine reboots (/run is tmpfs)
tor:
    #!/usr/bin/env bash
    if [ -f /run/tor-routing-active ]; then
      echo "Stopping Tor routing..."
      sudo systemctl stop nftables-tor-routing.service
      sudo rm -f /run/tor-routing-active
      echo "Done. Traffic is no longer routed through Tor."
    else
      echo "Starting Tor routing..."
      if sudo systemctl start nftables-tor-routing.service; then
        sudo touch /run/tor-routing-active
        echo "Done. All TCP and DNS traffic is now routed through Tor."
        echo "Polybar will show the Tor exit IP within 3 seconds."
      else
        echo "ERROR: Failed to start nftables-tor-routing.service. Routing not active." >&2
        exit 1
      fi
    fi
