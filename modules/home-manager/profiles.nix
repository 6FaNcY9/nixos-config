{
  lib,
  pkgs,
  config,
  hmCli ? null,
  codexPkg ? null,
  ...
}: let
  cfg = config.profiles;

  mkProfile = name: default:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      description = "Enable ${name} package set.";
    };

  corePkgs = with pkgs; [
    git
    delta
    lazygit
    eza
    tree
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
    curl
    wget
    p7zip
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
    xfce.thunar
    networkmanagerapplet
    blueman
    btop
    brightnessctl
    dunst
    flameshot
    picom
    playerctl
    polkit_gnome
    pulseaudio
    vscode
    feh
    fontconfig
    killall
    xclip
    gsimplecal
    font-awesome
    nerd-fonts.jetbrains-mono
  ];

  extrasPkgs = with pkgs; [
    chafa
    neofetch
  ];
in {
  options.profiles = {
    core = mkProfile "core CLI tools" true;
    dev = mkProfile "development tools" false;
    desktop = mkProfile "desktop apps" false;
    extras = mkProfile "nice-to-have extras" false;
    ai = mkProfile "AI tools" false;
  };

  config.home.packages = lib.concatLists [
    (lib.optionals cfg.core (corePkgs ++ lib.optionals (hmCli != null) [hmCli]))
    (lib.optionals cfg.dev devPkgs)
    (lib.optionals cfg.desktop desktopPkgs)
    (lib.optionals cfg.extras extrasPkgs)
    (lib.optionals (cfg.ai && codexPkg != null) [codexPkg])
  ];
}
