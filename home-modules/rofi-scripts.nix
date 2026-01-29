# Rofi scripts for power menu, network menu, and enhanced clipboard
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Power menu script
  powerMenu = pkgs.writeShellScriptBin "rofi-power-menu" ''
    # Power menu with Rofi
    options="Lock\nLogout\nSuspend\nReboot\nPoweroff"

    chosen=$(echo -e "$options" | ${pkgs.rofi}/bin/rofi -dmenu \
      -i \
      -p "Power Menu" \
      -theme-str 'window {width: 200px;}' \
      -theme-str 'listview {lines: 5;}')

    case "$chosen" in
      Lock)
        ${pkgs.i3lock}/bin/i3lock
        ;;
      Logout)
        i3-msg exit
        ;;
      Suspend)
        systemctl suspend
        ;;
      Reboot)
        systemctl reboot
        ;;
      Poweroff)
        systemctl poweroff
        ;;
    esac
  '';

  # Network menu script
  networkMenu = pkgs.writeShellScriptBin "rofi-network-menu" ''
        #!/usr/bin/env bash

        # Get network information
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

        # Main menu
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
            -p "Network" \
            -theme-str 'window {width: 400px;}' \
            -theme-str 'listview {lines: 10;}'
        }

        # Show available networks
        show_networks() {
          ${pkgs.networkmanager}/bin/nmcli device wifi rescan 2>/dev/null
          sleep 1

          local networks=$(${pkgs.networkmanager}/bin/nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | \
            ${pkgs.gawk}/bin/awk -F: '{if ($1) printf "%s  %s%%  %s\n", $1, $2, ($3 ? "🔒" : "📡")}' | \
            ${pkgs.coreutils}/bin/sort -rn -k2)

          local chosen=$(echo "$networks" | ${pkgs.rofi}/bin/rofi -dmenu \
            -i \
            -p "Select Network" \
            -theme-str 'window {width: 500px;}')

          if [ -n "$chosen" ]; then
            local ssid=$(echo "$chosen" | ${pkgs.gawk}/bin/awk '{print $1}')
            ${pkgs.networkmanager}/bin/nmcli device wifi connect "$ssid" || \
              ${pkgs.networkmanager}/bin/nmcli device wifi connect "$ssid" --ask
          fi
        }

        # Process selection
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

  # Enhanced clipboard menu with Rofi
  clipboardMenu = pkgs.writeShellScriptBin "rofi-clipboard-menu" ''
    # Use clipmenu with rofi
    export CM_LAUNCHER=rofi
    export CM_HISTLENGTH=20
    ${pkgs.clipmenu}/bin/clipmenu \
      -theme-str 'window {width: 600px;}' \
      -theme-str 'listview {lines: 15;}'
  '';
in {
  config = lib.mkIf config.profiles.desktop {
    home.packages = [
      powerMenu
      networkMenu
      clipboardMenu
    ];

    # Update i3 keybindings to use new scripts
    xsession.windowManager.i3.config.keybindings = let
      mod = config.xsession.windowManager.i3.config.modifier;
    in
      lib.mkOptionDefault {
        # Power menu
        "${mod}+Shift+e" = "exec ${powerMenu}/bin/rofi-power-menu";

        # Clipboard menu
        "${mod}+Shift+v" = "exec ${clipboardMenu}/bin/rofi-clipboard-menu";

        # Network menu
        "${mod}+Shift+n" = "exec ${networkMenu}/bin/rofi-network-menu";
      };
  };
}
