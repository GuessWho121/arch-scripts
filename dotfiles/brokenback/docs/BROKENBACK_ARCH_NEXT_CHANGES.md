# BrokenBack Arch Next Changes

This file is the living queue for future Arch daily-driver changes that should be planned before implementation. Keep it separate from the changelog: this is for intended work, hardware migration notes, and deferred cleanup.

Last updated: 2026-08-27

## Rules

- Implement one milestone at a time.
- Back up every touched system file before changing it.
- Do not remove `codexsetup` until the Arch install is stable on the intended daily-driver hardware.
- Do not make final-hardware-specific package decisions while the Arch install is still running on the temporary BrokenBack/server laptop.

## Milestone 2 Implemented: BSPWM Daily Desktop Foundation, surface-dots Port, Bar Polish, Type 6 Launcher, Window Count Menu Chip, And Eww Hub

Status:

- Milestone 2 base implemented on 2026-08-06.
- Milestone 2.1 `surface-dots`-inspired bar/hub port implemented on 2026-08-06.
- Milestone 2.2 workspace pill, rounded status pills, Rofi/hub fixes, and Flameshot X11 screenshot fix implemented on 2026-08-06.
- Milestone 2.3 Type 6 Rofi launcher, Picom blur, larger hub button, and media-only center behavior implemented on 2026-08-06.
- Milestone 2.4 window-count/menu chip, larger bar icons, compact Type 6 launcher, and hub updates row implemented on 2026-08-06.
- Milestone 2.5 left bar overflow fix and Eww top-right control hub implemented on 2026-08-06.
- Milestone 2.6 Eww control settings/calendar split hubs, backlight permissions, workspaces spacing and rounded outline highlights, last-played persistent media status, and Rofi height/Picom blur alignment fixes implemented on 2026-08-06.
- Milestone 2.7 hub right-edge fix, true Eww-owned rounded workspace pill, safe reload-only installer behavior, persistent Windows SSH alias, and directory permission repair implemented on 2026-08-26.
- Milestone 2.8 hub readability, unquoted Eww workspace markup, stronger Alacritty blur, and equal Type 6 Rofi mode tabs implemented on 2026-08-26.
- Milestone 2.9 Rofi full-background blur overlay and stable Type 6 filebrowser shape implemented on 2026-08-26.
- Milestone 2.10 Polybar default workspace dots and Eww workspace-strip removal implemented on 2026-08-27.
- Milestone 2.10.1 Polybar workspace icon detection and left pill width nudge implemented on 2026-08-27.
- Milestone 2.10.2 Polybar pill borders and extra left workspace breathing room implemented on 2026-08-27.
- Milestone 2.10.3 Polybar workspace right-edge spacing fix implemented on 2026-08-27.
- Milestone 2.10.4 main Control Hub header/action-row cleanup implemented on 2026-08-27.
- Milestone 2.10.5 main Control Hub icon-only action tiles implemented on 2026-08-27.
- See `BROKENBACK_ARCH_CHANGELOG.md` for the detailed implementation record.
- Keep backups under `/var/backups/codex/` until visual acceptance of Milestone 2 through 2.10.5.

User-side acceptance still needed:

