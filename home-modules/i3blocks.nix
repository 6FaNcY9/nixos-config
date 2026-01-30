{
  lib,
  pkgs,
  hostname,
  palette,
  config,
  ...
}: let
  cfgLib = import ../lib {inherit lib;};
in {
  config = lib.mkIf config.profiles.desktop {
    programs.i3blocks = let
      # Generic wrapper for block scripts
      mkBlockScript = name: body:
        cfgLib.mkShellScript {
          inherit pkgs body;
          name = "i3blocks-${name}";
        };

      hostBlock = mkBlockScript "host" ''
        printf '   %s\n\n${palette.accent2}\n' "${hostname}"
      '';

      netBlock = mkBlockScript "net" ''
        info="$(${pkgs.networkmanager}/bin/nmcli -t -f TYPE,STATE,CONNECTION dev status | ${pkgs.gawk}/bin/awk -F: '$2=="connected"{print $1":"$3; exit}')"
        color="${palette.danger}"
        text="  offline"

        if test -n "$info"; then
          type="''${info%%:*}"
          name="''${info#*:}"
          icon="󰈀"
          color="${palette.accent2}"

          if test "$type" = "wifi"; then
            icon=""
            color="${palette.accent}"
          fi

          text=" $icon $name"
        fi

        printf '%s\n%s\n%s\n' "$text" "$text" "$color"
      '';

      volumeBlock = mkBlockScript "volume" ''
        sink="$(${pkgs.pulseaudio}/bin/pactl info | ${pkgs.gawk}/bin/awk -F': ' '$1=="Default Sink"{print $2}')"
        if test -z "$sink"; then sink="@DEFAULT_SINK@"; fi

        volume="$(${pkgs.pulseaudio}/bin/pactl get-sink-volume "$sink" | ${pkgs.coreutils}/bin/head -n1 | ${pkgs.gawk}/bin/awk '{gsub("%","",$5); print $5}')"
        mute="$(${pkgs.pulseaudio}/bin/pactl get-sink-mute "$sink" | ${pkgs.gawk}/bin/awk '{print $2}')"

        vol="''${volume:-0}"
        icon="󰕾"
        color="${palette.accent2}"

        if test "''${mute:-no}" = "yes"; then
          icon="󰝟"
          color="${palette.danger}"
        elif test "$vol" -gt 80; then
          color="${palette.warn}"
        fi

        printf ' %s %s%%\n\n%s\n' "$icon" "$vol" "$color"
      '';

      batteryBlock = mkBlockScript "battery" ''
        bat="$(${pkgs.upower}/bin/upower -e | ${pkgs.gnugrep}/bin/grep -m1 BAT || true)"
        if test -z "$bat"; then
          printf '   n/a\n\n${palette.muted}\n'
          exit 0
        fi

        info="$(${pkgs.upower}/bin/upower -i "$bat")"
        percent="$(echo "$info" | ${pkgs.gawk}/bin/awk '/percentage/ {gsub("%","",$2); print $2}')"
        state="$(echo "$info" | ${pkgs.gawk}/bin/awk '/state/ {print $2}')"

        p="''${percent:-0}"
        icon=""
        color="${palette.accent}"

        if test "''${state:-}" = "charging"; then
          icon=""
          color="${palette.accent2}"
        elif test "''${state:-}" = "fully-charged"; then
          icon=""
          color="${palette.accent2}"
        else
          if test "$p" -lt 20; then
            icon=""
            color="${palette.danger}"
          elif test "$p" -lt 40; then
            icon=""
            color="${palette.warn}"
          elif test "$p" -lt 65; then
            icon=""
          fi
        fi

        printf ' %s %s%%\n\n%s\n' "$icon" "$p" "$color"
      '';

      powerProfileBlock = mkBlockScript "power-profile" ''
        prof="$(${pkgs.power-profiles-daemon}/bin/powerprofilesctl get 2>/dev/null || true)"
        icon=""
        color="${palette.accent2}"

        case "$prof" in
          performance)
            icon=""
            color="${palette.danger}"
            ;;
          power-saver)
            icon=""
            color="${palette.accent}"
            ;;
          "" )
            prof="unknown"
            icon=""
            color="${palette.muted}"
            ;;
        esac

        printf ' %s %s\n\n%s\n' "$icon" "$prof" "$color"
      '';

      brightnessBlock = mkBlockScript "brightness" ''
        level="$(${pkgs.brightnessctl}/bin/brightnessctl -m | ${pkgs.coreutils}/bin/cut -d, -f4 | tr -d "%" 2>/dev/null || true)"
        lvl="''${level:-0}"

        icon="󰃟"
        color="${palette.accent2}"

        if test "$lvl" -lt 30; then
          icon="󰃞"
          color="${palette.accent}"
        elif test "$lvl" -gt 70; then
          icon="󰃝"
          color="${palette.warn}"
        fi

        printf ' %s %s%%\n\n%s\n' "$icon" "$lvl" "$color"
      '';

      timeBlock = mkBlockScript "time" ''
        now="$(${pkgs.coreutils}/bin/date '+%H:%M')"
        printf '   %s\n\n${palette.accent2}\n' "$now"
      '';

      dateBlock = mkBlockScript "date" ''
        today="$(${pkgs.coreutils}/bin/date '+%a %d %b %Y')"
        printf '   %s\n\n${palette.text}\n' "$today"
      '';
    in {
      enable = false; # i3blocks is currently inactive

      bars.top = {
        host = lib.hm.dag.entryAnywhere {
          command = "${hostBlock}/bin/i3blocks-host";
          interval = 600;
          separator = false;
        };

        net = lib.hm.dag.entryAfter ["host"] {
          command = "${netBlock}/bin/i3blocks-net";
          interval = 10;
          separator = false;
        };

        volume = lib.hm.dag.entryAfter ["net"] {
          command = "${volumeBlock}/bin/i3blocks-volume";
          interval = 2;
          separator = false;
        };

        battery = lib.hm.dag.entryAfter ["volume"] {
          command = "${batteryBlock}/bin/i3blocks-battery";
          interval = 20;
          separator = false;
        };

        power = lib.hm.dag.entryAfter ["battery"] {
          command = "${powerProfileBlock}/bin/i3blocks-power-profile";
          interval = 10;
          separator = false;
        };

        brightness = lib.hm.dag.entryAfter ["power"] {
          command = "${brightnessBlock}/bin/i3blocks-brightness";
          interval = 5;
          separator = false;
        };

        time = lib.hm.dag.entryAfter ["brightness"] {
          command = "${timeBlock}/bin/i3blocks-time";
          interval = 5;
          separator = false;
        };

        date = lib.hm.dag.entryAfter ["time"] {
          command = "${dateBlock}/bin/i3blocks-date";
          interval = 60;
          separator = false;
        };
      };
    };
  };
}
