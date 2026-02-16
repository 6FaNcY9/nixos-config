# Rofi menu scripts (power, network, clipboard)
{
  config,
  pkgs,
  lib,
  cfgLib,
  ...
}:
let
  rofi = "${pkgs.rofi}/bin/rofi";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";
  notify = "${pkgs.libnotify}/bin/notify-send";

  # Power menu script -- 6 options with confirmation for destructive actions
  powerMenu = cfgLib.mkShellScript {
    inherit pkgs;
    name = "rofi-power-menu";
    body = ''
      options="󰌾 Lock\n󰤱 Logout\n󰤄 Suspend\n󰒲 Hibernate\n󰜉 Reboot\n󰐥 Poweroff"

      chosen=$(echo -e "$options" | ${rofi} -dmenu \
        -i \
        -p "Power" \
        -theme powermenu-theme)

      [ -z "$chosen" ] && exit 0

      confirm_action() {
        local answer
        answer=$(echo -e "󰄬 Yes\n󰅖 No" | ${rofi} -dmenu \
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
          lock-screen
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
              if   [ "$signal" -ge 75 ]; then echo "󰤨"
              elif [ "$signal" -ge 50 ]; then echo "󰤥"
              elif [ "$signal" -ge 25 ]; then echo "󰤢"
              else echo "󰤟"
              fi
            }

            get_wifi_info() {
              local iface
              iface=$(get_interface)
              if [ -z "$iface" ]; then
                echo "󰤭 No wireless interface"
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
                echo "󰤭 Not connected"
              fi
            }

            show_menu() {
              local info
              info=$(get_wifi_info)
              local options="$info
      ────────────────
      󰍉 Scan Networks
      󰩬 Disconnect
      󰘉 Enable WiFi
      󰘊 Disable WiFi
      󰒓 Network Settings"

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
                    if ($2 >= 75) icon="󰤨"
                    else if ($2 >= 50) icon="󰤥"
                    else if ($2 >= 25) icon="󰤢"
                    else icon="󰤟"
                    lock = ($3 != "") ? "󰌾" : "󰌷"
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

  # Audio output switcher -- pactl-based device selection
  audioSwitcher = cfgLib.mkShellScript {
    inherit pkgs;
    name = "rofi-audio-switcher";
    body = ''
      get_sinks() {
        ${pkgs.pulseaudio}/bin/pactl list sinks short | while IFS=$'\t' read -r id name _ state _; do
          description=$(${pkgs.pulseaudio}/bin/pactl list sinks | grep -A1 "Sink #$id" | grep "Description:" | sed 's/.*Description: //')
          default_sink=$(${pkgs.pulseaudio}/bin/pactl get-default-sink)
          if [ "$name" = "$default_sink" ]; then
            printf "󰓃  %s (active)\n" "$description"
          else
            printf "󰋋  %s\n" "$description"
          fi
        done
      }

      chosen=$(get_sinks | ${rofi} -dmenu -p " 󰓃  Audio" -theme ~/.config/rofi/audio-switcher-theme.rasi)

      if [ -z "$chosen" ]; then
        exit 0
      fi

      # Strip icon prefix and (active) suffix to get description
      clean_name=$(echo "$chosen" | sed 's/^[^ ]* *//; s/ (active)$//')

      # Find matching sink by description
      sink_name=$(${pkgs.pulseaudio}/bin/pactl list sinks | grep -B1 "Description: $clean_name" | grep "Name:" | sed 's/.*Name: //')

      if [ -n "$sink_name" ]; then
        ${pkgs.pulseaudio}/bin/pactl set-default-sink "$sink_name"
        ${notify} "Audio Output" "Switched to: $clean_name"
      fi
    '';
  };

  # Dropdown menu -- consolidates brightness, now-playing, audio, autotiling
  dropdownMenu = cfgLib.mkShellScript {
    inherit pkgs;
    name = "rofi-dropdown-menu";
    body = ''
      brightnessctl="${pkgs.brightnessctl}/bin/brightnessctl"
      playerctl="${pkgs.playerctl}/bin/playerctl"
      pactl="${pkgs.pulseaudio}/bin/pactl"
      pgrep="${pkgs.procps}/bin/pgrep"
      pkill="${pkgs.procps}/bin/pkill"

      brightness=$(( $($brightnessctl get) * 100 / $($brightnessctl max) ))
      volume=$($pactl get-sink-volume @DEFAULT_SINK@ | ${pkgs.gnugrep}/bin/grep -Po '\d+(?=%)' | ${pkgs.coreutils}/bin/head -1)
      muted=$($pactl get-sink-mute @DEFAULT_SINK@ | ${pkgs.gnugrep}/bin/grep -Po '(yes|no)')

      player_status=$($playerctl status 2>/dev/null || echo "Stopped")
      if [ "$player_status" = "Playing" ]; then
        title=$($playerctl metadata title 2>/dev/null | ${pkgs.coreutils}/bin/cut -c1-28)
        artist=$($playerctl metadata artist 2>/dev/null | ${pkgs.coreutils}/bin/cut -c1-18)
        [ -n "$artist" ] && now_playing="$artist - $title" || now_playing="$title"
        play_icon="󰐊"
      elif [ "$player_status" = "Paused" ]; then
        title=$($playerctl metadata title 2>/dev/null | ${pkgs.coreutils}/bin/cut -c1-30)
        now_playing="$title (paused)"
        play_icon="󰏤"
      else
        now_playing="Nothing playing"
        play_icon="󰏤"
      fi

      if [ "$muted" = "yes" ]; then
        vol_icon="󰖁"
        vol_label="Muted"
      else
        vol_icon="󰕾"
        vol_label="''${volume}%"
      fi

      if $pgrep -f autotiling > /dev/null 2>&1; then
        auto_state="ON"
        auto_icon="󰕭"
      else
        auto_state="OFF"
        auto_icon="󰕭"
      fi

      entries="󰃟  Brightness: ''${brightness}%
      $play_icon  $now_playing
      $vol_icon  Volume: $vol_label
      $auto_icon  Autotiling: $auto_state"

      chosen=$(echo -e "$entries" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//' | ${rofi} -dmenu \
        -theme ~/.config/rofi/dropdown-theme.rasi \
        -selected-row 0)

      [ -z "$chosen" ] && exit 0

      case "$chosen" in
        *Brightness*)
          current=$(( $($brightnessctl get) * 100 / $($brightnessctl max) ))
          options="󰃞  100%\n󰃞  75%\n󰃝  50%\n󰃜  25%\n󰃛  10%"
          level=$(echo -e "$options" | ${rofi} -dmenu \
            -theme ~/.config/rofi/dropdown-theme.rasi \
            -theme-str 'listview { lines: 5; }' \
            -selected-row 0)
          if [ -n "$level" ]; then
            pct=$(echo "$level" | ${pkgs.gnugrep}/bin/grep -Po '\d+')
            $brightnessctl set "''${pct}%"
            ${notify} -t 1500 "Brightness" "Set to ''${pct}%"
          fi
          ;;
        *Volume*|*Muted*)
          if [ "$muted" = "yes" ]; then
            mute_label="󰖁  Unmute"
          else
            mute_label="󰖁  Mute"
          fi
          vol_options="󰕾  100%\n󰕾  75%\n󰕾  50%\n󰕾  25%\n󰕾  10%\n$mute_label\n󰓃  Switch Output"
          vol_choice=$(echo -e "$vol_options" | ${rofi} -dmenu \
            -theme ~/.config/rofi/dropdown-theme.rasi \
            -theme-str 'listview { lines: 7; }' \
            -selected-row 0)
          if [ -n "$vol_choice" ]; then
            case "$vol_choice" in
              *Mute*|*Unmute*)
                $pactl set-sink-mute @DEFAULT_SINK@ toggle
                new_mute=$($pactl get-sink-mute @DEFAULT_SINK@ | ${pkgs.gnugrep}/bin/grep -Po '(yes|no)')
                if [ "$new_mute" = "yes" ]; then
                  ${notify} -t 1500 "Volume" "Muted"
                else
                  new_vol=$($pactl get-sink-volume @DEFAULT_SINK@ | ${pkgs.gnugrep}/bin/grep -Po '\d+(?=%)' | ${pkgs.coreutils}/bin/head -1)
                  ${notify} -t 1500 "Volume" "Unmuted (''${new_vol}%)"
                fi
                ;;
              *"Switch Output"*)
                ${audioSwitcher}/bin/rofi-audio-switcher
                ;;
              *)
                pct=$(echo "$vol_choice" | ${pkgs.gnugrep}/bin/grep -Po '\d+')
                $pactl set-sink-volume @DEFAULT_SINK@ "''${pct}%"
                ${notify} -t 1500 "Volume" "Set to ''${pct}%"
                ;;
            esac
          fi
          ;;
        *Autotiling*)
          if $pgrep -f autotiling > /dev/null 2>&1; then
            $pkill -f autotiling
            ${notify} -t 1500 "Autotiling" "Disabled"
          else
            ${pkgs.autotiling}/bin/autotiling &
            ${notify} -t 1500 "Autotiling" "Enabled"
          fi
          ;;
        *)
          if [ "$player_status" = "Playing" ] || [ "$player_status" = "Paused" ]; then
            $playerctl play-pause
          fi
          ;;
      esac
    '';
  };
in
{
  config = lib.mkIf config.profiles.desktop {
    home.packages = [
      powerMenu
      networkMenu
      clipboardMenu
      audioSwitcher
      dropdownMenu
    ];

    services.polybar.settings = {
      "module/menu" = {
        click-left = "exec ${dropdownMenu}/bin/rofi-dropdown-menu &";
      };
      "module/power" = {
        click-left = "exec ${powerMenu}/bin/rofi-power-menu";
      };
      "module/network" = {
        click-left = "${networkMenu}/bin/rofi-network-menu";
      };
    };

    xsession.windowManager.i3.config.keybindings =
      let
        mod = config.xsession.windowManager.i3.config.modifier;
      in
      lib.mkOptionDefault {
        "${mod}+Shift+e" = "exec ${powerMenu}/bin/rofi-power-menu";
        "${mod}+Shift+v" = "exec ${clipboardMenu}/bin/rofi-clipboard-menu";
        "${mod}+Shift+n" = "exec ${networkMenu}/bin/rofi-network-menu";
        "${mod}+Shift+s" = "exec ${audioSwitcher}/bin/rofi-audio-switcher";
      };
  };
}
