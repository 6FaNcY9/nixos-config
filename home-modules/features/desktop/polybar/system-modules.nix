{
  config,
  pkgs,
  icons,
  mkPolybarTwoTone,
  mkPolybarTwoToneState,
}:
{
  # ── Temperature (red two-tone) ──
  "module/temp" = {
    type = "custom/script";
    exec = "${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gawk}/bin/awk '/^edge/||/^Tctl/ {print $2; exit}' || echo N/A";
    interval = 2;
  }
  // mkPolybarTwoTone {
    icon = icons.temp;
    color = "red";
  };

  # ── Memory (orange two-tone) ──
  "module/memory" = {
    type = "internal/memory";
    interval = 1;
    label = "%free%";
  }
  // mkPolybarTwoTone {
    icon = icons.memory;
    color = "orange";
  };

  # ── Audio (yellow two-tone, muted = red) ──
  "module/pulseaudio" = {
    type = "internal/pulseaudio";
    label-volume = "%percentage%%";
    label-muted = "muted";
  }
  // mkPolybarTwoToneState {
    state = "volume";
    icon = icons.volume;
    color = "yellow";
  }
  // mkPolybarTwoToneState {
    state = "muted";
    icon = icons.muted;
    color = "red";
  };

  # ── Power button (yellow block) ──
  "module/power" = {
    type = "custom/text";
    format = " ${icons.power} ";
    format-foreground = "\${colors.black}";
    format-background = "\${colors.yellow}";
  };

  # ── Brightness (purple two-tone) ──
  "module/brightness" = {
    type = "internal/backlight";
    card = config.devices.backlight;
    enable-scroll = true;
  }
  // mkPolybarTwoTone {
    icon = "";
    color = "purple";
  };

  # ── Now-Playing (custom script) ──
  "module/now-playing" = {
    type = "custom/script";
    exec = "${pkgs.writeShellScript "polybar-now-playing" ''
      player_status=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null)
      if [ "$player_status" = "Playing" ]; then
        title=$(${pkgs.playerctl}/bin/playerctl metadata title 2>/dev/null | cut -c1-30)
        artist=$(${pkgs.playerctl}/bin/playerctl metadata artist 2>/dev/null | cut -c1-20)
        if [ -n "$title" ]; then
          echo " $artist - $title"
        fi
      elif [ "$player_status" = "Paused" ]; then
        title=$(${pkgs.playerctl}/bin/playerctl metadata title 2>/dev/null | cut -c1-30)
        echo " $title"
      fi
    ''}";
    interval = 3;
    click-left = "${pkgs.playerctl}/bin/playerctl play-pause";
    click-right = "${pkgs.playerctl}/bin/playerctl next";
    format = "<label>";
    label = "%output%";
    label-foreground = "\${colors.cream}";
    format-background = "\${colors.bg}";
    format-padding = 1;
  };

  # ── Autotiling Indicator (aqua two-tone) ──
  "module/autotiling" = {
    type = "custom/script";
    exec = "${pkgs.writeShellScript "polybar-autotiling" ''
      if ${pkgs.procps}/bin/pgrep -f autotiling > /dev/null; then
        echo "on"
      else
        echo "off"
      fi
    ''}";
    interval = 5;
    click-left = "${pkgs.writeShellScript "toggle-autotiling" ''
      if ${pkgs.procps}/bin/pgrep -f autotiling > /dev/null; then
        ${pkgs.procps}/bin/pkill -f autotiling
      else
        ${pkgs.autotiling}/bin/autotiling &
      fi
    ''}";
  }
  // mkPolybarTwoTone {
    icon = icons.autotiling;
    color = "aqua";
  };
}
