# Shell: bat — modern cat replacement with syntax highlighting
#
# Configures programs.bat for consistent output style.
# Theme is applied via stylix.targets.bat (enabled in vino/default.nix).
# Package is also present in profiles.core for basic use without HM config.
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.shell.bat;
in
{
  options.features.shell.bat.enable =
    lib.mkEnableOption "bat — cat replacement with syntax highlighting";

  config = lib.mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config = {
        style = "numbers,changes,header-filename,header-filesize";
        italic-text = "always";
      };
    };
  };
}
