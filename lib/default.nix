{lib}: {
  mkWorkspaceBindings = {
    mod,
    workspaces,
    commandPrefix,
    shift ? false,
  }: let
    indices = lib.range 1 (builtins.length workspaces);
    keyPrefix =
      if shift
      then "${mod}+Shift+"
      else "${mod}+";
  in
    builtins.listToAttrs (
      lib.lists.zipListsWith (wsName: idx: {
        name = "${keyPrefix}${builtins.toString idx}";
        value = "${commandPrefix} ${wsName}";
      })
      workspaces
      indices
    );
}
