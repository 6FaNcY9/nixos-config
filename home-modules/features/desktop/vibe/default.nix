# Vibe AI assistant devenv configuration
# Symlinks ~/.vibe/devenv.nix and ~/.vibe/devenv.yaml into the Home Manager store
# so they're tracked in nixos-config and not forgotten on fresh installs.
#
# The .vibe/ directory is where vibe expects its devenv shell (direnv + devenv).
# The wrapper in profiles.nix runs: direnv exec "$HOME/.vibe" vibe "$@"
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.desktop.vibe;
in
{
  options.features.desktop.vibe = {
    enable = lib.mkEnableOption "vibe AI assistant devenv configuration";
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".vibe/devenv.nix".source = ./devenv.nix;
      ".vibe/devenv.yaml".source = ./devenv.yaml;
    };
  };
}
