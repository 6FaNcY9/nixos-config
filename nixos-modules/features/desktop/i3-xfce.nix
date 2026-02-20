# Feature: i3-XFCE Desktop Environment
# Provides: i3 window manager + XFCE components + PipeWire audio
# Dependencies: X11 support
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.features.desktop.i3-xfce;
in
{
  options.features.desktop.i3-xfce = {
    enable = lib.mkEnableOption "i3 window manager with XFCE components";

    keyboardLayout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "X11 keyboard layout";
      example = "at";
    };

    displayManager = {
      defaultSession = lib.mkOption {
        type = lib.types.str;
        default = "xfce+i3";
        description = "Default display manager session";
      };

      lightdm = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable LightDM display manager";
        };

        indicators = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "~session"
            "~power"
            "~language"
            "~layout"
            "~a11y"
            "~clock"
            "~host"
          ];
          description = "LightDM GTK greeter indicators";
        };
      };
    };

    audio = {
      enablePipewire = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable PipeWire audio (recommended over PulseAudio)";
      };

      enableJack = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable JACK audio support";
      };
    };

    i3Package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.i3;
      description = "i3 window manager package to use";
    };
  };

  config = lib.mkIf cfg.enable {
    # File system support
    services = {
      gvfs.enable = true;
      udisks2.enable = true;

      displayManager.defaultSession = cfg.displayManager.defaultSession;

      # X server configuration
      xserver = {
        enable = true;
        xkb.layout = cfg.keyboardLayout;

        displayManager.lightdm = lib.mkIf cfg.displayManager.lightdm.enable {
          enable = true;
          greeters.gtk = {
            enable = true;
            inherit (cfg.displayManager.lightdm) indicators;
          };
        };

        desktopManager = {
          xterm.enable = false;
          xfce = {
            enable = true;
            noDesktop = true; # Use i3 for window management, XFCE for components
            enableXfwm = false; # Disable XFCE's window manager
          };
        };

        windowManager.i3 = {
          enable = true;
          package = cfg.i3Package;
        };
      };

      # Audio configuration
      pulseaudio.enable = false; # Disabled in favor of PipeWire
      pipewire = lib.mkIf cfg.audio.enablePipewire {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
        jack.enable = cfg.audio.enableJack;
      };
    };

    # Desktop programs
    programs = {
      dconf.enable = true; # Required for GTK settings
      i3lock.enable = true; # Screen locker
    };

    # Security settings
    security = {
      polkit.enable = true; # Policy kit for privilege escalation
      pam.services.i3lock.enable = true; # PAM support for i3lock
      rtkit.enable = true; # RealtimeKit for audio
    };

    # Warnings
    warnings =
      lib.optional (!cfg.audio.enablePipewire && !config.services.pulseaudio.enable)
        "features.desktop.i3-xfce: No audio system enabled (PipeWire disabled and PulseAudio not configured)";
  };
}
