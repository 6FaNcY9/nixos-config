#!/usr/bin/env bash
set -euo pipefail

options="󰌾 Lock\n󰤱 Logout\n󰤄 Suspend\n󰒲 Hibernate\n󰜉 Reboot\n󰐥 Poweroff"

chosen_idx=$(echo -e "$options" | awk '{print $1}' | rofi -dmenu \
	-format i \
	-i \
	-p "" \
	-theme powermenu-theme)

[ -z "$chosen_idx" ] && exit 0

confirm_action() {
	local idx
	idx=$(echo -e "󰄬 Yes\n󰅖 No" | awk '{print $1}' | rofi -dmenu \
		-format i \
		-i \
		-p "" \
		-theme powermenu-theme \
		-theme-str 'listview { columns: 2; lines: 1; }' \
		-theme-str 'window { width: 320px; }' \
		-theme-str 'element { padding: 20px 10px; }' \
		-theme-str 'mainbox { children: [ "listview" ]; }')
	[ "$idx" = "0" ]
}

case "$chosen_idx" in
0) lock-screen ;;
1) i3-msg exit ;;
2) systemctl suspend ;;
3) systemctl hibernate ;;
4) confirm_action && systemctl reboot ;;
5) confirm_action && systemctl poweroff ;;
esac
