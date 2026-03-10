# Shell: eza — modern ls replacement with icons and git integration
#
# Fish shell abbrs (ll/ls/lt/lta) in fish.nix take precedence over
# enableFishIntegration — disabled here to avoid conflicts.
# Package is also present in profiles.core for basic use without HM config.
{
  lib,
  config,
  ...
}:
let
  cfg = config.features.shell.eza;
in
{
  options.features.shell.eza.enable =
    lib.mkEnableOption "eza — ls replacement with icons and git integration";

  config = lib.mkIf cfg.enable {
    programs.eza = {
      enable = true;
      icons = "auto";
      git = true;
      enableFishIntegration = false; # managed via fish.nix shellAbbrs (ll/ls/lt/lta)
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };
  };
}
