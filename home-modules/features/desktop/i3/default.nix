{
  lib,
  i3Pkg,
  config,
  ...
}: {
  imports = [
    ./config.nix
    ./keybindings.nix
    ./autostart.nix
    ./workspace.nix
  ];

  config = lib.mkIf config.profiles.desktop {
    xsession = {
      enable = true;
      windowManager.i3 = {
        enable = true;
        package = i3Pkg;
      };
    };
  };
}
