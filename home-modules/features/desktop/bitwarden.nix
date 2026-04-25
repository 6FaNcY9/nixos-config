# Bitwarden integration
# Primary workflow: rbw daemon + rofi-rbw picker (Mod+p) for credential autotype.
# Web vault (Mod+Shift+b) for managing entries, TOTP, and sharing.
# bw CLI kept for scripting edge cases.
#
# First-time setup after home-switch:
#   rbw config set email <your@email.com>
#   rbw register   # sends verification email
#   rbw unlock     # starts the daemon and unlocks the vault
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.features.desktop.bitwarden;

  customMenu = pkgs.writeShellApplication {
    name = "rofi-bitwarden-menu";
    runtimeInputs = [
      pkgs.bitwarden-cli
      pkgs.jq
      pkgs.libnotify
      pkgs.rofi
      pkgs.xclip
    ];
    text = builtins.readFile ./bitwarden-menu.sh;
  };
in
{
  options.features.desktop.bitwarden.enable =
    lib.mkEnableOption "Bitwarden — rbw daemon + rofi-rbw picker + bw CLI";

  config = lib.mkIf cfg.enable {
    home.packages = [
      customMenu
      pkgs.bitwarden-cli # bw CLI — vault export, scripting, edge cases
      pkgs.rbw # rbw daemon — keeps vault unlocked, no session key juggling
      pkgs.rofi-rbw # rofi picker — autotypes credentials into focused window
      pkgs.pinentry-rofi # pinentry frontend for rbw master password prompt
      pkgs.xdotool # required by rofi-rbw for autotyping on X11
    ];

    xsession.windowManager.i3.config.keybindings =
      let
        mod = config.xsession.windowManager.i3.config.modifier;
      in
      lib.mkOptionDefault {
        "${mod}+Shift+p" = "exec ${customMenu}/bin/rofi-bitwarden-menu";
      };
  };
}
