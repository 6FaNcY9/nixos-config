#!/usr/bin/env bash
set -euo pipefail

status_json=$(bw status 2>/dev/null || true)

if [ -z "$status_json" ]; then
	notify-send -u critical "Bitwarden" "Unable to query bw status"
	exit 1
fi

status=$(printf '%s' "$status_json" | jq -r '.status // "unknown"')

case "$status" in
unlocked) ;;
locked)
	notify-send "Bitwarden" "Unlock first with: bw unlock"
	exit 1
	;;
unauthenticated)
	notify-send "Bitwarden" "Login first with: bw login"
	exit 1
	;;
*)
	notify-send -u critical "Bitwarden" "Unexpected bw status: $status"
	exit 1
	;;
esac

mapfile -t items < <(
	bw list items | jq -cr '
    sort_by(.name // "" | ascii_downcase)[] |
    {
      name: (.name // "(unnamed)"),
      subtitle:
        (if .type == 1 then (.login.username // "")
         elif .type == 2 then "[Secure Note]"
         elif .type == 3 then
           ((.card.brand // "Card") +
             (if ((.card.number // "") | length) >= 4
              then " •••• " + ((.card.number // "")[-4:])
              else ""
              end))
         elif .type == 4 then
           ([.identity.firstName // "", .identity.lastName // ""]
             | map(select(length > 0))
             | join(" "))
         elif .type == 5 then "[SSH Key]"
         else ""
         end),
      secondary:
        (if .type == 1
         then ((.login.uris[0].uri // "") | sub("^https?://"; "") | split("/")[0])
         else ""
         end),
      password: (.login.password // "")
    }'
)

if [ "${#items[@]}" -eq 0 ]; then
	notify-send "Bitwarden" "No items found"
	exit 0
fi

labels=()
for item in "${items[@]}"; do
	name=$(printf '%s' "$item" | jq -r '.name')
	subtitle=$(printf '%s' "$item" | jq -r '.subtitle')
	secondary=$(printf '%s' "$item" | jq -r '.secondary')

	label="$name"
	if [ -n "$subtitle" ]; then
		label="$label — $subtitle"
	fi
	if [ -n "$secondary" ]; then
		label="$label · $secondary"
	fi

	labels+=("$label")
done

selected_index=$(printf '%s\n' "${labels[@]}" | rofi -dmenu -i -p "Bitwarden" -format i) || exit 0
selected_item=${items[$selected_index]}
selected_name=$(printf '%s' "$selected_item" | jq -r '.name')
selected_password=$(printf '%s' "$selected_item" | jq -r '.password')

if [ -z "$selected_password" ]; then
	notify-send "Bitwarden" "No password available for $selected_name"
	exit 1
fi

printf '%s' "$selected_password" | xclip -selection clipboard
notify-send -t 1500 "Bitwarden" "Copied password for $selected_name"
