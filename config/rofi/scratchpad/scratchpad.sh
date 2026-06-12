#!/bin/bash

dir="/home/justice-reaper/.config/rofi/scratchpad"
cache="/home/justice-reaper/.config/rofi/filters/desktop-cache.txt"

if [ ! -f "$cache" ]; then
    /home/justice-reaper/.config/rofi/filters/desktop-cache.sh
fi

find_desktop() {
    local class="${1,,}" pid="$2" line=""

    line=$(grep -m1 "^${class}|" "$cache")

    if [ -z "$line" ]; then
        local prefix="${class%%[^[:alnum:]]*}"
        if [ -n "$prefix" ]; then
            line=$(grep -m1 "^${prefix}" "$cache")
        fi
    fi

    if [ -z "$line" ] && [ -n "$pid" ]; then
        for word in $(ps -o args= -p "$pid" 2>/dev/null); do
            if [[ "$word" == -* ]] || [[ "$word" == python* ]] || [[ "$word" == java* ]]; then continue; fi
            local base="${word%%_*}"
            base="${base,,}"
            if [ -n "$base" ]; then
                line=$(grep -m1 "${base}" "$cache")
                if [ -n "$line" ]; then break; fi
            fi
        done
    fi

    echo "$line"
}

mapfile -t windows < <(hyprctl clients -j | jq -r '.[] | select(.workspace.name | startswith("special")) | "\(.address)|\(.class)|\(.pid)"')

if [ ${#windows[@]} -eq 0 ]; then exit 0; fi

display=""
for w in "${windows[@]}"; do
    class=$(echo "$w" | cut -d'|' -f2)
    pid=$(echo "$w" | cut -d'|' -f3)
    info=$(find_desktop "$class" "$pid")

    if [ -n "$info" ]; then
        name=$(echo "$info" | cut -d'|' -f2)
        icon=$(echo "$info" | cut -d'|' -f3)
    else
        name="${class^}"
        icon="${class,,}"
    fi

    display+="${name}\0icon\x1f${icon}\n"
done

index=$(echo -en "$display" | rofi -dmenu -format i -x11 -normal-window -theme "${dir}/style.rasi" -p "Scratchpad")
code=$?

if [ -z "$index" ] || [ "$index" = "-1" ]; then exit 0; fi

addr=$(echo "${windows[$index]}" | cut -d'|' -f1)
current_ws=$(hyprctl activeworkspace -j | jq -r '.id')

case $code in
    0)
        hyprctl eval "hl.config({ cursor = { no_warps = true } })"
        hyprctl eval "hl.dispatch(hl.dsp.workspace.toggle_special({name = '${addr}'}))"
        hyprctl eval "hl.dispatch(hl.dsp.focus({window = 'address:${addr}'}))"
        hyprctl eval "hl.dispatch(hl.dsp.window.move({workspace = '${current_ws}'}))"
        hyprctl eval "hl.config({ cursor = { no_warps = false } })"
        ;;
    10)
        hyprctl eval "hl.dispatch(hl.dsp.window.close({window = 'address:${addr}'}))"
        ;;
esac
