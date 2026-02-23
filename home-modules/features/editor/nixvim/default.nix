{ lib, config, ... }:
let
  cfg = config.features.editor.nixvim;
in
{
  options.features.editor.nixvim = {
    enable = lib.mkEnableOption "nixvim editor";
  };

  imports = [
    ./options.nix
    ./autocmds.nix
    ./highlights.nix
    ./ui.nix
    ./plugins.nix
    ./keymaps
    ./extra-config.nix
  ];

  config = lib.mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
    };
  };
}
