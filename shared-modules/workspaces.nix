# i3 workspace definitions — number:icon mapping used by i3 and polybar.
#
# Provides 10 workspaces with Font Awesome 6 icons:
#   1:  (Firefox), 2:  (Window), 3:  (Code), 4:  (Folder), 5:  (Music),
#   6:  (Image), 7:  (Video), 8:  (Chat), 9:  (Settings), 10:  (File).
#
# Shared between NixOS and Home Manager via _module.args.
{ lib, ... }:
{
  options.workspaces = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
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
      }
    );
    default = [
      {
        number = 1;
        icon = ""; # fa-firefox (U+F269) - FA6 Brands
      }
      {
        number = 2;
        icon = ""; # fa-window-maximize (U+F2D0) - FA6 Solid
      }
      {
        number = 3;
        icon = ""; # fa-code (U+F121) - FA6 Solid
      }
      {
        number = 4;
        icon = ""; # fa-folder (U+F07C) - FA6 Solid
      }
      {
        number = 5;
        icon = ""; # fa-music (U+F001) - FA6 Solid
      }
      {
        number = 6;
        icon = ""; # fa-image (U+F03E) - FA6 Solid
      }
      {
        number = 7;
        icon = ""; # fa-video (U+F03D) - FA6 Solid
      }
      {
        number = 8;
        icon = ""; # fa-comments (U+F086) - FA6 Solid
      }
      {
        number = 9;
        icon = ""; # fa-gear (U+F013) - FA6 Solid
      }
      {
        number = 10;
        icon = ""; # fa-file (U+F15B) - FA6 Solid
      }
    ];
    description = "List of i3 workspace definitions with numbers and icons.";
  };
}