- Confirm the left workspace pill is back in Polybar and shows app-aware dots/icons.
- Confirm the active workspace is only an accent dot/icon, with no rounded/pill highlight.
- Confirm the left workspace pill width feels balanced and no dot clips.
- Confirm the rounded Polybar pills have a visible border.
- Confirm the main Control Hub top row only has lock, power, and close.
- Confirm Screenshot and Stats buttons sit cleanly between the sliders and Updates row.
- Confirm Screenshot and Stats are icon-only square tiles aligned beside Notify.
- Confirm top hub action icons are large enough.
- Confirm center bar shows the last played track prefixed with stopped `` icon when the player is off.
- Confirm Combined datetime pill displays date and time nicely. Clicking it opens/closes the new Calendar Hub.
- Confirm Renamed `windowcount` pill has a peach background. Clicking it opens/closes the Control settings Hub.
- Confirm Eww Control settings Hub layout matches the reference styling (avatar image, lock and power buttons, 4 quick toggles Wi-Fi/SSID, Bluetooth/status, Performance, DND, volume/brightness sliders, Updates count in bold).
- Confirm Control Hub and Calendar Hub text/icons are readable at normal viewing distance.
- Confirm the longer volume and brightness sliders use the hub height cleanly without leaving awkward empty space.
- Confirm volume and brightness sliders actually change the system volume and screen brightness.
- Confirm clicking outside either active hub successfully closes it.
- Confirm both the Control Hub and Calendar Hub stay fully inside the right screen edge.
- Confirm Eww Calendar Hub renders calendar grid, weather details (Nerd Font icon + temp + condition description), and upcoming event lists.
- Confirm Rofi launcher opens, has centered button labels of identical height, and Picom dual-kawase background blur is active.
- Confirm the Rofi Type 6 `FILES` tab is the same visual size as the other mode tabs.
- Confirm switching to the Rofi Type 6 `FILES` mode no longer changes the launcher card shape.
- Confirm the whole desktop behind Rofi blurs/dims while the compact centered launcher is open.
- Confirm Alacritty background blur/transparency is now visible while keeping terminal text readable.
- Confirm required keybinds feel correct.
- Confirm screenshot keys work without timeout.
- Confirm the installer/reload flow no longer logs out the active LightDM/BSPWM session.


## Future Hub Refinement Candidate

Recommended goal:

- Refine the new Eww hub only after the first visual pass is accepted.
- Keep the fallback Rofi hub available, but do not use it as the primary entrypoint.
- Preserve current keybinds and the peach window-count/menu chip as the hub entry point.

Current state:

- Eww is now installed and provides real volume/brightness sliders.
- Polybar owns the full top bar again: left app-aware workspace dots/icons, center media, and right status pills.
- Eww owns the Control Hub, Calendar Hub, and temporary Rofi blur layer only.
- Package updates are read-only in the hub.
- The old Rofi hub remains only as a fallback action menu.

Possible refinements:

- Better slider layout after physical-screen review if the Milestone 2.8 sizing still feels too large or too tight.
- Mute state and microphone controls.
- More detailed Bluetooth paired-device state.
- A richer media card if top-bar media text is not enough.
- Optional click-outside-to-close behavior if the manual toggle feels clunky.

## Milestone 3 Candidate: Daily Apps And Visual Refinement

Recommended goal:

- Keep the Milestone 2/Milestone 2.1/Milestone 2.2/Milestone 2.3/Milestone 2.4/Milestone 2.5/Milestone 2.6/Milestone 2.7/Milestone 2.8/Milestone 2.9/Milestone 2.10/Milestone 2.10.1/Milestone 2.10.2/Milestone 2.10.3/Milestone 2.10.4/Milestone 2.10.5 BSPWM base stable.
- Install and theme the actual daily apps only after the shell feels right.
- Decide which app set should be part of the cloned daily-driver image and which should wait until final hardware.

Possible scope:

- Browser setup and default browser choice.
- Editor/dev app defaults outside containers.
- Terminal/Ranger preview refinements after real use.
- Better Eww hub/submenus if the new hub feels too plain or too crowded.
- Optional larger media widget only if the top-bar media text is not enough.
- Wallpaper set rotation or curated wallpaper pack.
- App-specific GTK/Qt theme fixes discovered during use.
- Backup review and cleanup after Milestone 2 through Milestone 2.10.5 visual acceptance.

## Startup Polish Follow-Up

Status:

- A video from 2026-08-05 16:03:55 showed:
  - boot/initramfs text near the start,
  - a long dark section,
  - wallpaper visible around `00:45-00:49`,
  - a black WebKit greeter window with pointer around `00:50-00:55`,
  - full greeter visible around `00:56`.
