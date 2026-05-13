# Host-specific Home Manager configuration for: homelab (Intel i9 server)
#
# Headless server — desktop profile disabled, shell + editor + terminal retained.
# No battery/backlight/network-interface identifiers needed (server hardware).
_: {
  profiles = {
    # core and dev remain enabled (defaults in profiles.nix).
    desktop = false; # No GUI on headless server
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
      tmux.enable = true;
      # alacritty omitted — no display server
    };

    # No desktop features on headless host.
  };
}
