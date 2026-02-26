# NixVim Main Configuration
# Provides a complete Neovim setup with LSP, plugins, and modern UI
#
# Sub-modules:
#   options.nix       - Core vim options (leader key, tabs, scrolling, etc.)
#   autocmds.nix      - Auto-commands for behavior customization
#   highlights.nix    - Custom syntax highlighting overrides
#   ui.nix            - Status line, bufferline, notifications, dashboard
#   plugins.nix       - Plugin ecosystem (LSP, Treesitter, Telescope, etc.)
#   keymaps/          - Organized keybindings by category
#   extra-config.nix  - Additional plugins and Lua configuration

{ lib, config, ... }:
let
  cfg = config.features.editor.nixvim;
in
{
  options.features.editor.nixvim = {
    enable = lib.mkEnableOption "nixvim editor";
  };

  imports = [
    # Sub-module files for nixvim configuration
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
