{
  pkgs,
  config,
  cfgLib,
  ...
}: let
  opencodePkg = pkgs.opencode;
  missionControlWrapper = config.mission-control.wrapper;
  maintenancePackages = [pkgs.pre-commit pkgs.nix missionControlWrapper] ++ config.pre-commit.settings.enabledPackages;

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
  inherit
    commonDevPackages
    maintenancePackages
    maintenanceDevPackages
    devshellStartup
    mkApp
    repoRootCmd
    opencodePkg
    cfgLib
    ;
}
