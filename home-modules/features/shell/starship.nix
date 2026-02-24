# Starship prompt configuration
{
  lib,
  config,
  c,
  ...
}:
let
  cfg = config.features.shell.starship;
in
{
  options.features.shell.starship = {
    enable = lib.mkEnableOption "starship prompt";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;

      settings = {
        add_newline = false;

        format = ''
          $directory$git_branch$git_status$nix_shell$direnv$cmd_duration
          $character
        '';

        directory = {
          format = "[ 󰉋  $path ]($style)";
          style = "fg:${c.base05} bg:${c.base01}";
          truncation_length = 4;
          truncation_symbol = "…/";
        };

        git_branch = {
          format = "[  $branch ]($style)";
          style = "fg:${c.base0B} bg:${c.base01}";
        };

        git_status = {
          # Hide module entirely when there is no status to show
          format = "([ $all_status$ahead_behind ]($style))";
          style = "fg:${c.base0A} bg:${c.base01}";
        };

        nix_shell = {
          format = "[  $state ]($style)";
          style = "fg:${c.base0D} bg:${c.base01}";
        };

        direnv = {
          disabled = false;
          format = "[ direnv ]($style)";
          style = "fg:${c.base08} bg:${c.base01}";
        };

        cmd_duration = {
          format = "[  $duration ]($style)";
          style = "fg:${c.base0E} bg:${c.base01}";
          min_time = 500;
        };

        character = {
          success_symbol = " [](fg:${c.base0B})";
          error_symbol = " [](fg:${c.base08})";
          vimcmd_symbol = " [](fg:${c.base0A})";
        };
      };
    };
  };
}
