#!/bin/sh
# Toggle a floating kitty running a TUI app: popup.sh <name> <command...>
# Clicking the bar module again closes it. Floating/size rules for the
# "popup-*" window class live in ~/.config/hypr/hyprland.conf.
name="$1"; shift
class="popup-$name"
pkill -f "kitty --class $class" || exec kitty --class "$class" "$@"
