#!/bin/bash

cache="/home/justice-reaper/.config/rofi/filters/desktop-cache.txt"

: > "$cache"

find /usr/share/applications /home/justice-reaper/.local/share/applications -maxdepth 1 -name '*.desktop' 2>/dev/null | while IFS= read -r file; do
    name=$(grep -m1 '^Name=' "$file" | cut -d'=' -f2-)
    icon=$(grep -m1 '^Icon=' "$file" | cut -d'=' -f2-)
    wmclass=$(grep -m1 '^StartupWMClass=' "$file" | cut -d= -f2-)
    stem=$(basename "$file" .desktop)

    if [ -z "$name" ]; then continue; fi

    if [ -n "$wmclass" ]; then
        echo "${wmclass,,}|${name}|${icon}" >> "$cache"
    fi
    echo "${stem,,}|${name}|${icon}" >> "$cache"
done

sort -u -o "$cache" "$cache"
