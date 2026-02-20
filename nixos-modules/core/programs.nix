# Core: System programs
# Always enabled (no option)
{
  pkgs,
  repoRoot,
  ...
}:
{
  programs = {
    fish = {
      enable = true;

      # Keep vendor completions/functions, but disable vendor config snippets
      vendor = {
        completions.enable = true;
        functions.enable = true;
        config.enable = false; # fzf.fish provides bindings; avoids vendor fzf_key_bindings noise
      };
    };

    gnupg.agent = {
      enable = true;
      # Use GTK2 pinentry for GUI popup (works with i3 + XFCE)
      # pinentry-curses doesn't work in SSH/OpenCode terminal
      # Alternative options: pinentry-gnome3, pinentry-qt, pinentry-rofi
      pinentryPackage = pkgs.pinentry-gtk2;
      enableSSHSupport = true;
    };

    # nh: friendly NixOS rebuild wrapper; `flake` tells it where to find this config
    # so `nh os switch` works without an explicit --flake path.
    nh = {
      enable = true;
      flake = repoRoot;
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };
    };

    # Command-not-found with nix-index (better than default)
    command-not-found.enable = false;
    nix-index = {
      enable = true;
      enableFishIntegration = true;
    };


    # Use prebuilt nix-index database (prevents 12GB evaluation)
    nix-index-database.comma.enable = true;

    # Allow running non‑Nix dynamic binaries (bunx/AppImage/vendor CLIs)
    nix-ld = {
      enable = true;
      libraries =
        let
          p = pkgs;
        in
        [
          # Default/core libs (NixOS wiki baseline)
          p.zlib
          p.zstd
          p.stdenv.cc.cc
          p.curl
          p.openssl
          p.attr
          p.libssh
          p.bzip2
          p.libxml2
          p.acl
          p.libsodium
          p.util-linux
          p.xz
          p.systemd

          # Common desktop/runtime additions
          p.glib
          p.gtk3
          p.libGL
          p.libva
          p.pipewire
          p.libx11
          p.libxext
          p.libxrandr
          p.libxrender
          p.libxcb
        ];
    };
  };
}
