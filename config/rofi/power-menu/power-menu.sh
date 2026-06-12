#!/bin/bash

dir="/home/justice-reaper/.config/rofi/power-menu"
shutdown='Shutdown'
reboot='Reboot'
lock='Lock'
suspend='Suspend'
logout='Logout'

rofi_cmd() {
    rofi -dmenu \
        -x11 \
        -normal-window \
        -theme "${dir}/style.rasi"
}

run_rofi() {
    echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

chosen="$(run_rofi)"

case ${chosen} in
    $shutdown)
        loginctl poweroff
        ;;
    $reboot)
        loginctl reboot
        ;;
    $lock)
        swaylock
        ;;
    $suspend)
        loginctl suspend
        ;;
    $logout)
        hyprctl dispatch 'hl.dsp.exit()'
        ;;
esac