- The root cause is the cold startup cost of `lightdm-webkit2-greeter`/WebKit plus external USB HDD boot latency.
- A first-paint patch has been applied to inline the greeter wallpaper/loading layer directly in `index.html`.
- The previous LightDM `display-setup-script` wallpaper hook has been commented out to avoid the wallpaper-to-black flash.

Next verification:

- Reboot visually and confirm whether the black pointer gap is reduced or at least no longer flashes from wallpaper to black.
- If it still feels bad, decide between:
  - keeping WebKit for custom rice and accepting a small cold-start delay, or
  - switching to a faster native greeter such as GTK/Slick and sacrificing the custom HTML/CSS login surface.

## Fingerprint Implementation

Goal:

- Add fingerprint login/unlock only after the login greeter and lock flow are otherwise stable.

Planned discovery:

- Identify the fingerprint reader:
  - `lsusb`
  - `lspci`
  - `fprintd-list-devices`
- Check whether the reader is supported by the installed `libfprint` version.
- Confirm whether the final intended hardware has the same reader as the temporary BrokenBack/server laptop.

Likely packages:

- `fprintd`
- `libfprint`
- `pam_fprintd`

Planned integration:

- Enroll the main user:
  - `fprintd-enroll guesswho`
- Test verification:
  - `fprintd-verify guesswho`
- Add PAM fingerprint auth carefully:
  - LightDM login after password flow is stable.
  - Lock screen only after login test passes.
  - Sudo/polkit only if explicitly wanted later.

Rollback requirement:

- Back up every touched PAM file before enabling fingerprint auth.
- Keep password login available at all times.
- Never make fingerprint the only unlock path.

## OLED Display Care And Burn-In Mitigation

Goal:

- If the final daily-driver hardware has an OLED panel, make the rice OLED-aware before locking in static bars, lock screens, wallpapers, or always-on UI elements.
- Reduce burn-in risk without making the desktop annoying to use.

Important:

- Do not finalize OLED-specific behavior while the Arch install is still running on the temporary BrokenBack/server laptop.
- First confirm whether the final Windows PC/laptop display is OLED, mini-LED, IPS, or external-monitor based.
- OLED care should influence Milestone 2 visual choices, especially the bar, lockscreen, panel transparency, wallpaper brightness, and idle behavior.

Planned discovery on final hardware:

- Identify display stack and outputs:
  - `xrandr --verbose`
  - `xset q`
  - `loginctl show-session "$XDG_SESSION_ID"`
- Check brightness/backlight interfaces:
  - `ls /sys/class/backlight`
  - `brightnessctl --list`
- If external monitors are used, check DDC/CI support:
  - `ddcutil detect`

Libraries/tools to evaluate:

- `brightnessctl` for laptop panel brightness controls.
- `xorg-xrandr` for display geometry/output state and possible small-position/panning experiments.
- `xorg-xset` for DPMS and blanking policy.
- `xidlehook` or `xautolock` for idle actions if `xss-lock` alone is not flexible enough.
- `xss-lock` for session lock integration.
- `picom` for opacity/fade behavior.
- `feh` or a wallpaper helper for rotating/dimming wallpapers.
- `gammastep` for color temperature and optional night dimming.
- `ddcutil` for external OLED monitor brightness where supported.
- A small custom `brokenback-oled-guard` script/service if existing tools do not provide the exact pixel-shift/bar-shift behavior we want.

OLED protection ideas:

- Pixel shift:
  - periodically move static UI by a tiny offset,
  - prefer shifting bars/panels/wallpaper layers over shifting the whole X screen if whole-screen shifting causes cursor or window placement weirdness,
  - test carefully with BSPWM gaps and monitors before enabling by default.
- Bar burn-in reduction:
  - avoid a permanently bright fixed bar,
  - consider auto-hide, translucent, or periodic side/top/bottom movement,
  - avoid static pure-white icons/text in the same pixels all day.
