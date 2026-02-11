# Rofi menu scripts (power, network, clipboard)
{
  config,
  pkgs,
  lib,
  cfgLib,
  ...
}: let
  rofi = "${pkgs.rofi}/bin/rofi";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  notify = "${pkgs.libnotify}/bin/notify-send";

  # Power menu script -- 6 options with confirmation for destructive actions
  powerMenu = cfgLib.mkShellScript {
    inherit pkgs;
    name = "rofi-power-menu";
    body = ''
      options=" Lock\n\u{f0931} Logout\n\u{f0904} Suspend\n\u{f04b2} Hibernate\n Reboot\n Poweroff"

      chosen=$(echo -e "$options" | ${rofi} -dmenu \
        -i \
        -p "Power" \
        -theme powermenu-theme)

      [ -z "$chosen" ] && exit 0

      confirm_action() {
        local answer
        answer=$(echo -e " Yes\n No" | ${rofi} -dmenu \
          -i \
          -p "Are you sure?" \
          -theme powermenu-theme \
          -theme-str 'listview { columns: 2; lines: 1; }' \
          -theme-str 'window { width: 320px; }' \
          -theme-str 'element { padding: 20px 10px; }' \
          -theme-str 'mainbox { children: [ "listview" ]; }')
        [[ "$answer" == *"Yes"* ]]
      }

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
        *Hibernate)
          systemctl hibernate
          ;;
        *Reboot)
          confirm_action && systemctl reboot
          ;;
        *Poweroff)
          confirm_action && systemctl poweroff
          ;;
      esac
    '';
  };

  # Network menu script -- dynamic interface detection, signal strength icons
  networkMenu = cfgLib.mkShellScript {
    inherit pkgs;
    name = "rofi-network-menu";
    body = ''
            get_interface() {
              ${nmcli} -t -f DEVICE,TYPE device status | ${pkgs.gnugrep}/bin/grep ':wifi$' | ${pkgs.coreutils}/bin/head -1 | ${pkgs.coreutils}/bin/cut -d: -f1
            }

            signal_icon() {
              local signal="$1"
              if   [ "$signal" -ge 75 ]; then echo "\u{f0928}"
              elif [ "$signal" -ge 50 ]; then echo "\u{f0925}"
              elif [ "$signal" -ge 25 ]; then echo "\u{f0922}"
              else echo "\u{f091f}"
              fi
            }

            get_wifi_info() {
              local iface
              iface=$(get_interface)
              if [ -z "$iface" ]; then
                echo "\u{f092d} No wireless interface"
                return
              fi

              local ssid signal ip
              ssid=$(${nmcli} -t -f active,ssid dev wifi | ${pkgs.gnugrep}/bin/grep '^yes' | ${pkgs.coreutils}/bin/cut -d: -f2)
              signal=$(${nmcli} -t -f active,signal dev wifi | ${pkgs.gnugrep}/bin/grep '^yes' | ${pkgs.coreutils}/bin/cut -d: -f2)
              ip=$(${pkgs.iproute2}/bin/ip -4 addr show "$iface" 2>/dev/null | ${pkgs.gawk}/bin/awk '/inet / {print $2}')

              if [ -n "$ssid" ]; then
                local icon
                icon=$(signal_icon "$signal")
                echo "$icon $ssid ($signal%) - $ip"
              else
                echo "\u{f092d} Not connected"
              fi
            }

            show_menu() {
              local info
              info=$(get_wifi_info)
              local options="$info
      \u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}
       Scan Networks
       Disconnect
      \u{f0609} Enable WiFi
      \u{f060a} Disable WiFi
       Network Settings"

              echo -e "$options" | ${rofi} -dmenu \
                -i \
                -p "Network" \
                -theme network-theme
            }

            show_networks() {
              ${nmcli} device wifi rescan 2>/dev/null
              sleep 1

              local networks
              networks=$(${nmcli} -t -f SSID,SIGNAL,SECURITY device wifi list | \
                ${pkgs.gawk}/bin/awk -F: '{
                  if ($1 != "" && !seen[$1]++) {
                    if ($2 >= 75) icon="\u{f0928}"
                    else if ($2 >= 50) icon="\u{f0925}"
                    else if ($2 >= 25) icon="\u{f0922}"
                    else icon="\u{f091f}"
                    lock = ($3 != "") ? "\u{f033e}" : "\u{f0337}"
                    printf "%s %s  %s%%  %s\n", icon, $1, $2, lock
                  }
                }' | ${pkgs.coreutils}/bin/sort -t'%' -k1 -rn)

              local chosen
              chosen=$(echo "$networks" | ${rofi} -dmenu \
                -i \
                -p "Select Network" \
                -theme network-theme)

              if [ -n "$chosen" ]; then
                local ssid
                ssid=$(echo "$chosen" | ${pkgs.gawk}/bin/awk '{print $2}')
                if ${nmcli} device wifi connect "$ssid" 2>/dev/null; then
                  ${notify} -i network-wireless "WiFi" "Connected to $ssid"
                else
                  ${nmcli} device wifi connect "$ssid" --ask
                fi
              fi
            }

            choice=$(show_menu)
            [ -z "$choice" ] && exit 0

            iface=$(get_interface)

            case "$choice" in
              *"Scan Networks")
                show_networks
                ;;
              *"Disconnect")
                if [ -n "$iface" ]; then
                  ${nmcli} device disconnect "$iface"
                  ${notify} -i network-offline "WiFi" "Disconnected"
                fi
                ;;
              *"Enable WiFi")
                ${nmcli} radio wifi on
                ${notify} -i network-wireless "WiFi" "Enabled"
                ;;
              *"Disable WiFi")
                ${nmcli} radio wifi off
                ${notify} -i network-offline "WiFi" "Disabled"
                ;;
              *"Network Settings")
                ${pkgs.networkmanagerapplet}/bin/nm-connection-editor &
                ;;
            esac
    '';
  };

  # Clipboard menu -- themed clipmenu wrapper
  clipboardMenu = cfgLib.mkShellScript {
    inherit pkgs;
    name = "rofi-clipboard-menu";
    body = ''
      export CM_LAUNCHER=rofi
      export CM_HISTLENGTH=20
      export ROFI_THEME=clipboard-theme
      CM_LAUNCHER_ARGS="-theme clipboard-theme" ${pkgs.clipmenu}/bin/clipmenu
    '';
  };
in {
  config = lib.mkIf config.profiles.desktop {
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
