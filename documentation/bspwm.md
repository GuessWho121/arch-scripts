# BSPWM After-Install Guide

A beginner-friendly guide for running `arch-bspwm.sh` after the base Arch install is complete.

This guide covers:

- When to run the BSPWM setup script
- Required base system state
- What the script installs
- Hardware detection behavior
- `greetd` and `tuigreet` login setup
- Checkpoints, resume, and restore
- Cleanup and post-install checks

The `arch-bspwm.sh` script handles the desktop setup:

- Minimal X11 and BSPWM desktop
- `greetd` with `tuigreet` as a lightweight console display manager
- `yay` AUR helper
- GPU package detection for Intel, AMD, and NVIDIA
- PipeWire audio with `pulsemixer`
- Bluetooth packages and service enablement
- Firefox
- Alacritty, rofi, dunst, polybar, picom, feh, and xclip
- Minimal launch/session files only

---

## When To Run This Script

Run this script after:

- `arch-initialize.sh` has completed
- You exited chroot
- You unmounted `/mnt`
- You rebooted into the installed Arch system
- You logged in as your normal user

Do not run this script inside `arch-chroot`.

Do not run this script as root.

Run it as the normal user created by `arch-initialize.sh`.

---

## Requirements

Before running the script, your system should already have:

- A working Arch installation
- A normal user account
- Working `sudo`
- Working internet access
- NetworkManager enabled from the initialization script
- Git available, if cloning the repository after boot

Check internet access:

```bash
ping archlinux.org
```

Check sudo access:

```bash
sudo -v
```

If Wi-Fi is not connected yet, use:

```bash
nmtui
```

or:

```bash
nmcli device wifi list
nmcli device wifi connect WIFI_NAME password WIFI_PASSWORD
```

---

## Download The Script

Clone the repository:

```bash
git clone https://github.com/GuessWho121/arch-scripts.git
cd arch-scripts
```

Make the script executable:

```bash
chmod +x arch-bspwm.sh
```

Run it as your normal user:

```bash
./arch-bspwm.sh
```

---

## What Gets Installed

### X11

The script installs only the required X11 packages:

```text
xorg-server
xorg-xinit
```

It does not install the full `xorg` group.

### BSPWM Desktop

```text
bspwm
sxhkd
polybar
picom
```

### Login Manager

```text
greetd
greetd-tuigreet
```

The script uses `tuigreet` to launch `startx`, and `startx` launches BSPWM through `~/.xinitrc`.

### Desktop Tools

```text
alacritty
rofi
dunst
feh
xclip
firefox
unzip
xdg-user-dirs
```

### Audio

```text
pipewire
pipewire-pulse
pipewire-alsa
wireplumber
pulsemixer
```

`pulsemixer` is the simple terminal audio mixer.

### Bluetooth

```text
bluez
bluez-utils
```

The script enables and starts:

```text
bluetooth.service
```

### Font

```text
ttf-profont-nerd
```

### AUR Helper

The script builds and installs standard `yay` from the AUR as your normal user.

---

## Hardware Detection

Before installing desktop packages, the script detects and prints:

- Current user
- Home directory
- CPU
- Detected GPUs
- Battery presence
- Bluetooth adapter presence
- Network reachability

For GPUs, it checks all detected graphics devices and installs packages for every matching vendor.

### Intel GPU

```text
mesa
vulkan-intel
intel-media-driver
```

### AMD GPU

```text
mesa
vulkan-radeon
```

### NVIDIA GPU

```text
nvidia
```

Hybrid GPU systems are supported. For example, if both Intel and NVIDIA GPUs are detected, the script installs both Intel and NVIDIA package sets.

---

## Script Phases

The script uses five phases:

```text
phase1 - preflight, sudo check, hardware and system detection
phase2 - install and build yay
phase3 - install desktop, GPU, audio, Bluetooth, browser, and font packages
phase4 - enable services and run user setup commands
phase5 - write minimal launch and session files
```

