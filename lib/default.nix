_: let
  mkWorkspaceName = ws: let
    number = builtins.toString ws.number;
    icon = ws.icon or "";
  in
    if icon == ""
    then number
    else "${number}:${icon}";
in {
  inherit mkWorkspaceName;

  mkWorkspaceBindings = {
    mod,
    workspaces,
    commandPrefix,
    shift ? false,
  }: let
    keyPrefix =
      if shift
      then "${mod}+Shift+"
      else "${mod}+";
  in
    builtins.listToAttrs (
      map (ws: {
        name = "${keyPrefix}${builtins.toString ws.number}";
        value = "${commandPrefix} \"${mkWorkspaceName ws}\"";
      })
      workspaces
    );
}
