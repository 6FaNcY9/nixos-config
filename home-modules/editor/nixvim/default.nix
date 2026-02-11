{...}: {
  imports = [
    ./options.nix
    ./autocmds.nix
    ./highlights.nix
    ./ui.nix
    ./plugins.nix
    ./keymaps
    ./extra-config.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
