#!/usr/bin/env bash
# XDG Base Directory Migration Script
# Moves package manager data to XDG-compliant locations
# Run AFTER: nh home switch -c vino@bandit

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# XDG directories (use defaults if not set)
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }

dry_run=false
if [[ ${1:-} == "--dry-run" ]]; then
	dry_run=true
	warn "DRY RUN MODE - No changes will be made"
fi

echo ""
echo "========================================"
echo "  XDG Base Directory Migration Script"
echo "========================================"
echo ""

# Ensure target directories exist
ensure_dir() {
	if [[ $dry_run == false ]]; then
		mkdir -p "$1"
	fi
}

# Move directory if source exists and target doesn't
migrate_dir() {
	local src="$1"
	local dst="$2"
	local name="$3"

	if [[ -d $src ]]; then
		if [[ -d $dst && "$(ls -A "$dst" 2>/dev/null)" ]]; then
			warn "$name: Target exists and not empty, merging..."
			if [[ $dry_run == false ]]; then
				cp -rn "$src"/* "$dst"/ 2>/dev/null || true
				rm -rf "$src"
			else
				echo "  Would merge: $src -> $dst"
			fi
		elif [[ ! -e $dst ]]; then
			log "$name: Moving $src -> $dst"
			if [[ $dry_run == false ]]; then
				ensure_dir "$(dirname "$dst")"
				mv "$src" "$dst"
			fi
			success "$name migrated"
		else
			warn "$name: Target exists, skipping"
		fi
	else
		log "$name: Source doesn't exist, skipping"
	fi
}

# Move file with directory creation
migrate_file() {
	local src="$1"
	local dst="$2"
	local name="$3"

	if [[ -f $src ]]; then
		if [[ -f $dst ]]; then
			warn "$name: Target exists, skipping"
		else
			log "$name: Moving $src -> $dst"
			if [[ $dry_run == false ]]; then
				ensure_dir "$(dirname "$dst")"
				mv "$src" "$dst"
			fi
			success "$name migrated"
		fi
	fi
}

# Delete file/directory
cleanup() {
	local path="$1"
	local name="$2"

	if [[ -e $path ]]; then
		log "$name: Removing $path"
		if [[ $dry_run == false ]]; then
			rm -rf "$path"
		fi
		success "$name cleaned"
	fi
}

echo "Step 1: Package Manager Migrations"
echo "-----------------------------------"

# NPM - Move cache
migrate_dir "$HOME/.npm" "$XDG_CACHE_HOME/npm" "npm"

# Cargo - Move entire directory (contains bin/, registry/, etc)
migrate_dir "$HOME/.cargo" "$XDG_DATA_HOME/cargo" "cargo"

# Rustup - Move toolchains
migrate_dir "$HOME/.rustup" "$XDG_DATA_HOME/rustup" "rustup"

# Go - Move GOPATH
migrate_dir "$HOME/go" "$XDG_DATA_HOME/go" "go"

# Yarn - Delete old locations (env vars handle new location)
cleanup "$HOME/.yarn" "yarn cache"
cleanup "$HOME/.yarnrc" "yarn config"

# Bun - Move if exists in wrong location
migrate_dir "$HOME/.bun" "$XDG_DATA_HOME/bun" "bun"

# Themes - Move to XDG data
migrate_dir "$HOME/.themes" "$XDG_DATA_HOME/themes" "themes"

echo ""
echo "Step 2: History File Migrations"
echo "--------------------------------"

# Bash history
ensure_dir "$XDG_STATE_HOME/bash"
migrate_file "$HOME/.bash_history" "$XDG_STATE_HOME/bash/history" "bash history"

# Python history
ensure_dir "$XDG_STATE_HOME/python"
migrate_file "$HOME/.python_history" "$XDG_STATE_HOME/python/history" "python history"

echo ""
echo "Step 3: X11/Compose Cache"
echo "-------------------------"

# Compose cache
ensure_dir "$XDG_CACHE_HOME/X11"
migrate_dir "$HOME/.compose-cache" "$XDG_CACHE_HOME/X11/xcompose" "compose cache"

echo ""
echo "Step 4: Cleanup Garbage Files"
echo "-----------------------------"

# Claude backup files
for f in "$HOME"/.claude.json.backup.*; do
	[[ -e $f ]] && cleanup "$f" "claude backup"
done

# Stray log/debug files
cleanup "$HOME/flameshot.strace" "flameshot strace"
cleanup "$HOME/playwright-mcp-server.log" "playwright log"

# X session errors (regenerated on login)
cleanup "$HOME/.xsession-errors" "xsession-errors"
cleanup "$HOME/.xsession-errors.old" "xsession-errors.old"

# ICEauthority (regenerated)
cleanup "$HOME/.ICEauthority" "ICEauthority"

echo ""
echo "Step 5: Dotnet (if exists)"
echo "--------------------------"
migrate_dir "$HOME/.dotnet" "$XDG_DATA_HOME/dotnet" "dotnet"

echo ""
echo "========================================"
echo "  Migration Complete!"
echo "========================================"
echo ""
echo "Note: The following cannot be moved automatically:"
echo "  - ~/.mozilla (Firefox 147 will add XDG support)"
echo "  - ~/.vscode (VS Code doesn't support XDG)"
echo "  - ~/.gnupg (requires careful reconfiguration)"
echo "  - ~/.ssh (must stay for security)"
echo ""
echo "Add these to shell config for full XDG compliance:"
# shellcheck disable=SC2016
echo '  export HISTFILE="$XDG_STATE_HOME/bash/history"'
echo ""
if [[ $dry_run == true ]]; then
	warn "This was a dry run. Run without --dry-run to apply changes."
fi
