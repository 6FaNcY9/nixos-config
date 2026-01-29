{
  lib,
  pkgs,
  config,
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

  claudeCodePkg = let
    unstablePkg = lib.attrByPath ["unstable" "claude-code"] null pkgs;
  in
    if unstablePkg != null
    then unstablePkg
    else lib.attrByPath ["claude-code"] null pkgs;

  opencodePkg = let
    unstablePkg = lib.attrByPath ["unstable" "opencode"] null pkgs;
  in
    if unstablePkg != null
    then unstablePkg
    else pkgs.opencode;

  corePkgs = with pkgs; [
    git
    delta
    lazygit
    gh
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
    firefox
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
    killall
    xclip
    gsimplecal
    font-awesome
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
    (lib.optionals cfg.core corePkgs)
    (lib.optionals cfg.dev devPkgs)
    (lib.optionals cfg.desktop desktopPkgs)
    (lib.optionals cfg.extras extrasPkgs)
    (lib.optionals (cfg.ai && claudeCodePkg != null) [claudeCodePkg])
    (lib.optionals (cfg.ai && codexPkg != null) [codexPkg])
    (lib.optionals cfg.ai [opencodePkg])
  ];
}
