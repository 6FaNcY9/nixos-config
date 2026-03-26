# Bitwarden CLI + qutebrowser integration
# Provides bw CLI, pinentry-rofi for master password prompt, and keyutils for session key caching.
# Symlinks the bundled qute-bitwarden userscript into qutebrowser's search path.
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.features.desktop.bitwarden;
in
{
  options.features.desktop.bitwarden.enable =
    lib.mkEnableOption "Bitwarden CLI + qutebrowser integration";

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.bitwarden-cli # Official Bitwarden CLI (bw) — used by qute-bitwarden userscript
      pkgs.pinentry-rofi # Pinentry frontend for bw master password prompt
      pkgs.keyutils # keyctl — used by qute-bitwarden to cache the bw session key
    ];

    # Symlink bundled qute-bitwarden into qutebrowser's userscripts search path.
    # The nix store path is not searched by default; symlinking makes it available to
    # `spawn --userscript qute-bitwarden`. Requires bitwarden-cli (bw) to be installed.
    home.file.".local/share/qutebrowser/userscripts/qute-bitwarden".source =
      "${pkgs.qutebrowser}/share/qutebrowser/userscripts/qute-bitwarden";
  };
}
