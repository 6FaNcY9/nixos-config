# i3 workspace assignments - Assign applications to specific workspaces
# Uses mkWorkspaceName helper to format workspace names with icons
# assignRules maps workspace numbers to window criteria (class names)

{
  workspaces,
  cfgLib,
  lib,
  ...
}:
let
  wsName =
    n:
    cfgLib.mkWorkspaceName (
      lib.findFirst (ws: ws.number == n) (throw "workspace ${toString n} not found") workspaces
    );

  assignRules = [
    {
      ws = 1;
      criteria = [
        { class = "qutebrowser"; }
        { class = "firefox"; }
      ];
    }
    {
      ws = 2;
      criteria = [ { class = "Alacritty"; } ];
    }
    {
      ws = 3;
      criteria = [ { class = "Code"; } ];
    }
    {
      ws = 4;
      criteria = [ { class = "Thunar"; } ];
    }
    {
      ws = 5;
      criteria = [ { class = "Spotify"; } ];
    }
    {
      ws = 6;
      criteria = [ { class = "feh"; } ];
    }
    {
      ws = 8;
      criteria = [ { class = "discord"; } ];
    }
  ];
in
{
  xsession.windowManager.i3.config.assigns = builtins.listToAttrs (
    map (r: {
      name = wsName r.ws;
      value = r.criteria;
    }) assignRules
  );
}
