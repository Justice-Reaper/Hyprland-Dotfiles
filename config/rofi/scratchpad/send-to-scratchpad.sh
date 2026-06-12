#!/bin/bash

addr=$(hyprctl activewindow -j | jq -r '.address')
if [ -z "$addr" ] || [ "$addr" = "null" ]; then exit 0; fi
hyprctl eval "hl.dispatch(hl.dsp.window.move({workspace = 'special:${addr}', follow = false}))"
