# i3 workspace definitions - shared between NixOS and Home Manager
{lib, ...}: {
  options.workspaces = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        number = lib.mkOption {
          type = lib.types.int;
          description = "Workspace number (for i3 workspace name)";
        };
        icon = lib.mkOption {
          type = lib.types.str;
          description = "Workspace icon (for polybar display)";
        };
      };
    });
    default = [
      {
        number = 1;
        icon = "";
      }
      {
        number = 2;
        icon = "";
      }
      {
        number = 3;
        icon = "";
      }
      {
        number = 4;
        icon = "";
      }
      {
        number = 5;
        icon = "";
      }
      {
        number = 6;
        icon = "";
      }
      {
        number = 7;
        icon = "";
      }
      {
        number = 8;
        icon = "";
      }
      {
        number = 9;
        icon = "";
      }
      {
        number = 10;
        icon = "";
      }
    ];
    description = "List of i3 workspace definitions with numbers and icons.";
  };
}
