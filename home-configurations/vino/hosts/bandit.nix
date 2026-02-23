_: {
  # core, dev, desktop are now true by default in profiles.nix
  profiles = {
    extras = true;
    ai = true;
  };

  devices = {
    battery = "BAT1";
    backlight = "amdgpu_bl1";
    networkInterface = "wlp1s0";
  };

  features.shell.git.enable = true;
  features.shell.fish.enable = true;
  features.shell.starship.enable = true;
  features.editor.nixvim.enable = true;
  features.terminal.alacritty.enable = true;


  # Workspaces use shared defaults from shared-modules/workspaces.nix
  # Override here only if host-specific icons are needed
}
