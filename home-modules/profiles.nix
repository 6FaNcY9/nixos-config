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

  corePkgs =
    let
      p = pkgs;
    in
    [
      p.delta
      p.direnv # Auto-load/unload environments per directory
      p.lazygit
      p.gh
      p.eza
      p.tree
      p.nix-tree
      p.ripgrep
      p.fd
      p.fzf
      p.jq
      p.bat
      p.broot
      p.gdu
      p.zoxide
      p.tmux
      p.zellij
      p.procs
      p.hexyl
      p.yq-go
      p.unzip
      p.zip
      p.man-pages
      p.man-pages-posix
      p.nh
      p.nix-output-monitor
      p.nvd
    ];

  devPkgs =
    let
      p = pkgs;
    in
    [
      p.python3
      p.clang
      # gnumake and pkg-config are in nixos-modules/roles/development.nix (system-level)
      p.nodejs
      p.github-copilot-cli
      p.rustc
      p.cargo
      p.rustfmt
      p.clippy
      p.uv
      p.devenv
      p.tree-sitter-cli # v0.26.5 CLI tool (separate from tree-sitter library for neovim)
    ];

  desktopPkgs =
    let
      p = pkgs;
    in
    [
      p.alacritty
      p.autotiling
      p.rofi
      p.thunar # Moved to top-level in unstable
      p.networkmanagerapplet
      p.blueman
      p.btop
      p.brightnessctl
      p.dunst
      p.flameshot
      p.picom
      p.playerctl
      p.polkit_gnome
      p.feh
      p.killall
      p.xclip
      p.gsimplecal
    ];

  extrasPkgs =
    let
      p = pkgs;
    in
    [
      p.chafa
      p.fastfetch # neofetch replacement (actively maintained)
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
