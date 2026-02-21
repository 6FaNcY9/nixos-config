#!/usr/bin/env bash
set -euo pipefail

get_sinks() {
	pactl list sinks short | while IFS=$'\t' read -r id name _ _ _; do
		description=$(pactl list sinks | grep -A1 "Sink #$id" | grep "Description:" | sed 's/.*Description: //')
		default_sink=$(pactl get-default-sink)
		if [ "$name" = "$default_sink" ]; then
			printf "󰓃  %s (active)\n" "$description"
		else
			printf "󰋋  %s\n" "$description"
		fi
	done
}

chosen=$(get_sinks | rofi -dmenu -p " 󰓃  Audio" -theme ~/.config/rofi/audio-switcher-theme.rasi)

if [ -z "$chosen" ]; then
	exit 0
fi

# Strip icon prefix and (active) suffix to get description
clean_name=$(echo "$chosen" | sed 's/^[^ ]* *//; s/ (active)$//')

# Find matching sink by description
sink_name=$(pactl list sinks | grep -B1 "Description: $clean_name" | grep "Name:" | sed 's/.*Name: //')

if [ -n "$sink_name" ]; then
	pactl set-default-sink "$sink_name"
	notify-send "Audio Output" "Switched to: $clean_name"
fi
