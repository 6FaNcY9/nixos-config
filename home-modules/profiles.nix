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
  codexPkg ? null,
  opencodePkg ? null,
  ...
}: let
  cfg = config.profiles;

  mkProfile = name: default:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      description = "Enable ${name} package set.";
    };

  claudeCodePkg = let
    unstablePkg = lib.attrByPath ["unstable" "claude-code"] null pkgs;
  in
    if unstablePkg != null
    then unstablePkg
    else lib.attrByPath ["claude-code"] null pkgs;

  corePkgs = with pkgs; [
    delta
    direnv # Auto-load/unload environments per directory
    lazygit
    gh
    eza
    tree
    nix-tree
    ripgrep
    fd
    fzf
    jq
    bat
    broot
    gdu
    zoxide
    tmux
    zellij
    procs
    hexyl
    yq-go
    unzip
    zip
    man-pages
    man-pages-posix
    nh
    nix-output-monitor
    nvd
  ];

  devPkgs = with pkgs; [
    python3
    clang
    gnumake
    pkg-config
    nodejs
    rustc
    cargo
    rustfmt
    clippy
    uv
    devenv
  ];

  desktopPkgs = with pkgs; [
    alacritty
    rofi
    thunar # Moved to top-level in unstable
    networkmanagerapplet
    blueman
    btop
    brightnessctl
    dunst
    flameshot
    picom
    playerctl
    polkit_gnome
    feh
    killall
    xclip
    gsimplecal
  ];

  extrasPkgs = with pkgs; [
    chafa
    neofetch
  ];
in {
  options.profiles = {
    core = mkProfile "core CLI tools" true;
    dev = mkProfile "development tools" true; # Default true for typical dev machine
    desktop = mkProfile "desktop apps" true; # Default true for typical desktop
    extras = mkProfile "nice-to-have extras" false;
    ai = mkProfile "AI tools" false;
  };

  config.home.packages = lib.concatLists [
    (lib.optionals cfg.core corePkgs)
    (lib.optionals cfg.dev devPkgs)
    (lib.optionals cfg.desktop desktopPkgs)
    (lib.optionals cfg.extras extrasPkgs)
    (lib.optionals (cfg.ai && claudeCodePkg != null) [claudeCodePkg])
    (lib.optionals (cfg.ai && codexPkg != null) [codexPkg])
    (lib.optionals (cfg.ai && opencodePkg != null) [opencodePkg])
  ];
}
