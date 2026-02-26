# Host-specific configuration for: bandit (Framework 13 AMD)
#
# Device identifiers:
#   battery         — BAT1 (Framework battery identifier)
#   backlight       — amdgpu_bl1 (AMD GPU backlight control)
#   networkInterface — wlp1s0 (WiFi interface)

_: {
  # core, dev, desktop are now true by default in profiles.nix
  profiles = {
    extras = true;
    ai = true;
  };

  # Hardware device identifiers for this host
  devices = {
    battery = "BAT1"; # Framework battery
    backlight = "amdgpu_bl1"; # AMD GPU backlight
    networkInterface = "wlp1s0"; # WiFi interface
  };

  features = {
    shell = {
      git.enable = true;
      fish.enable = true;
      starship.enable = true;
      vibe.enable = true;
    };
    editor.nixvim.enable = true;
    terminal = {
      alacritty.enable = true;
      tmux.enable = true;
      yazi.enable = true;
    };
    desktop = {
      services.enable = true;
      clipboard.enable = true;
      lock.enable = true;
      firefox.enable = true;
      xfce-session.enable = true;
      i3.enable = true;
      polybar.enable = true;
      rofi.enable = true;
    };
  };
  # Workspaces use shared defaults from shared-modules/workspaces.nix
  # Override here only if host-specific icons are needed
}
