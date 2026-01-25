# i3 workspace definitions - shared between NixOS and Home Manager
{lib, ...}: {
  options.workspaces = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Workspace name (shown in bar)";
        };
        icon = lib.mkOption {
          type = lib.types.str;
          description = "Workspace icon (for polybar/i3blocks)";
        };
      };
    });
    default = [
      {name = "1: "; icon = "";}
      {name = "2: "; icon = "";}
      {name = "3: "; icon = "";}
      {name = "4: "; icon = "";}
      {name = "5: "; icon = "";}
      {name = "6: "; icon = "";}
      {name = "7: "; icon = "";}
      {name = "8: "; icon = "";}
      {name = "9: "; icon = "";}
    ];
    description = "List of i3 workspace definitions with names and icons.";
  };
}
