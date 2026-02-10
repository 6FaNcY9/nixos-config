# Rofi configuration (Frost-Phoenix structure, palette-driven colors)
{
  config,
  pkgs,
  lib,
  palette,
  c,
  stylixFonts ? {monospace.name = "Monospace";},
  ...
}: let
  cfgLib = import ../../lib {inherit lib;};
  fontBase = stylixFonts.monospace.name;

  replace = cfgLib.mkColorReplacer {
    colors = {
      "bg-col" = palette.bg;
      "bg-col-light" = palette.bgAlt;
      "border-col" = "#d65d0e"; # Gruvbox orange — matches polybar accent
      "selected-col" = "#fabd2f"; # Yellow-alt — matches polybar focused workspace
      "green" = "#fe8019"; # Orange-alt — matches polybar MENU button
      "fg-col" = palette.text;
      "fg-col2" = c.base06;
      "grey" = palette.muted;
      "element-bg" = palette.bg;
      "element-alternate-bg" = palette.bgAlt;
      "font-base" = fontBase;
      "icon-theme" = "Papirus-Dark";
      "terminal" = "alacritty";
    };
  };

  themeText = replace (builtins.readFile ./theme.rasi);
  configText = replace (builtins.readFile ./config.rasi);
  powermenuText = replace (builtins.readFile ./powermenu-theme.rasi);

  # Power menu script
  powerMenu = cfgLib.mkShellScript {
    inherit pkgs;
    name = "rofi-power-menu";
    body = ''
      options=" Lock\n󰗽 Logout\n󰤄 Suspend\n Reboot\n Poweroff"

      chosen=$(echo -e "$options" | ${pkgs.rofi}/bin/rofi -dmenu \
        -i \
        -p "Power" \
        -theme powermenu-theme)

      case "$chosen" in
        *Lock)
          ${pkgs.i3lock}/bin/i3lock
          ;;
        *Logout)
          i3-msg exit
          ;;
        *Suspend)
          systemctl suspend
          ;;
        *Reboot)
          systemctl reboot
          ;;
        *Poweroff)
          systemctl poweroff
          ;;
      esac
    '';
  };

  # Network menu script
  networkMenu = cfgLib.mkShellScript {
    inherit pkgs;
    name = "rofi-network-menu";
    body = ''
            get_wifi_info() {
              local interface=$(${pkgs.iproute2}/bin/ip -br link | ${pkgs.gawk}/bin/awk '/wl/ {print $1; exit}')
              if [ -z "$interface" ]; then
                echo "No wireless interface found"
                return
              fi

              local ssid=$(${pkgs.networkmanager}/bin/nmcli -t -f active,ssid dev wifi | ${pkgs.gnugrep}/bin/grep '^yes' | ${pkgs.coreutils}/bin/cut -d':' -f2)
              local signal=$(${pkgs.networkmanager}/bin/nmcli -t -f active,signal dev wifi | ${pkgs.gnugrep}/bin/grep '^yes' | ${pkgs.coreutils}/bin/cut -d':' -f2)
              local ip=$(${pkgs.iproute2}/bin/ip -4 addr show "$interface" | ${pkgs.gawk}/bin/awk '/inet / {print $2}')

              if [ -n "$ssid" ]; then
                echo "Connected: $ssid"
                echo "Signal: $signal%"
                echo "IP: $ip"
                echo "Interface: $interface"
              else
                echo "Not connected"
                echo "Interface: $interface"
              fi
            }

            show_menu() {
              local info=$(get_wifi_info)
              local options="$info
      ────────────────
       Scan Networks
       Disconnect
      󰖪 Enable WiFi
      󰖪 Disable WiFi
       Network Settings"

              echo -e "$options" | ${pkgs.rofi}/bin/rofi -dmenu \
                -i \
                -p "Network"
            }

            show_networks() {
              ${pkgs.networkmanager}/bin/nmcli device wifi rescan 2>/dev/null
              sleep 1

              local networks=$(${pkgs.networkmanager}/bin/nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | \
                ${pkgs.gawk}/bin/awk -F: '{if ($1) printf "%s  %s%%  %s\n", $1, $2, ($3 ? "🔒" : "📡")}' | \
                ${pkgs.coreutils}/bin/sort -rn -k2)

              local chosen=$(echo "$networks" | ${pkgs.rofi}/bin/rofi -dmenu \
                -i \
                -p "Select Network")

              if [ -n "$chosen" ]; then
                local ssid=$(echo "$chosen" | ${pkgs.gawk}/bin/awk '{print $1}')
                ${pkgs.networkmanager}/bin/nmcli device wifi connect "$ssid" || \
                  ${pkgs.networkmanager}/bin/nmcli device wifi connect "$ssid" --ask
              fi
            }

            choice=$(show_menu)

            case "$choice" in
              *"Scan Networks")
                show_networks
                ;;
              *"Disconnect")
                ${pkgs.networkmanager}/bin/nmcli device disconnect wlan0 2>/dev/null || \
                ${pkgs.networkmanager}/bin/nmcli device disconnect wlp* 2>/dev/null
                ;;
              *"Enable WiFi")
                ${pkgs.networkmanager}/bin/nmcli radio wifi on
                ;;
              *"Disable WiFi")
                ${pkgs.networkmanager}/bin/nmcli radio wifi off
                ;;
              *"Network Settings")
                ${pkgs.networkmanagerapplet}/bin/nm-connection-editor &
                ;;
            esac
    '';
  };

  # Enhanced clipboard menu with Rofi
  clipboardMenu = cfgLib.mkShellScript {
    inherit pkgs;
    name = "rofi-clipboard-menu";
    body = ''
      export CM_LAUNCHER=rofi
      export CM_HISTLENGTH=20
      ${pkgs.clipmenu}/bin/clipmenu
    '';
  };
in {
  config = lib.mkIf config.profiles.desktop {
    # Disable Stylix theming for rofi; we manage it via palette-driven Rasi files.
    stylix.targets.rofi.enable = lib.mkDefault false;

    xdg = {
      configFile = {
        "rofi/theme.rasi".text = themeText;
        "rofi/config.rasi".text = configText;
        "rofi/powermenu-theme.rasi".text = powermenuText;
      };
    };

    home.packages = [
      powerMenu
      networkMenu
      clipboardMenu
    ];

    xsession.windowManager.i3.config.keybindings = let
      mod = config.xsession.windowManager.i3.config.modifier;
    in
      lib.mkOptionDefault {
        "${mod}+Shift+e" = "exec ${powerMenu}/bin/rofi-power-menu";
        "${mod}+Shift+v" = "exec ${clipboardMenu}/bin/rofi-clipboard-menu";
        "${mod}+Shift+n" = "exec ${networkMenu}/bin/rofi-network-menu";
      };
  };
}
