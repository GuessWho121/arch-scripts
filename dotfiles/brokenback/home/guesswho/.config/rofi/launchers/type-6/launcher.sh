#!/usr/bin/env sh
set -eu

mode="${1:-drun}"
dir="${HOME}/.config/rofi/launchers/type-6"
theme="${dir}/style-brokenback.rasi"
eww_config="${HOME}/.config/eww/brokenback-hub"

case "$mode" in
  drun|run|filebrowser|window) ;;
  *) mode="drun" ;;
esac

close_blur() {
  if command -v eww >/dev/null 2>&1; then
    eww --config "$eww_config" close brokenback_rofi_blur >/dev/null 2>&1 || true
  fi
}

open_blur() {
  command -v eww >/dev/null 2>&1 || return 0
  [ -d "$eww_config" ] || return 0

  "${HOME}/.local/bin/brokenback-eww-daemon" "$eww_config" >/dev/null 2>&1 || return 0

  timeout 2s eww --config "$eww_config" close brokenback_hub brokenback_hub_background brokenback_calendar_hub brokenback_calendar_background >/dev/null 2>&1 || true
  timeout 3s eww --config "$eww_config" open brokenback_rofi_blur >/dev/null 2>&1 || true
  sleep 0.08
}

trap close_blur EXIT INT TERM
open_blur
rofi -show "$mode" -theme "$theme"
