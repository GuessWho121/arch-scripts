#!/usr/bin/env bash
set -euo pipefail

export HOME=/home/guesswho
export USER=guesswho
export DISPLAY=:0
export XDG_RUNTIME_DIR=/run/user/1000
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

config=/home/guesswho/.config/eww/brokenback-hub

runuser -u guesswho -- env \
  HOME="$HOME" \
  USER="$USER" \
  DISPLAY="$DISPLAY" \
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  /home/guesswho/.local/bin/brokenback-rofi-launcher filebrowser \
  >/tmp/brokenback-rofi-live.out 2>/tmp/brokenback-rofi-live.err &

launcher_pid=$!
sleep 1

echo after-open
runuser -u guesswho -- env \
  HOME="$HOME" \
  USER="$USER" \
  DISPLAY="$DISPLAY" \
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  eww --config "$config" active-windows
pgrep -a rofi || true

pkill -x rofi || true
wait "$launcher_pid" 2>/dev/null || true
sleep 1

runuser -u guesswho -- env \
  HOME="$HOME" \
  USER="$USER" \
  DISPLAY="$DISPLAY" \
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  eww --config "$config" close brokenback_rofi_blur >/dev/null 2>&1 || true

echo after-close
runuser -u guesswho -- env \
  HOME="$HOME" \
  USER="$USER" \
  DISPLAY="$DISPLAY" \
  XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
  DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
  eww --config "$config" active-windows

if [ -s /tmp/brokenback-rofi-live.err ]; then
  echo rofi-stderr
  cat /tmp/brokenback-rofi-live.err
fi
