#!/bin/bash

file="/home/justice-reaper/.config/bin/scope"
dir="/home/justice-reaper/.config/rofi/scope-manager"

min_width=250
max_width=300

mapfile -t domains < <(grep '[^[:space:]]' "$file" 2>/dev/null | sort -u)
assets="${#domains[@]}"

if [[ "$assets" -eq 0 ]]; then
    exit 0
fi

max=$(printf '%s\n' "${domains[@]}" | awk 'length > max { max = length } END { print max }')
width=$(( max * 14 ))

if [[ "$width" -lt "$min_width" ]]; then
    width="$min_width"
fi

if [[ "$width" -gt "$max_width" ]]; then
    width="$max_width"
fi

selection=$(printf '%s\n' "${domains[@]}" | rofi \
  -dmenu \
  -x11 \
  -normal-window \
  -p " " \
  -theme "${dir}/style.rasi" \
  -theme-str "window { width: ${width}px; }"
)

if [[ -n "$selection" ]]; then
    printf '%s' "$selection" | wl-copy
fi
