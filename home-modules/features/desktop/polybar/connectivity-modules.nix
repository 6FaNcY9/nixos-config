{
  config,
  pkgs,
  lib,
  hasBattery,
  hasNetwork,
  hasLan,
  icons,
  mkPolybarTwoToneState,
}:
lib.mkMerge [
  # ── Network / WiFi (green two-tone) ──
  (lib.optionalAttrs hasNetwork {
    "module/network" = {
      type = "internal/network";
      interface = "${config.devices.networkInterface}";
      interval = 3;
      label-connected = "%essid%";
      label-disconnected = "off";
      click-right = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor &";
    }
    // mkPolybarTwoToneState {
      state = "connected";
      icon = icons.networkConnected;
      color = "green";
    }
    // mkPolybarTwoToneState {
      state = "disconnected";
      icon = icons.networkDisconnected;
      color = "red";
    };
  })

  # ── LAN / Ethernet (blue two-tone) ──
  (lib.optionalAttrs hasLan {
    "module/lan" = {
      type = "internal/network";
      interface = "${config.devices.lanInterface}";
      interval = 3;
      label-connected = "%local_ip%";
      label-disconnected = "off";
      click-right = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor &";
    }
    // mkPolybarTwoToneState {
      state = "connected";
      icon = icons.lanConnected;
      color = "blue";
    }
    // mkPolybarTwoToneState {
      state = "disconnected";
      icon = icons.lanDisconnected;
      color = "red";
    };
  })

  # ── Battery (aqua two-tone) ──
  (lib.optionalAttrs hasBattery {
    "module/battery" = {
      type = "internal/battery";
      inherit (config.devices) battery;
      full-at = 98;
      label-charging = "%percentage%%";
      label-discharging = "%percentage%%";
      label-full = "100%";
    }
    // mkPolybarTwoToneState {
      state = "charging";
      icon = icons.batteryCharging;
      color = "aqua";
    }
    // mkPolybarTwoToneState {
      state = "discharging";
      icon = icons.batteryDischarging;
      color = "aqua";
    }
    // mkPolybarTwoToneState {
      state = "full";
      icon = icons.batteryFull;
      color = "aqua";
    };
  })
]
