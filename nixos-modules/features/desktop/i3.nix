# Feature: i3 Desktop Environment
# Provides: greetd+tuigreet login, i3 window manager, PipeWire audio
# Dependencies: X11 support
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.features.desktop.i3;
  xsessionPath = "${config.services.displayManager.sessionData.desktops}/share/xsessions";
in
{
  options.features.desktop.i3 = {
    enable = lib.mkEnableOption "i3 window manager with greetd + tuigreet";

    keyboardLayout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "X11 keyboard layout";
      example = "at";
    };

    displayManager.defaultSession = lib.mkOption {
      type = lib.types.str;
      default = "none+i3";
      description = "Default greetd session";
    };

    audio = {
      enablePipewire = lib.mkEnableOption "PipeWire audio (recommended over PulseAudio)" // {
        default = true;
      };

      enableJack = lib.mkEnableOption "JACK audio support";
    };

    i3Package = lib.mkPackageOption pkgs "i3" { };
  };

  config = lib.mkIf cfg.enable {
    services = {
      gvfs.enable = true;
      udisks2.enable = true;
      libinput.enable = true;

      displayManager.defaultSession = cfg.displayManager.defaultSession;

      greetd = {
        enable = true;
        settings.default_session = {
          command = "${lib.getExe pkgs.tuigreet} --time --xsessions ${xsessionPath}";
          user = "greeter";
        };
      };

      xserver = {
        enable = true;
        xkb.layout = cfg.keyboardLayout;

        displayManager.startx = {
          enable = true;
          generateScript = true;
        };

        desktopManager.xterm.enable = false;

        windowManager.i3 = {
          enable = true;
          package = cfg.i3Package;
        };
      };

      # Audio configuration - PipeWire is modern replacement for PulseAudio
      pulseaudio.enable = false;
      pipewire = lib.mkIf cfg.audio.enablePipewire {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
        jack.enable = cfg.audio.enableJack;
      };
    };

    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };

    programs = {
      dconf.enable = true;
    };

    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };

    warnings = lib.optional (
      !cfg.audio.enablePipewire && !config.services.pulseaudio.enable
    ) "features.desktop.i3: No audio system enabled (PipeWire disabled and PulseAudio not configured)";
  };
}
