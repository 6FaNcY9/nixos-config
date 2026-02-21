#!/usr/bin/env bash
set -euo pipefail

brightness=$(($(brightnessctl get) * 100 / $(brightnessctl max)))
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -1)
muted=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -Po '(yes|no)')

player_status=$(playerctl status 2>/dev/null || echo "Stopped")
if [ "$player_status" = "Playing" ]; then
	title=$(playerctl metadata title 2>/dev/null | cut -c1-28)
	artist=$(playerctl metadata artist 2>/dev/null | cut -c1-18)
	[ -n "$artist" ] && now_playing="$artist - $title" || now_playing="$title"
	play_icon="󰐊"
elif [ "$player_status" = "Paused" ]; then
	title=$(playerctl metadata title 2>/dev/null | cut -c1-30)
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
	vol_label="${volume}%"
fi

if pgrep -f autotiling >/dev/null 2>&1; then
	auto_state="ON"
	auto_icon="󰕭"
else
	auto_state="OFF"
	auto_icon="󰕭"
fi

entries="󰃟  Brightness: ${brightness}%
$play_icon  $now_playing
$vol_icon  Volume: $vol_label
$auto_icon  Autotiling: $auto_state"

chosen=$(echo -e "$entries" | sed 's/^[[:space:]]*//' | rofi -dmenu \
	-theme ~/.config/rofi/dropdown-theme.rasi \
	-selected-row 0)

[ -z "$chosen" ] && exit 0

case "$chosen" in
*Brightness*)
	options="󰃞  100%\n󰃞  75%\n󰃝  50%\n󰃜  25%\n󰃛  10%"
	level=$(echo -e "$options" | rofi -dmenu \
		-theme ~/.config/rofi/dropdown-theme.rasi \
		-theme-str 'listview { lines: 5; }' \
		-selected-row 0)
	if [ -n "$level" ]; then
		pct=$(echo "$level" | grep -Po '\d+')
		brightnessctl set "${pct}%"
		notify-send -t 1500 "Brightness" "Set to ${pct}%"
	fi
	;;
*Volume* | *Muted*)
	if [ "$muted" = "yes" ]; then
		mute_label="󰖁  Unmute"
	else
		mute_label="󰖁  Mute"
	fi
	vol_options="󰕾  100%\n󰕾  75%\n󰕾  50%\n󰕾  25%\n󰕾  10%\n$mute_label\n󰓃  Switch Output"
	vol_choice=$(echo -e "$vol_options" | rofi -dmenu \
		-theme ~/.config/rofi/dropdown-theme.rasi \
		-theme-str 'listview { lines: 7; }' \
		-selected-row 0)
	if [ -n "$vol_choice" ]; then
		case "$vol_choice" in
		*Mute* | *Unmute*)
			pactl set-sink-mute @DEFAULT_SINK@ toggle
			new_mute=$(pactl get-sink-mute @DEFAULT_SINK@ | grep -Po '(yes|no)')
			if [ "$new_mute" = "yes" ]; then
				notify-send -t 1500 "Volume" "Muted"
			else
				new_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '\d+(?=%)' | head -1)
				notify-send -t 1500 "Volume" "Unmuted (${new_vol}%)"
			fi
			;;
		*"Switch Output"*)
			rofi-audio-switcher
			;;
		*)
			pct=$(echo "$vol_choice" | grep -Po '\d+')
			pactl set-sink-volume @DEFAULT_SINK@ "${pct}%"
			notify-send -t 1500 "Volume" "Set to ${pct}%"
			;;
		esac
	fi
	;;
*Autotiling*)
	if pgrep -f autotiling >/dev/null 2>&1; then
		pkill -f autotiling
		notify-send -t 1500 "Autotiling" "Disabled"
	else
		autotiling &
		notify-send -t 1500 "Autotiling" "Enabled"
	fi
	;;
*)
	if [ "$player_status" = "Playing" ] || [ "$player_status" = "Paused" ]; then
		playerctl play-pause
	fi
	;;
esac
