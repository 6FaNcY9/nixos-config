# Package profiles - Opt-in collections of packages organized by purpose
#
# Profiles allow granular control over installed packages without cluttering
# the main configuration. Enable/disable entire categories as needed.
#
# Available profiles:
#   - core: Essential CLI tools (always enabled)
#   - dev: Development tools and programming languages
#   - desktop: GUI applications for desktop use
#   - extras: Nice-to-have utilities and tools
#   - ai: AI/LLM tools (Codex, OpenCode)
#
# Usage: Set `profiles.<name> = true` in home configuration
{
  lib,
  pkgs,
  config,
  cfgLib,
  codexPkg ? null,
  opencodePkg ? null,
  ...
}:
let
  cfg = config.profiles;

  claudeCodePkg =
    let
      unstablePkg = lib.attrByPath [ "unstable" "claude-code" ] null pkgs;
    in
    if unstablePkg != null then unstablePkg else lib.attrByPath [ "claude-code" ] null pkgs;

  aiPkgs = lib.filter (p: p != null) [
    claudeCodePkg
    codexPkg
    opencodePkg
  ];

  corePkgs = [
    # VCS + GitHub
    pkgs.lazygit
    pkgs.gh
    # Search + file traversal
    pkgs.ripgrep
    pkgs.fd
    pkgs.eza
    pkgs.tree
    # Nix tooling
    pkgs.nix-tree
    pkgs.nix-output-monitor
    pkgs.nvd
    pkgs.nh
    # Data wrangling
    pkgs.jq
    pkgs.yq-go
    pkgs.bat
    pkgs.hexyl
    # Disk usage
    pkgs.gdu
    pkgs.dust # Intuitive du replacement with tree view
    pkgs.duf # Modern df replacement
    # TUI utilities
    pkgs.broot
    pkgs.zellij
    pkgs.procs
    # Archives
    pkgs.unzip
    pkgs.zip
    # Man pages
    pkgs.man-pages
    pkgs.man-pages-posix
    # Quick reference
    pkgs.tealdeer # Fast tldr client
  ];

  devPkgs = [
    pkgs.sqlite
    pkgs.python3
    pkgs.clang
    # gnumake and pkg-config are in nixos-modules/features/development/base.nix (system-level)
    pkgs.nodejs
    pkgs.github-copilot-cli
    pkgs.rustc
    pkgs.cargo
    pkgs.rustfmt
    pkgs.clippy
    pkgs.uv
    pkgs.devenv
    pkgs.tree-sitter-cli # v0.26.5 CLI tool (separate from tree-sitter library for neovim)
  ];

  desktopPkgs = [
    pkgs.alacritty
    pkgs.autotiling
    pkgs.rofi
    pkgs.thunar # Moved to top-level in unstable
    # applets managed by HM services (services.network-manager-applet, services.blueman-applet)
    pkgs.btop
    pkgs.brightnessctl
    pkgs.dunst
    pkgs.flameshot
    pkgs.picom
    pkgs.playerctl
    pkgs.polkit_gnome
    pkgs.feh
    pkgs.killall
    pkgs.xclip
    pkgs.gsimplecal
  ];

  extrasPkgs = [
    pkgs.chafa
    pkgs.fastfetch # neofetch replacement (actively maintained)
  ];
in
{
  options.profiles = {
    core = cfgLib.mkProfile "core CLI tools" true;
    dev = cfgLib.mkProfile "development tools" true;
    desktop = cfgLib.mkProfile "desktop apps" true;
    extras = cfgLib.mkProfile "nice-to-have extras" false;
    ai = cfgLib.mkProfile "AI tools" false;
  };

  config.home.packages = lib.concatLists [
    (lib.optionals cfg.core corePkgs)
    (lib.optionals cfg.dev devPkgs)
    (lib.optionals cfg.desktop desktopPkgs)
    (lib.optionals cfg.extras extrasPkgs)
    (lib.optionals cfg.ai aiPkgs)
  ];
}
