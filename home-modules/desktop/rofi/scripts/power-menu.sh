set -euo pipefail

options="󰌾 Lock\n󰤱 Logout\n󰤄 Suspend\n󰒲 Hibernate\n󰜉 Reboot\n󰐥 Poweroff"

chosen=$(echo -e "$options" | rofi -dmenu \
  -i \
  -p "Power" \
  -theme powermenu-theme)

[ -z "$chosen" ] && exit 0

confirm_action() {
  local answer
  answer=$(echo -e "󰄬 Yes\n󰅖 No" | rofi -dmenu \
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
