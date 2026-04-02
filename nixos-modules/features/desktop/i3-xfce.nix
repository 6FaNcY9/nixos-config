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
        enable = lib.mkEnableOption "LightDM display manager" // {
          default = true;
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
      enablePipewire = lib.mkEnableOption "PipeWire audio (recommended over PulseAudio)" // {
        default = true;
      };

      enableJack = lib.mkEnableOption "JACK audio support";
    };

    i3Package = lib.mkPackageOption pkgs "i3" { };
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

      # Audio configuration - PipeWire is modern replacement for PulseAudio
      pulseaudio.enable = false; # Disabled in favor of PipeWire (better latency and JACK support)
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
      dconf.enable = true; # Required for GTK settings and XFCE components to persist preferences
    };

    # Security settings
    security = {
      polkit.enable = true; # Policy kit for privilege escalation (mounting drives, NetworkManager, etc.)
      rtkit.enable = true; # RealtimeKit for audio - grants realtime scheduling to audio processes
      pam.services.lightdm.startSession = true;
      # Add pam_keyinit.so to the login session stack so every login (including
      # LightDM, which does `session include login`) gets a proper per-user
      # kernel session keyring. Without this, the session keyring is anonymous
      # (uid=0): child processes cannot "possess" keys in @u and get only
      # view-only (perm 0x01) instead of the possessor's full 0x3f, causing
      # `keyctl pipe` / `keyctl timeout` to fail with EACCES.
      # Required by qute-bitwarden to cache the Bitwarden session key.
      # The `revoke` flag clears all session-keyring keys on logout.
      pam.services.login.rules.session.keyinit = {
        modulePath = "${pkgs.linux-pam}/lib/security/pam_keyinit.so";
        control = "optional";
        args = [ "revoke" ];
        # Run immediately after pam_unix establishes the user identity.
        order = config.security.pam.services.login.rules.session.unix.order + 10;
      };
    };

    # Warnings
    warnings =
      lib.optional (!cfg.audio.enablePipewire && !config.services.pulseaudio.enable)
        "features.desktop.i3-xfce: No audio system enabled (PipeWire disabled and PulseAudio not configured)";
  };
}
