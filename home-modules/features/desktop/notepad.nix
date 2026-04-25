{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.features.desktop.notepad;
in
{
  options.features.desktop.notepad = {
    enable = lib.mkEnableOption "Joplin Desktop note-taking app";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.joplin-desktop ];
  };
}