- Lockscreen care:
  - avoid a high-contrast static lockscreen left on for long periods,
  - blank or dim the display after a short locked idle delay,
  - keep the clock/hint subtle.
- Wallpaper care:
  - avoid very bright static wallpaper regions under the same UI,
  - optionally rotate wallpapers or shift/crop position over time.
- Browser/app care:
  - prefer dark GTK/Qt/browser themes,
  - avoid full-bright static maximized windows for long unattended periods.
- Idle behavior:
  - dim first,
  - lock next,
  - blank/off display after a short delay,
  - never rely on a visible static screensaver as the main OLED protection.

Planned implementation style:

- Keep OLED settings user-visible and easy to disable.
- Use systemd user services/timers for any periodic helper.
- Log helper actions lightly for debugging.
- Back up BSPWM, SXHKD, Picom, Polybar/bar, lock, and idle configs before changes.

Rollback requirement:

- Keep one command or config flag to disable OLED shifting/dimming if it causes display glitches.
- Do not enable aggressive brightness or DPMS behavior until tested on the final hardware.

## Final-Hardware Microcode Cleanup

Goal:

- Install only the CPU microcode needed for the final daily-driver hardware, not merely the temporary hardware currently booting this Arch install.

Important:

- Do not finalize microcode packages until the Arch install is booted on the intended Windows PC/laptop or the final CPU vendor is confirmed.
- Current BrokenBack/server laptop appears to be Intel-based, but that should not decide the final install.

Final-hardware discovery:

- On the final machine, check:
  - `lscpu | grep -E 'Vendor ID|Model name'`
  - `grep -m1 vendor_id /proc/cpuinfo`
- If checking from Windows before migration, note the exact CPU model from Task Manager, Device Manager, BIOS, or `wmic cpu get name`.

Package rule:

- Intel CPU:
  - install/keep `intel-ucode`
  - remove `amd-ucode` if present
- AMD CPU:
  - install/keep `amd-ucode`
  - remove `intel-ucode` if present

Bootloader rule:

- Ensure GRUB loads only the matching microcode image:
  - Intel: `/intel-ucode.img`
  - AMD: `/amd-ucode.img`
- Do not duplicate microcode in both GRUB and the mkinitcpio `microcode` hook.
- Current preferred setup is GRUB microcode image plus no `microcode` hook in `mkinitcpio.conf`, because it keeps the initramfs smaller.

Cleanup steps after final hardware is known:

- Install the matching microcode package.
- Remove the nonmatching microcode package.
- Confirm `/boot` is mounted or automounted before package changes.
- Regenerate GRUB config:
  - `sudo grub-mkconfig -o /boot/grub/grub.cfg`
- Rebuild initramfs:
  - `sudo mkinitcpio -P`
- Verify rescue entry still exists until several successful boots.

## Deferred Cleanup

- Milestone 1 has been accepted, and the approved remote cleanup was completed on 2026-08-05.
- Safe local workspace cleanup already completed:
  - removed `tools/ffmpeg/download`,
  - removed `tools/ffmpeg/extract`,
  - removed `video-analysis`,
  - kept `tools/ffmpeg/bin/ffmpeg.exe` and `tools/ffmpeg/bin/ffprobe.exe`.
- Remote cleanup completed:
  - removed old backup directories under `/var/backups/codex/arch-*`,
  - removed the old `greetd`/`regreet` stack,
  - removed orphaned dependencies from that old greeter stack,
  - removed temporary rescue initramfs images,
  - removed the obsolete GRUB rescue entry and regenerated `/boot/grub/grub.cfg`,
  - removed inactive `/usr/local/bin/brokenback-lightdm-display-setup`,
  - cleaned old pacman package cache entries and stale `download-*` temp directories.
- Future cleanup:
  - keep `codexsetup` until the install is stable on the final hardware,
  - keep final-hardware microcode cleanup deferred until the final CPU vendor is known,
  - review package cache again after large package installs in later milestones.
