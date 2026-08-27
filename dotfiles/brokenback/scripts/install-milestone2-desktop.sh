#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  exec sudo bash "$0" "$@"
fi

payload_dir="${1:-$(cd "$(dirname "$0")/payload" && pwd)}"
user_name="guesswho"
user_home="/home/${user_name}"
user_group="$(id -gn "$user_name")"
user_uid="$(id -u "$user_name")"

if [ ! -d "$payload_dir/home/guesswho" ]; then
  echo "Payload not found: $payload_dir/home/guesswho" >&2
  exit 1
fi

install -d -o "$user_name" -g "$user_group" -m 0755 "$user_home/.config"
install -d -o "$user_name" -g "$user_group" -m 0755 "$user_home/.local/bin"

cp -a "$payload_dir/home/guesswho/.config/." "$user_home/.config/"
cp -a "$payload_dir/home/guesswho/.local/." "$user_home/.local/"

chown -R "$user_name:$user_group" \
  "$user_home/.config" \
  "$user_home/.local" \
  "$user_home/.config/bspwm" \
  "$user_home/.config/sxhkd" \
  "$user_home/.config/polybar" \
  "$user_home/.config/picom" \
  "$user_home/.config/dunst" \
  "$user_home/.config/alacritty" \
  "$user_home/.config/rofi" \
  "$user_home/.config/eww" \
  "$user_home/.config/flameshot" \
  "$user_home/.config/ranger" \
  "$user_home/.config/gtk-3.0" \
  "$user_home/.config/gtk-4.0" \
  "$user_home/.config/qt5ct" \
  "$user_home/.config/qt6ct" \
  "$user_home/.config/Kvantum" \
  "$user_home/.config/starship.toml" \
  "$user_home/.local/bin"

chmod 0755 "$user_home/.config" "$user_home/.local" "$user_home/.local/bin"
find \
  "$user_home/.config/bspwm" \
  "$user_home/.config/sxhkd" \
  "$user_home/.config/polybar" \
  "$user_home/.config/picom" \
  "$user_home/.config/dunst" \
  "$user_home/.config/alacritty" \
  "$user_home/.config/rofi" \
  "$user_home/.config/eww" \
  "$user_home/.config/flameshot" \
  "$user_home/.config/ranger" \
  "$user_home/.config/gtk-3.0" \
  "$user_home/.config/gtk-4.0" \
  "$user_home/.config/qt5ct" \
  "$user_home/.config/qt6ct" \
  "$user_home/.config/Kvantum" \
  -type d -exec chmod 0755 {} +

chmod 0755 "$user_home/.config/bspwm/bspwmrc"
chmod 0644 "$user_home/.config/sxhkd/sxhkdrc"
chmod 0644 "$user_home/.config/polybar/config.ini"
chmod 0644 "$user_home/.config/picom/picom.conf"
chmod 0644 "$user_home/.config/dunst/dunstrc"
chmod 0644 "$user_home/.config/alacritty/alacritty.toml"
chmod 0644 "$user_home/.config/rofi/config.rasi"
if [ -d "$user_home/.config/rofi/launchers/type-6" ]; then
  chmod 0755 "$user_home/.config/rofi/launchers/type-6/launcher.sh"
  chmod 0644 "$user_home/.config/rofi/launchers/type-6"/*.rasi
fi
if [ -d "$user_home/.config/eww/brokenback-hub" ]; then
  find "$user_home/.config/eww/brokenback-hub" -type d -exec chmod 0755 {} +
  find "$user_home/.config/eww/brokenback-hub" -type f -exec chmod 0644 {} +
  chmod 0755 "$user_home/.config/eww/brokenback-hub/scripts"/hub-*
fi
chmod 0644 "$user_home/.config/flameshot/flameshot.ini"
chmod 0644 "$user_home/.config/ranger/rc.conf"
chmod 0755 "$user_home/.config/ranger/scope.sh"
chmod 0755 "$user_home/.local/bin"/brokenback-*

bashrc_tmp="$(mktemp)"
awk '
  /^# >>> brokenback milestone 2$/ { skip = 1; next }
  /^# <<< brokenback milestone 2$/ { skip = 0; next }
  skip != 1 { print }
' "$user_home/.bashrc" > "$bashrc_tmp"
cat >> "$bashrc_tmp" <<'EOF'

# >>> brokenback milestone 2
export PATH="$HOME/.local/bin:$PATH"
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
export CM_LAUNCHER=rofi
export CM_SELECTIONS=clipboard
export CM_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/clipmenu"
export GTK_THEME=Materia-dark
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=kvantum
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi
# <<< brokenback milestone 2
EOF
install -o "$user_name" -g "$user_group" -m 0644 "$bashrc_tmp" "$user_home/.bashrc"
rm -f "$bashrc_tmp"

rm -f "$user_home/EOF"
rm -f "$user_home/.local/bin/brokenback-workspaces-eww-state"
rm -rf "$user_home/.config/autostart.disabled"

install -d -o "$user_name" -g "$user_group" -m 0700 "$user_home/.cache/clipmenu"
if [ -f "$(dirname "$0")/90-backlight.rules" ]; then
  cp "$(dirname "$0")/90-backlight.rules" "/etc/udev/rules.d/"
  udevadm control --reload-rules
  udevadm trigger
  echo "Backlight udev rule installed and reloaded."
fi

echo "Milestone 2 desktop payload installed."

# Reload the active desktop session without restarting LightDM.
if [ -S "/run/user/${user_uid}/bus" ] && [ -x "$user_home/.local/bin/brokenback-desktop-reload" ]; then
  sudo -u "$user_name" env \
    HOME="$user_home" \
    USER="$user_name" \
    DISPLAY=:0 \
    XDG_RUNTIME_DIR="/run/user/${user_uid}" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${user_uid}/bus" \
    "$user_home/.local/bin/brokenback-desktop-reload" || true
  echo "Desktop session reload requested without restarting LightDM."
else
  echo "No active graphical user bus found; desktop reload skipped."
fi
