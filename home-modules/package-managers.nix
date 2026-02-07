# Package manager and tool XDG configuration
# Centralizes paths to follow XDG Base Directory spec
# Prevents home directory bloat from npm, yarn, cargo, go, etc.
{config, ...}: {
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
    # .NET
    # ──────────────────────────────────────────────────────────────
    DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";
    NUGET_PACKAGES = "${config.xdg.cacheHome}/nuget";

    # ──────────────────────────────────────────────────────────────
    # X11 / Display
    # ──────────────────────────────────────────────────────────────
    XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
    ICEAUTHORITY = "${config.xdg.cacheHome}/ICEauthority";

    # ──────────────────────────────────────────────────────────────
    # Build tools
    # ──────────────────────────────────────────────────────────────
    GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";
    MAVEN_OPTS = "-Dmaven.repo.local=${config.xdg.cacheHome}/maven/repository";

    # ──────────────────────────────────────────────────────────────
    # Containers & Mobile
    # ──────────────────────────────────────────────────────────────
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    ANDROID_HOME = "${config.xdg.dataHome}/android";

    # ──────────────────────────────────────────────────────────────
    # GPU / CUDA
    # ──────────────────────────────────────────────────────────────
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
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
