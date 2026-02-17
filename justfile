# NixOS Config — task runner (replaces mission-control)
# Run `just` to see all available recipes.

host := "bandit"
user := "vino"

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

