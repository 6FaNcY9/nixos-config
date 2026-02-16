# Common devshell utilities exposed via _module.args for all perSystem modules.
# Usage: receive `common` in perSystem args, e.g. `perSystem = {common, ...}:`
{
  pkgsFor,
  repoRoot,
  ...
}: {
  perSystem = {
    system,
    config,
    lib,
    ...
  }: let
    pkgs = pkgsFor system;
    cfgLib = import ../lib {inherit lib;};

    opencodePkg = pkgs.opencode;
    baseMissionControlWrapper = config.mission-control.wrapper;
    # Make `,` usable from external project folders that use this flake shell via direnv.
    missionControlWrapper = pkgs.writeShellApplication {
      name = ",";
      text = ''
        set -euo pipefail

        find_flake_root() {
          local dir="$PWD"
          while true; do
            if [ -f "$dir/flake.nix" ]; then
              return 0
            fi
            if [ "$dir" = "/" ]; then
              return 1
            fi
            dir="''${dir%/*}"
            if [ -z "$dir" ]; then
              dir="/"
            fi
          done
        }

        # Support both ", --help" (native) and ", help" (common expectation).
        if [ "''${1-}" = "help" ]; then
          exec ${baseMissionControlWrapper}/bin/, --help
        fi

        # Preserve the caller's directory for CWD-sensitive commands
        # (e.g. `, db` stores data relative to the project, not the flake root).
        export ORIGINAL_PWD="$PWD"

        # mission-control resolves FLAKE_ROOT via flake-root; when outside any flake,
        # run commands from this repo root so scripts like ", services" still work.
        if ! find_flake_root; then
          cd ${repoRoot}
        fi

        exec ${baseMissionControlWrapper}/bin/, "$@"
      '';
    };
    maintenancePackages = [pkgs.pre-commit pkgs.nix missionControlWrapper] ++ config.pre-commit.settings.enabledPackages;

    # Common utilities for project devShells (CLI tools only, no flake management)
    commonDevPackages = with pkgs; [
      git
      gh
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
      statix
      deadnix
    ];

    # Mission-control wrapper + completions (added to all shells for universal `,` access)
    missionControlPackages = [missionControlWrapper config.packages.mission-control-completions];

    # Full flake tooling: pre-commit + nix + common + mission-control
    flakeToolsPackages = maintenancePackages ++ commonDevPackages ++ missionControlPackages;

    repoRootCmd = ''repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"'';

    # Shared startup configuration for devshells
    devshellStartup = {
      load-mission-control-completions.text = ''
        export MISSION_CONTROL_COMPLETIONS="${config.packages.mission-control-completions}"
        if [ -n "$BASH_VERSION" ] && [ -f "$MISSION_CONTROL_COMPLETIONS/share/bash-completion/completions/," ]; then
          source "$MISSION_CONTROL_COMPLETIONS/share/bash-completion/completions/,"
        fi
      '';
      show-devshell-info.text = ''
        if command -v git >/dev/null 2>&1; then
          REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
          if [ -n "$REPO_ROOT" ]; then
            BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
            DIRTY=$(git status --porcelain 2>/dev/null | wc -l)
            echo "  Repository: $(basename "$REPO_ROOT")"
            if [ "$DIRTY" -gt 0 ]; then
              echo "  Branch: $BRANCH (''${DIRTY} uncommitted changes)"
            else
              echo "  Branch: $BRANCH (clean)"
            fi
          fi
        fi
        if [ -n "''${DIRENV_DIR:-}" ]; then
          echo "  Direnv: active"
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
    _module.args.common = {
      inherit
        pkgs
        cfgLib
        commonDevPackages
        missionControlPackages
        flakeToolsPackages
        devshellStartup
        mkApp
        repoRootCmd
        opencodePkg
        ;
    };
  };
}