Checkpoint state is stored at:

```bash
/var/lib/arch-bspwm
```

Backups are stored at:

```bash
/var/lib/arch-bspwm/backups
```

Temporary build files are stored at:

```bash
/tmp/arch-bspwm
```

---

## Files The Script May Edit

The script only writes minimal launch/session files:

```text
/etc/greetd/config.toml
~/.xinitrc
~/.config/bspwm/bspwmrc
~/.config/sxhkd/sxhkdrc
```

These files are backed up before phase5 edits them.

The script does not install styled dotfiles, themes, wallpapers, or rice configs.

---

## Minimal Keybindings

The generated `sxhkd` config includes only essential bindings:

| Keybinding | Action |
|---|---|
| `Super + Enter` | Open Alacritty |
| `Super + d` | Open rofi |
| `Super + Shift + q` | Close focused window |
| `Super + Escape` | Reload sxhkd |
| `Super + Alt + r` | Restart BSPWM |
| `Super + Alt + q` | Quit BSPWM |

---

## Resume Or Restore

If the script stops or the system loses power, run:

```bash
./arch-bspwm.sh --resume
```

To restore files backed up for a phase:

```bash
./arch-bspwm.sh --restore phase5
```

Valid phases are:

```text
phase1 phase2 phase3 phase4 phase5
```

`--restore phase5` is the most useful restore option because phase5 owns the desktop/session config files.

---

## Cleanup

At the end, the script asks before removing:

- `/var/lib/arch-bspwm` state and backups
- `/tmp/arch-bspwm` temporary build/download directory
- The installer script file itself, `arch-bspwm.sh`

The cleanup does not remove:

- User configs outside the files listed above
- Installed packages
- Home directory files
- Unrelated system files

---

## Reboot

After the script completes, reboot:

```bash
sudo reboot
```

After reboot, `tuigreet` should appear.

Log in as your normal user. The session should start BSPWM through X11.

---

## Post-Install Checks

Check display manager:

```bash
systemctl status greetd.service
```

Check PipeWire:

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
```

Open the audio mixer:

```bash
pulsemixer
```

Check Bluetooth:

```bash
systemctl status bluetooth.service
bluetoothctl
```

Check `yay`:

```bash
yay --version
```

Check the session files:

```bash
cat ~/.xinitrc
cat ~/.config/bspwm/bspwmrc
cat ~/.config/sxhkd/sxhkdrc
```

---

## What This Script Does Not Install

This script intentionally does not install:

- Full `xorg` group
- File manager
- Screenshot tool
- Lock screen
- GTK theme
- Polkit agent
- NetworkManager tray applet
- `pavucontrol`
- Emoji font pack
- Noto or DejaVu font pack unless pulled as dependencies
- `p7zip`
- `unrar`
- SSH service enablement
- Firefox custom config
- Wallpaper config
- Styled dotfiles
- Visual rice

Those can be handled later by a separate config script.

---

## Troubleshooting

### `tuigreet` Opens But BSPWM Does Not Start

Check `~/.xinitrc`:

```bash
cat ~/.xinitrc
```

It should contain:

```bash
exec bspwm
```

Check that BSPWM is installed:

```bash
pacman -Q bspwm
```

### No Terminal Opens

Try the keybinding:

```text
Super + Enter
```

If it does not work, check that `sxhkd` is running:

```bash
pgrep -a sxhkd
```

Check the config:

```bash
cat ~/.config/sxhkd/sxhkdrc
```

### No Audio

Check user services:

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
```

Try restarting them:

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
```

Open:

```bash
pulsemixer
```

### Bluetooth Not Working

Check service status:

```bash
systemctl status bluetooth.service
```

Start the Bluetooth tool:

```bash
bluetoothctl
```

Inside `bluetoothctl`:

```bash
power on
agent on
default-agent
scan on
```

---

## License

MIT
