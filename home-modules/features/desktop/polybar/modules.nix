{
  config,
  pkgs,
  lib,
  workspaces,
  hostname,
  cfgLib,
  ...
}:
let
  inherit (cfgLib) mkPolybarTwoTone mkPolybarTwoToneState;
  icons = import ./icons.nix { inherit cfgLib; };
  hasIcons = builtins.any (workspace: workspace.icon != "") workspaces;
  wsIconAttrs = lib.listToAttrs (
    map (workspace: {
      name = "ws-icon-${toString (workspace.number - 1)}";
      value = "${cfgLib.mkWorkspaceName workspace};${workspace.icon}";
    }) workspaces
  );
  hasBattery = config.devices.battery != "";
  hasNetwork = config.devices.networkInterface != "";
  hasLan = config.devices.lanInterface != "";

  coreModules = import ./core-modules.nix {
    inherit
      pkgs
      hasIcons
      wsIconAttrs
      hostname
      icons
      mkPolybarTwoTone
      ;
  };

  systemModules = import ./system-modules.nix {
    inherit
      config
      pkgs
      icons
      mkPolybarTwoTone
      mkPolybarTwoToneState
      ;
  };

  connectivityModules = import ./connectivity-modules.nix {
    inherit
      config
      pkgs
      lib
      hasBattery
      hasNetwork
      hasLan
      icons
      mkPolybarTwoToneState
      ;
  };
in
{
  services.polybar.settings = lib.mkMerge [
    coreModules
    systemModules
    connectivityModules
  ];
}
