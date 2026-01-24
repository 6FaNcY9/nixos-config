{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.roles.desktop && config.desktop.variant == "i3-xfce") {
    services = {
      gvfs.enable = true;
      udisks2.enable = true;

      displayManager.defaultSession = "xfce+i3";

      xserver = {
        enable = true;
        xkb.layout = "at";

        displayManager = {
          lightdm = {
            enable = true;
            greeters.gtk = {
              enable = true;
              indicators = [
                "~session"
                "~power"
                "~language"
                "~layout"
                "~a11y"
                "~clock"
                "~host"
              ];
            };
          };
        };

        desktopManager = {
          xterm.enable = false;
          xfce = {
            enable = true;
            noDesktop = true;
            enableXfwm = false;
          };
        };

        windowManager.i3 = {
          enable = true;
          package = pkgs.i3;
        };
      };

      pulseaudio.enable = false;
      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
        jack.enable = false;
      };
    };

    programs = {
      dconf.enable = true;
      i3lock.enable = true;
    };

    security = {
      polkit.enable = true;
      pam.services.i3lock.enable = true;
      rtkit.enable = true;
    };
  };
}
