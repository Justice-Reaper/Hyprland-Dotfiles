#!/usr/bin/env bash

touchpad_enabled=""

get_touchpad() {
    hyprctl devices -j | jq -r '.mice[] | select(.name | test("touchpad")) | .name' | head -1
}

has_external_mouse() {
    local tp_prefix="${1%-touchpad}"
    hyprctl devices -j | jq -e --arg prefix "$tp_prefix" '.mice[] | select(.name | test("touchpad|keyboard") | not) | select(.name | startswith($prefix) | not)' &>/dev/null
}

set_touchpad() {
    local touchpad="$1"
    local enable="$2"

    if [[ "$enable" == "$touchpad_enabled" ]]; then
        return
    fi

    hyprctl eval "hl.device({name='$touchpad', enabled=$enable})"
    touchpad_enabled="$enable"
}

check_mouse() {
    local touchpad
    touchpad=$(get_touchpad)

    if [[ -z "$touchpad" ]]; then
        return
    fi

    if has_external_mouse "$touchpad"; then
        set_touchpad "$touchpad" false
    else
        set_touchpad "$touchpad" true
    fi
}

check_mouse

udevadm monitor --subsystem-match=input --udev | while read -r line; do
    if [[ "$line" == *add* || "$line" == *remove* ]]; then
        check_mouse
    fi
done
