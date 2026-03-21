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
          $directory$git_branch$git_status$rust$python$golang$nodejs$nix_shell$direnv$cmd_duration
          $character
        '';

        directory = {
          format = "[ 󰉋  $path ]($style)";
          style = "fg:${c.base05} bg:${c.base01} bold";
          truncation_length = 4;
          truncation_symbol = "…/";
        };

        git_branch = {
          format = "[  $branch ]($style)";
          style = "fg:${c.base0B} bg:${c.base01}";
        };

        git_status = {
          format = "([ $all_status$ahead_behind ]($style))";
          style = "fg:${c.base0A} bg:${c.base01}";
          # Show presence without counts for cleaner display
          staged = "+";
          modified = "!";
          untracked = "?";
          deleted = "✘";
          conflicted = "⚡";
          stashed = "≡";
          ahead = "⇡";
          behind = "⇣";
          diverged = "⇡⇣";
        };

        rust = {
          format = "[ 󱘗 $version ]($style)";
          style = "fg:${c.base08} bg:${c.base01}";
        };

        python = {
          format = "[  $version ]($style)";
          style = "fg:${c.base0A} bg:${c.base01}";
        };

        golang = {
          format = "[  $version ]($style)";
          style = "fg:${c.base0D} bg:${c.base01}";
        };

        nodejs = {
          format = "[  $version ]($style)";
          style = "fg:${c.base0B} bg:${c.base01}";
        };

        nix_shell = {
          format = "[  $state ]($style)";
          style = "fg:${c.base0D} bg:${c.base01}";
        };

        direnv = {
          disabled = false;
          format = "[  direnv ]($style)";
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
