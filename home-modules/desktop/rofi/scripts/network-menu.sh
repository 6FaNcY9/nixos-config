set -euo pipefail

get_interface() {
  nmcli -t -f DEVICE,TYPE device status | grep ':wifi$' | head -1 | cut -d: -f1
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
  ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
  signal=$(nmcli -t -f active,signal dev wifi | grep '^yes' | cut -d: -f2)
  ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2}')

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

  echo -e "$options" | rofi -dmenu \
    -i \
    -p "Network" \
    -theme network-theme
}

show_networks() {
  nmcli device wifi rescan 2>/dev/null
  sleep 1

  local networks
  networks=$(nmcli -t -f SSID,SIGNAL,SECURITY device wifi list | \
    awk -F: '{
      if ($1 != "" && !seen[$1]++) {
        if ($2 >= 75) icon="󰤨"
        else if ($2 >= 50) icon="󰤥"
        else if ($2 >= 25) icon="󰤢"
        else icon="󰤟"
        lock = ($3 != "") ? "󰌾" : "󰌷"
        printf "%s %s  %s%%  %s\n", icon, $1, $2, lock
      }
    }' | sort -t'%' -k1 -rn)

  local chosen
  chosen=$(echo "$networks" | rofi -dmenu \
    -i \
    -p "Select Network" \
    -theme network-theme)

  if [ -n "$chosen" ]; then
    local ssid
    ssid=$(echo "$chosen" | awk '{print $2}')
    if nmcli device wifi connect "$ssid" 2>/dev/null; then
      notify-send -i network-wireless "WiFi" "Connected to $ssid"
    else
      nmcli device wifi connect "$ssid" --ask
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
      nmcli device disconnect "$iface"
      notify-send -i network-offline "WiFi" "Disconnected"
    fi
    ;;
  *"Enable WiFi")
    nmcli radio wifi on
    notify-send -i network-wireless "WiFi" "Enabled"
    ;;
  *"Disable WiFi")
    nmcli radio wifi off
    notify-send -i network-offline "WiFi" "Disabled"
    ;;
  *"Network Settings")
    nm-connection-editor &
    ;;
esac
