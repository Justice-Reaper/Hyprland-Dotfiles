#!/bin/bash

dir="/home/justice-reaper/.config/rofi/tray"
cache="/home/justice-reaper/.config/rofi/filters/desktop-cache.txt"

if [ ! -f "$cache" ]; then
    /home/justice-reaper/.config/rofi/filters/desktop-cache.sh
fi

find_desktop() {
    local id="${1,,}" line=""

    line=$(grep -m1 "^${id}|" "$cache")

    if [ -z "$line" ]; then
        local prefix="${id%%[^[:alnum:]]*}"
        if [ -n "$prefix" ]; then
            line=$(grep -m1 "^${prefix}" "$cache")
        fi
    fi

    echo "$line"
}

items_raw=$(gdbus call --session \
    --dest=org.kde.StatusNotifierWatcher \
    --object-path=/StatusNotifierWatcher \
    --method=org.freedesktop.DBus.Properties.Get \
    "org.kde.StatusNotifierWatcher" "RegisteredStatusNotifierItems" 2>/dev/null)

mapfile -t items < <(echo "$items_raw" | grep -oP "'[^']+'" | tr -d "'")

if [ ${#items[@]} -eq 0 ]; then exit 0; fi

buses=()
paths=()
display=""

for item in "${items[@]}"; do
    bus="${item%%/*}"
    path="/${item#*/}"

    props=$(gdbus call --session --dest="$bus" --object-path="$path" \
        --method=org.freedesktop.DBus.Properties.GetAll \
        "org.kde.StatusNotifierItem" 2>/dev/null)

    title=$(echo "$props" | grep -oP "'Title': <'[^']*'>" | grep -oP "(?<=<')[^']*")
    id=$(echo "$props" | grep -oP "'Id': <'[^']*'>" | grep -oP "(?<=<')[^']*")

    if [ -z "$title" ]; then title="$id"; fi

    info=$(find_desktop "$id")
    if [ -n "$info" ]; then
        name=$(echo "$info" | cut -d'|' -f2)
        icon=$(echo "$info" | cut -d'|' -f3)
    else
        name="${title^}"
        icon="${id,,}"
    fi

    buses+=("$bus")
    paths+=("$path")
    display+="${name}\0icon\x1f${icon}\n"
done

index=$(echo -en "$display" | rofi -dmenu -format i -x11 -normal-window -theme "${dir}/style.rasi" -p "Tray")
code=$?

if [ -z "$index" ] || [ "$index" = "-1" ]; then exit 0; fi

bus="${buses[$index]}"
path="${paths[$index]}"

case $code in
    0)
        gdbus call --session --dest="$bus" --object-path="$path" \
            --method=org.kde.StatusNotifierItem.Activate 0 0 > /dev/null 2>&1
        ;;
    10)
        gdbus call --session --dest="$bus" --object-path="$path" \
            --method=org.kde.StatusNotifierItem.SecondaryActivate 0 0 > /dev/null 2>&1
        ;;
esac
