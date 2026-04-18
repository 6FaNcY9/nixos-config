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
}:
let
  cfg = config.profiles;

  claudeCodePkg =
    let
      unstablePkg = lib.attrByPath [ "unstable" "claude-code" ] null pkgs;
    in
    if unstablePkg != null then unstablePkg else lib.attrByPath [ "claude-code" ] null pkgs;

  githubCopilotPkg = lib.attrByPath [ "github-copilot-cli" ] null pkgs;

  vibePkg = lib.attrByPath [ "mistral-vibe" ] null pkgs;

  aiPkgs = lib.filter (p: p != null) [
    claudeCodePkg
    codexPkg
    opencodePkg
    githubCopilotPkg
    vibePkg
    pkgs.agentsys
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
    pkgs.filezilla
    pkgs.sqlite
    pkgs.python3
    pkgs.clang
    # gnumake and pkg-config are in nixos-modules/features/development/base.nix (system-level)
    pkgs.nodejs
    pkgs.rustc
    pkgs.cargo
    pkgs.rustfmt
    pkgs.clippy
    pkgs.uv
    pkgs.devenv
    pkgs.strip-json-comments-cli
    pkgs.tree-sitter-cli # v0.26.5 CLI tool (separate from tree-sitter library for neovim)
  ];

  desktopPkgs = [
    pkgs.alacritty
    pkgs.autotiling
    pkgs.rofi
    pkgs.thunar # Moved to top-level in unstable
    pkgs.thunar-archive-plugin
    pkgs.file-roller
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
    pkgs.copyq # Clipboard manager — persists clipboard content after source app closes
    pkgs.gsimplecal
    pkgs.chromium
  ];

  extrasPkgs = [
    pkgs.chafa
    pkgs.woeusb-ng
    pkgs.wimlib
    pkgs.fastfetch # neofetch replacement (actively maintained)
  ];
in
{
  options.profiles = {
    core = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable core CLI tools package set.";
    }; # Essential CLI: git, ripgrep, fd, eza, bat, jq, zellij, nix-tree, lazygit, etc.
    dev = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable development tools package set.";
    }; # Programming: sqlite, python3, clang, nodejs, rust, cargo, uv, devenv, tree-sitter
    desktop = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable desktop apps package set.";
    }; # GUI apps: alacritty, rofi, thunar, btop, dunst, flameshot, picom, etc.
    extras = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable nice-to-have extras package set.";
    }; # Extras: chafa, fastfetch
    ai = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AI tools package set.";
    }; # AI/LLM: claude-code, codex, opencode, github-copilot-cli
  };

  config.home.packages = lib.concatLists [
    (lib.optionals cfg.core corePkgs)
    (lib.optionals cfg.dev devPkgs)
    (lib.optionals cfg.desktop desktopPkgs)
    (lib.optionals cfg.extras extrasPkgs)
    (lib.optionals cfg.ai aiPkgs)
  ];
}
