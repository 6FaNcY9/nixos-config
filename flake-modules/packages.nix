# Custom packages exported via flake outputs.
{
  perSystem =
    { pkgs, inputs', ... }:
    {
      packages = {
        # Helper for extracting the wallpaper store path (used by scripts).
        gruvboxWallpaperOutPath = pkgs.writeText "gruvbox-wallpaper-path" (
          builtins.toString inputs'.gruvbox-wallpaper.packages.default
        );
      };
    };
}
