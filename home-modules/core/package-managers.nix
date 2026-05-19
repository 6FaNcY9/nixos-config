# Package manager and tool XDG configuration
# Centralizes paths to follow XDG Base Directory spec
# Prevents home directory bloat from npm, yarn, cargo, go, etc.
{ config, ... }:
{
  home.sessionVariables = {
    # ──────────────────────────────────────────────────────────────
    # Shell history (bash fallback)
    # ──────────────────────────────────────────────────────────────
    HISTFILE = "${config.xdg.stateHome}/bash/history";

    # ──────────────────────────────────────────────────────────────
    # NPM / Node.js
    # ──────────────────────────────────────────────────────────────
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
    NPM_CONFIG_PREFIX = "${config.xdg.dataHome}/npm";
    NPM_CONFIG_LOGS_DIR = "${config.xdg.stateHome}/npm/logs";
    NPM_CONFIG_UPDATE_NOTIFIER = "false"; # Prevents ~/.npm/_update-notifier-last-checked

    # ──────────────────────────────────────────────────────────────
    # Yarn
    # ──────────────────────────────────────────────────────────────
    YARN_CACHE_FOLDER = "${config.xdg.cacheHome}/yarn";
    YARN_GLOBAL_FOLDER = "${config.xdg.dataHome}/yarn";

    # ──────────────────────────────────────────────────────────────
    # pnpm
    # ──────────────────────────────────────────────────────────────
    PNPM_HOME = "${config.xdg.dataHome}/pnpm";

    # ──────────────────────────────────────────────────────────────
    # Bun
    # ──────────────────────────────────────────────────────────────
    BUN_INSTALL = "${config.xdg.dataHome}/bun";
    BUN_INSTALL_CACHE_DIR = "${config.xdg.cacheHome}/bun";

    # ──────────────────────────────────────────────────────────────
    # Cargo / Rust
    # ──────────────────────────────────────────────────────────────
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";

    # ──────────────────────────────────────────────────────────────
    # Go
    # ──────────────────────────────────────────────────────────────
    GOPATH = "${config.xdg.dataHome}/go";
    GOMODCACHE = "${config.xdg.cacheHome}/go/mod";
    GOCACHE = "${config.xdg.cacheHome}/go/build";

    # ──────────────────────────────────────────────────────────────
    # Python
    # ──────────────────────────────────────────────────────────────
    PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
    PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python";
    PYTHONUSERBASE = "${config.xdg.dataHome}/python";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
    UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";

    # ──────────────────────────────────────────────────────────────
    # X11 / Display
    # ──────────────────────────────────────────────────────────────
    XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
    ICEAUTHORITY = "${config.xdg.cacheHome}/ICEauthority";

    # ──────────────────────────────────────────────────────────────
    # Containers
    # ──────────────────────────────────────────────────────────────
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
  };

  # Add package manager bin directories to PATH
  home.sessionPath = [
    "${config.xdg.dataHome}/npm/bin" # npm global binaries
    "${config.xdg.dataHome}/yarn/bin" # yarn global binaries
    "${config.xdg.dataHome}/pnpm" # pnpm global binaries
    "${config.xdg.dataHome}/bun/bin" # bun binaries
    "${config.xdg.dataHome}/cargo/bin" # cargo binaries
    "${config.xdg.dataHome}/go/bin" # go binaries
    "${config.xdg.dataHome}/python/bin" # pip --user binaries
  ];
}
