{
  pkgs,
  hasIcons,
  wsIconAttrs,
  hostname,
  icons,
  mkPolybarTwoTone,
}:
{
  # ── MENU button (opens dropdown with brightness, now-playing, volume, autotiling) ──
  "module/menu" = {
    type = "custom/text";
    format = " MENU ";
    click-right = "exec ${pkgs.rofi}/bin/rofi -show drun -disable-history -show-icons &";
    format-foreground = "\${colors.black}";
    format-background = "\${colors.orange-alt}";
  };

  # ── i3 workspaces ──
  "module/i3" = {
    type = "internal/i3";
    enable-scroll = false;
    pin-workspaces = true;
    show-urgent = true;
    strip-wsnumbers = hasIcons;
    index-sort = true;
    enable-click = true;
    fuzzy-match = true;
    ws-icon-default = "";
    format = "<label-state><label-mode>";
    label-mode = " %mode% ";
    label-mode-padding = 1;
    label-mode-background = "\${colors.red}";
    label-mode-foreground = "\${colors.cream}";
    label-focused = " %icon% ";
    label-focused-foreground = "\${colors.black}";
    label-focused-background = "\${colors.yellow-alt}";
    label-focused-padding = 0;
    label-unfocused = " %icon% ";
    label-unfocused-foreground = "\${colors.muted}";
    label-unfocused-background = "\${colors.bg}";
    label-unfocused-padding = 0;
    label-visible = " %icon% ";
    label-visible-foreground = "\${colors.yellow-alt}";
    label-visible-underline = "\${colors.red}";
    label-visible-padding = 0;
    label-urgent = " %icon% ";
    label-urgent-foreground = "\${colors.black}";
    label-urgent-background = "\${colors.red-alt}";
    label-urgent-padding = 0;
    label-separator = " ";
    label-separator-padding = 0;
  }
  // wsIconAttrs;

  # ── Tray ──
  "module/tray" = {
    type = "internal/tray";
    format = "<tray>";
    format-background = "\${colors.dark}";
    tray-padding = 2;
    tray-size = 14;
    tray-background = "\${colors.dark}";
  };

  # ── Window title (purple two-tone) ──
  "module/xwindow" = {
    type = "internal/xwindow";
    label = "%title:0:50:.....%";
  }
  // mkPolybarTwoTone {
    icon = icons.xwindow;
    color = "purple";
  };

  # ── Time + Date (center, yellow two-tone, merged block) ──
  "module/time" = {
    type = "internal/date";
    interval = 1;
    time = "%H:%M:%S";
    date = "%d-%m-%Y";
    format = "<label>";
    label = "%{A1:${pkgs.gsimplecal}/bin/gsimplecal &:}%time%  ||  %date%%{A}";
  }
  // mkPolybarTwoTone {
    icon = icons.time;
    color = "yellow";
  };

  # ── Hostname (blue two-tone) ──
  "module/host" = {
    type = "custom/script";
    exec = "echo ${hostname}";
    interval = 3600;
  }
  // mkPolybarTwoTone {
    icon = icons.host;
    color = "blue";
  };

  # ── CPU (green two-tone) ──
  "module/cpu" = {
    type = "internal/cpu";
    interval = 1;
    label = "%percentage:2%%";
  }
  // mkPolybarTwoTone {
    icon = icons.cpu;
    color = "green";
  };
}
