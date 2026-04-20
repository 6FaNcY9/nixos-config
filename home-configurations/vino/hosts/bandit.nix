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
    lanInterface = ""; # Set to ethernet interface name when docked (e.g., "enp3s0")
  };

  features = {
    shell = {
      git.enable = true;
      fish.enable = true;
      starship.enable = true;
      bat.enable = true;
      eza.enable = true;
    };
    editor.nixvim.enable = true;
    terminal = {
      alacritty.enable = true;
      tmux.enable = true;
      yazi.enable = true;
    };
    desktop = {
      # Home Manager keeps the user-layer pieces split out even though NixOS enables
      # the combined system feature `features.desktop.i3-xfce` for this host.
      services.enable = true;
      clipboard.enable = true;
      lock.enable = true;
      qutebrowser.enable = true;
      firefox.enable = true;
      xfce-session.enable = true;
      i3.enable = true;
      polybar.enable = true;
      rofi.enable = true;
      vibe.enable = true;
      filezilla.enable = true;
      bitwarden.enable = true;
    };
    ai.hermes.enable = true;
  };
  # Workspaces use shared defaults from shared-modules/workspaces.nix
  # Override here only if host-specific icons are needed
}
