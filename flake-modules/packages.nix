{
  inputs,
  pkgsFor,
  ...
}: {
  perSystem = {
    system,
    config,
    lib,
    ...
  }: let
    pkgs = pkgsFor system;
  in {
    # nix eval fix (wrap outPath as a derivation)
    packages = {
      gruvboxWallpaperOutPath = pkgs.writeText "gruvbox-wallpaper-outPath" inputs.gruvbox-wallpaper.outPath;

      # Shell completions for mission-control (,) command
      # Dynamically generated from config.mission-control.scripts
      mission-control-completions = let
        inherit (config.mission-control) scripts;
        scriptNames = builtins.attrNames scripts;
        # Generate fish completions
        fishCompletions =
          lib.concatMapStrings (name: ''
            complete -c ',' -f -a "${name}" -d "${scripts.${name}.description}"
          '')
          scriptNames;
        # Generate bash command list
        bashCommands = lib.concatStringsSep " " scriptNames;
      in
        pkgs.symlinkJoin {
          name = "mission-control-completions";
          paths = [
            # Fish completions
            (pkgs.writeTextFile {
              name = "mission-control-fish-completions";
              destination = "/share/fish/vendor_completions.d/mission-control.fish";
              text = ''
                # Fish shell completions for mission-control (,) command
                # Auto-generated from flake mission-control configuration
                ${fishCompletions}
              '';
            })
            # Bash completions
            (pkgs.writeTextFile {
              name = "mission-control-bash-completions";
              destination = "/share/bash-completion/completions/,";
              text = ''
                # Bash completion for mission-control (,) command
                # Auto-generated from flake mission-control configuration
                _mission_control_completion() {
                  local cur="''${COMP_WORDS[COMP_CWORD]}"
                  local commands="${bashCommands}"
                  COMPREPLY=($(compgen -W "$commands" -- "$cur"))
                }
                complete -F _mission_control_completion ','
              '';
            })
          ];
        };
    };
  };
}
