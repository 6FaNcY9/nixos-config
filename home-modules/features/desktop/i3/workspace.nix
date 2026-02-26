# i3 workspace assignments - Assign applications to specific workspaces
# Uses mkWorkspaceName helper to format workspace names with icons
# assignRules maps workspace numbers to window criteria (class names)

{
  workspaces,
  cfgLib,
  ...
}:
let
  wsName = n: cfgLib.mkWorkspaceName (builtins.elemAt workspaces (n - 1));

  assignRules = [
    {
      ws = 1;
      criteria = [ { class = "firefox"; } ];
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
    {
      ws = 9;
      criteria = [ { class = "xfce4-settings-manager"; } ];
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
