# BrokenBack Backup Ledger

This file tracks backup directories created during setup so they can be removed later once the system is confirmed stable.

Last updated: 2026-08-27

Milestone 1 status: accepted by the user on 2026-08-05. Remote cleanup was approved and completed on 2026-08-05.
Milestone 2 status: implemented through Milestone 2.10.5 on 2026-08-27; keep its backups until the desktop, bar polish, Type 6 launcher, window-count/menu chip, Eww hubs, visual polish, Rofi blur/shape fixes, Polybar workspace icons/borders, and Control Hub layout are visually accepted after logout/login or reboot.

## Policy

- Keep all future backups until the related milestone has been tested after reboot/logout/login.
- Do not remove backups while `codexsetup` is still needed for recovery.
- Before deleting, inspect with:

```bash
sudo find /var/backups/codex -maxdepth 1 -mindepth 1 -type d -print
```

- Delete only after explicit approval.

## Backup Root

Arch laptop backup root:

```text
/var/backups/codex
```

## Active Milestone 2 Backup Directories

These remote backup directories still exist and should be kept until Milestone 2, its surface-dots-inspired port, the bar polish, the Type 6 launcher, the window-count/menu chip, the Eww hubs, and the Eww workspace pill are accepted.

| Backup path | Created for | Contents / rollback purpose | Keep until |
| --- | --- | --- | --- |
| `/var/backups/codex/arch-milestone2-desktop-20260806-004044` | BSPWM Daily Desktop Foundation | Previous `/home/guesswho/.config/bspwm`, `/home/guesswho/.config/sxhkd`, `/home/guesswho/.config/ranger`, `/home/guesswho/.bashrc`, stale `/home/guesswho/EOF`, and missing-path notes before Milestone 2 configs | Top bar, keybinds, Bluetooth, clipboard, screenshot, terminal, Ranger, theme, and session reload behavior are accepted after logout/login or reboot |
| `/var/backups/codex/arch-milestone2-surface-port-20260806-130453` | surface-dots-inspired Polybar/Rofi/BSPWM port | Previous Milestone 2 desktop configs before the four-segment Polybar layout, surface-style Rofi hub, hub/session menu styling, extra surface-style keybinds, and clipboard guard fix | The surface-inspired bar/hub layout is visually accepted and the desktop still works after logout/login or reboot |
| `/var/backups/codex/arch-milestone2-bar-polish-20260806-134552` | Workspace pill, rounded status pills, Rofi/hub/screenshot fixes | Previous Milestone 2.1 desktop configs before the workspace-only left pill, separate right status pills, far-right hub button, Rofi parse fix, quiet hub cancel, and Flameshot X11 screenshot wrapper | The polished workspace/status bar and screenshot flow are accepted after logout/login or reboot |
| `/var/backups/codex/arch-milestone2-rofi-type6-20260806-143846` | Type 6 Rofi launcher, Picom blur, hub button fix, media-only center | Previous Milestone 2.2 Rofi, Picom, Polybar, SXHKD, and helper scripts before the centered Type 6 launcher, blur config, larger explicit hub button, and media-only center helper | The Type 6 launcher, launcher blur, hub button, and media-only center behavior are accepted after logout/login or reboot |
| `/var/backups/codex/arch-milestone2-window-count-menu-20260806-151956` | Window-count menu chip, larger bar icons, compact Type 6 launcher | Previous Milestone 2.3 Rofi, Polybar, SXHKD, Picom, and helper scripts before the peach chip became global window count, the far-right hub bar was removed, bar glyphs were enlarged, and the launcher was made compact | The window-count/menu chip, no-far-right-hub bar layout, larger icons, compact launcher, and hub update row are accepted after logout/login or reboot |
| `/var/backups/codex/arch-milestone2-eww-hub-20260806-162223` | Bar overflow fix and Eww control hub | Previous Milestone 2.4 Polybar, SXHKD, Eww path if present, hub helpers, package state before Eww, and package state after Eww | The widened workspace pill, Eww top-right hub, sliders, peach-chip entrypoint, and read-only update count are accepted after logout/login or reboot |
| `/var/backups/codex/arch-milestone2-hub-workspace-fix-20260826-172415` | Hub edge fix and true rounded workspace pill | Previous Milestone 2.6 BSPWM, SXHKD, Polybar, Eww, Picom, Dunst, Rofi, helper scripts, failed-unit snapshots, process snapshots, and network state before Eww took ownership of the left workspace pill | The right-edge hub placement, click-outside close behavior, Eww workspace pill, reload-only install path, and directory permissions are accepted after logout/login or reboot |
| `/var/backups/codex/arch-milestone2-visual-polish-20260826-202458` | Hub readability, workspace text fix, and terminal blur | Previous Milestone 2.7 Eww hub config/styles, workspace state helper, Alacritty config, Picom config, and Type 6 Rofi launcher style before larger hub typography, literal workspace markup, stronger terminal blur, and equal launcher mode tabs | The enlarged hubs, unquoted workspace icons, active workspace pill, Alacritty blur, and equal Rofi mode tabs are accepted after logout/login or reboot |
| `/var/backups/codex/arch-milestone2-rofi-blur-shape-20260826-213900` | Rofi full-background blur and stable Type 6 shape | Previous Milestone 2.8 Eww hub config/styles, Type 6 Rofi launcher script/style, and Picom config before the fullscreen Rofi blur layer and fixed launcher heights/listview dynamics | The whole desktop blurs behind compact Rofi, and switching into the `FILES` tab no longer changes the launcher card shape |
| `/var/backups/codex/arch-milestone2-polybar-workspaces-20260827-000412` | Polybar default workspace dots | Previous Milestone 2.9 Polybar/Eww workspace state, including Eww hub config/styles, Polybar launch/config, Eww launch helper, and old Eww workspace state helper before returning workspace dots to Polybar | The left bar shows simple Polybar default-style workspace dots, no rounded active workspace highlight, and Eww still works for hubs/Rofi blur |
| `/var/backups/codex/arch-milestone2-polybar-icons-20260827-003502` | Polybar workspace icons and width nudge | Previous Milestone 2.10 Polybar config, workspace status helper, and Polybar launch helper before restoring app/TUI icon detection and widening the left pill | The left bar shows app-aware Polybar workspace dots/icons, the last item does not clip, and there is no rounded active workspace highlight |
| `/var/backups/codex/arch-milestone2-polybar-border-20260827-010238` | Polybar pill border and workspace breathing room | Previous Milestone 2.10.1 Polybar config and launch helper before adding pill borders and extra left workspace spacing | The last workspace item has breathing room and rounded Polybar pills show a visible border |
| `/var/backups/codex/arch-milestone2-polybar-left-edge-20260827-010731` | Polybar workspace right-edge fix | Previous Milestone 2.10.2 Polybar launch and workspace helper before widening the left pill again and trimming trailing item padding | The final workspace dot/icon stays inside the right edge of the left Polybar pill |
| `/var/backups/codex/arch-milestone2-eww-main-hub-layout-20260827-011608` | Main Hub header and action row cleanup | Previous Milestone 2.10.3 Eww hub layout, Eww styles, and hub action helper before moving Screenshot/Stats into the main body and shrinking header icons | The main Control Hub top row only has lock/power/close, Screenshot and Stats sit between sliders and Updates, and the hub opens cleanly |
| `/var/backups/codex/arch-milestone2-eww-hub-icon-actions-20260827-012606` | Main Hub icon-only action tiles | Previous Milestone 2.10.4 Eww hub layout and styles before moving Screenshot/Stats beside Notify and enlarging header icons | Screenshot and Stats are icon-only rounded square tiles aligned beside Notify, and top hub action icons are large enough |

Latest marker files:

```text
/var/backups/codex/arch-milestone2-desktop-latest
contains: /var/backups/codex/arch-milestone2-desktop-20260806-004044

/var/backups/codex/arch-milestone2-surface-port-latest
contains: /var/backups/codex/arch-milestone2-surface-port-20260806-130453

/var/backups/codex/arch-milestone2-bar-polish-latest
contains: /var/backups/codex/arch-milestone2-bar-polish-20260806-134552

/var/backups/codex/arch-milestone2-rofi-type6-latest
contains: /var/backups/codex/arch-milestone2-rofi-type6-20260806-143846

/var/backups/codex/arch-milestone2-window-count-menu-latest
contains: /var/backups/codex/arch-milestone2-window-count-menu-20260806-151956

/var/backups/codex/arch-milestone2-eww-hub-latest
contains: /var/backups/codex/arch-milestone2-eww-hub-20260806-162223

/var/backups/codex/arch-milestone2-hub-workspace-fix-latest
contains: /var/backups/codex/arch-milestone2-hub-workspace-fix-20260826-172415

/var/backups/codex/arch-milestone2-visual-polish-latest
contains: /var/backups/codex/arch-milestone2-visual-polish-20260826-202458

/var/backups/codex/arch-milestone2-rofi-blur-shape-latest
contains: /var/backups/codex/arch-milestone2-rofi-blur-shape-20260826-213900

/var/backups/codex/arch-milestone2-polybar-workspaces-latest
contains: /var/backups/codex/arch-milestone2-polybar-workspaces-20260827-000412

/var/backups/codex/arch-milestone2-polybar-icons-latest
contains: /var/backups/codex/arch-milestone2-polybar-icons-20260827-003502

/var/backups/codex/arch-milestone2-polybar-border-latest
contains: /var/backups/codex/arch-milestone2-polybar-border-20260827-010238

/var/backups/codex/arch-milestone2-polybar-left-edge-latest
contains: /var/backups/codex/arch-milestone2-polybar-left-edge-20260827-010731

/var/backups/codex/arch-milestone2-eww-main-hub-layout-latest
contains: /var/backups/codex/arch-milestone2-eww-main-hub-layout-20260827-011608

/var/backups/codex/arch-milestone2-eww-hub-icon-actions-latest
contains: /var/backups/codex/arch-milestone2-eww-hub-icon-actions-20260827-012606
```

## Removed Milestone 1 Backup Directories

These remote backup directories were removed after Milestone 1 was accepted. They are kept here as a historical audit trail only; they no longer exist under `/var/backups/codex`.

| Backup path | Created for | Contents / rollback purpose | Keep until |
| --- | --- | --- | --- |
| `/var/backups/codex/arch-lightdm-20260805-122646` | Initial LightDM/WebKit greeter milestone | Earlier LightDM/greetd/user config state before base greeter install | LightDM login, lock, and BSPWM startup are fully accepted |
| `/var/backups/codex/arch-lightdm-power-menu-20260805-125114` | Centered login and power menu polish | Theme/config state before bottom-right power popover work | Power UI is accepted |
| `/var/backups/codex/arch-lightdm-status-icons-20260805-130211` | Status icon iteration | Theme state before first icon-status pass | Status icons are accepted |
| `/var/backups/codex/arch-lightdm-status-icons-final-20260805-130451` | Final status icon pass before later dropdown/font work | Theme state before final icon cleanup | Status display is accepted |
| `/var/backups/codex/arch-lightdm-dropdown-20260805-132238` | User dropdown, password-only login, session auto-hide, SpaceMono config | Theme/config/font state before username dropdown and font changes | User dropdown/session behavior is accepted |
| `/var/backups/codex/arch-lightdm-fast-20260805-141507` | Greeter performance optimization | Theme and WebKit greeter config before inline SVG/performance changes | Fast greeter rendering is accepted |
| `/var/backups/codex/arch-lightdm-loading-20260805-142150` | Login-to-BSPWM loading overlay | Theme HTML/CSS/JS before loading overlay | Loading overlay is accepted after logout/login test |
| `/var/backups/codex/arch-bspwm-fast-20260805-142401` | BSPWM startup cleanup | Previous `/home/guesswho/.config/bspwm/bspwmrc` | BSPWM startup behavior is accepted |
| `/var/backups/codex/arch-startup-video-fixes-20260805-144746` | Startup recording diagnosis fixes | Previous LightDM seat config, BSPWM config, `/etc/default/grub`, `/boot/grub/grub.cfg`, and attempted duplicate autostart backup | Startup speed/lock behavior is accepted after reboot/login test |
| `/var/backups/codex/arch-initramfs-slim-20260805-150000` | Slim initramfs optimization | Previous `/etc/mkinitcpio.conf`, `/etc/grub.d/40_custom`, `/etc/default/grub`, `/boot/grub/grub.cfg`, and previous active `/boot/initramfs-linux.img` | Small initramfs boots reliably across several reboots |
| `/var/backups/codex/arch-boot-automount-20260805-150946` | `/boot` automount optimization | Previous `/etc/fstab` before `/boot` became an on-demand systemd automount | Kernel/package updates work correctly and `/boot` automount is accepted |
| `/var/backups/codex/arch-i915-initramfs-20260805-151928` | i915-only initramfs experiment | Previous mkinitcpio config and pre-i915 initramfs before the i915 test; active config was reverted afterward | Safe to remove once current small initramfs is accepted |
| `/var/backups/codex/arch-greeter-startup-polish-20260805-152704` | Greeter startup polish | Previous LightDM seat config, greeter status helper, and status timer before display setup/no-scan status changes | Greeter startup visuals and status display are accepted |
| `/var/backups/codex/arch-greeter-ac-status-20260805-153153` | Greeter AC-status inference | Previous `/usr/local/bin/brokenback-lightdm-status` before Lenovo `Not charging` AC inference | Battery/AC icon state is accepted |
| `/var/backups/codex/arch-webkit-first-paint-20260805-161342` | WebKit first-paint patch after video review | Previous greeter `index.html`, `style.css`, `script.js`, and LightDM seat config before inline prepaint and display-setup hook disable | User visually confirms the black pointer gap/flicker is improved |
| `/var/backups/codex/arch-drive-clone-sdc-to-sdd-20260805-193106` | `/dev/sdc` to `/dev/sdd` file-level clone | Preflight metadata, `lsblk`, `blkid`, source/target partition dumps, source `fstab`, source GRUB config backups, clone summary, and target UUID record | New `INSPIRE` drive boots successfully and original source drive is no longer needed as fallback |
| `/var/backups/codex/arch-wallpaper-layout-20260805-211509` | Wallpaper source layout | Previous greeter wallpaper, previous `/usr/local/bin/brokenback-lock`, and previous `/home/guesswho/.config/bspwm/bspwmrc` before login/home wallpaper folders and sync helper | Login, lock, and home wallpapers are visually accepted |
| `/var/backups/codex/arch-lockscreen-polish-20260805-212500` | Lockscreen input feedback cleanup | Previous `/usr/local/bin/brokenback-lock` before switching from Betterlockscreen default lock UI to direct `i3lock-color` with transparent password feedback | Lockscreen password entry and transparent clock area are visually accepted |
| `/var/backups/codex/arch-lockscreen-clock-hint-20260805-213200` | Intermediate lockscreen clock/hint iteration | Earlier `/usr/local/bin/brokenback-lock` from the first clock/hint pass | Milestone 1 remote cleanup is approved |
| `/var/backups/codex/arch-lockscreen-clock-hint-20260805-214500` | Lockscreen clock seconds and unlock hint | Previous `/usr/local/bin/brokenback-lock` before restoring seconds and adding `type your password to unlock` while keeping transparent lock UI layers | Lockscreen clock/hint layout is visually accepted |
| `/var/backups/codex/arch-spacemono-login-lock-20260805-215500` | SpaceMono Mono login/lock pin | Previous greeter `index.html`, greeter `style.css`, and `/usr/local/bin/brokenback-lock` before local theme font files and lock font-family changes | Login and lock screens are visually confirmed to use SpaceMono Nerd Font Mono |

## Completed Remote Cleanup

These items were removed after explicit approval on 2026-08-05.

| Item | Reason removed | Result |
| --- | --- | --- |
| `/var/backups/codex/arch-*` | Milestone 1 was accepted | Removed; `/var/backups/codex` is about `4K` |
| `greetd-regreet`, `greetd`, `greetd-agreety` | LightDM is the accepted display manager | Removed |
| `gtk4`, `xdg-desktop-portal`, `xdg-desktop-portal-gtk`, `fuse3`, `fuse-common` | Orphaned dependencies from the old greeter stack | Removed by `pacman -Rns`; reinstall later if a future app needs them |
| `/boot/initramfs-linux-preopt.img` | Old full rescue initramfs from before optimization | Removed |
| `/boot/initramfs-linux-pre-i915.img` | Old experimental i915 initramfs reference | Removed |
| `Arch Linux (pre-initramfs optimization rescue)` GRUB custom entry | Pointed at removed rescue image | Removed; `/boot/grub/grub.cfg` regenerated |
| `/usr/local/bin/brokenback-lightdm-display-setup` | Inactive rollback helper from before the inline WebKit first-paint patch | Removed |
| `/var/cache/pacman/pkg/download-*` | Stale temporary download directories from interrupted downloads | Removed |
| `/var/cache/pacman/pkg` old package entries | Pacman package cache was about `2.8G` at inspection | Cleaned to about `1.5G`; normal installed-package cache kept |

## Non-Backup-Root Files

These were moved or removed outside the `/var/backups/codex` backup root.

| Path | Original active location | Reason | Current result |
| --- | --- | --- | --- |
| `/home/guesswho/.config/autostart.disabled/xss-lock.desktop.disabled-20260805-144933` | `/home/guesswho/.config/autostart/xss-lock.desktop` | Duplicate `xss-lock` autostart disabled; `xss-lock` is managed by `bspwmrc` instead | Removed earlier when the disabled autostart folder became empty |
| `/boot/initramfs-linux-preopt.img` | Active `/boot/initramfs-linux.img` before initramfs slimming | GRUB rescue image for the pre-optimization full initramfs, about `52M` | Removed after Milestone 1 acceptance |
| `/boot/initramfs-linux-pre-i915.img` | Active `/boot/initramfs-linux.img` before the i915-only test | Temporary reference/rescue image for the small pre-i915 initramfs, about `15M` | Removed after Milestone 1 acceptance |

## Current Remote Backup List Observed

Observed from the Arch laptop after the Milestone 2.10.5 main hub icon-action change on 2026-08-27:

```text
/var/backups/codex/arch-milestone2-desktop-20260806-004044
/var/backups/codex/arch-milestone2-desktop-latest
/var/backups/codex/arch-milestone2-surface-port-20260806-130453
/var/backups/codex/arch-milestone2-surface-port-latest
/var/backups/codex/arch-milestone2-bar-polish-20260806-134552
/var/backups/codex/arch-milestone2-bar-polish-latest
/var/backups/codex/arch-milestone2-rofi-type6-20260806-143846
/var/backups/codex/arch-milestone2-rofi-type6-latest
/var/backups/codex/arch-milestone2-window-count-menu-20260806-151956
/var/backups/codex/arch-milestone2-window-count-menu-latest
/var/backups/codex/arch-milestone2-eww-hub-20260806-162223
/var/backups/codex/arch-milestone2-eww-hub-latest
/var/backups/codex/arch-milestone2-hub-workspace-fix-20260826-172415
/var/backups/codex/arch-milestone2-hub-workspace-fix-latest
/var/backups/codex/arch-milestone2-visual-polish-20260826-202458
/var/backups/codex/arch-milestone2-visual-polish-latest
/var/backups/codex/arch-milestone2-rofi-blur-shape-20260826-213900
/var/backups/codex/arch-milestone2-rofi-blur-shape-latest
/var/backups/codex/arch-milestone2-polybar-workspaces-20260827-000412
/var/backups/codex/arch-milestone2-polybar-workspaces-latest
/var/backups/codex/arch-milestone2-polybar-icons-20260827-003502
/var/backups/codex/arch-milestone2-polybar-icons-latest
/var/backups/codex/arch-milestone2-polybar-border-20260827-010238
/var/backups/codex/arch-milestone2-polybar-border-latest
/var/backups/codex/arch-milestone2-polybar-left-edge-20260827-010731
/var/backups/codex/arch-milestone2-polybar-left-edge-latest
/var/backups/codex/arch-milestone2-eww-main-hub-layout-20260827-011608
/var/backups/codex/arch-milestone2-eww-main-hub-layout-latest
/var/backups/codex/arch-milestone2-eww-hub-icon-actions-20260827-012606
/var/backups/codex/arch-milestone2-eww-hub-icon-actions-latest
```

## Cleanup Checklist

- Confirm the Arch laptop reaches the greeter after the Milestone 1.6 reboot; SSH was not reachable at the old link-local address immediately after that reboot.
- Confirm LightDM login works after reboot.
- Confirm username dropdown behaves correctly if multiple real users exist.
- Confirm session selector stays hidden with only BSPWM installed.
- Confirm password-only login works repeatedly.
- Confirm power menu opens immediately and actions are correct.
- Confirm icons render correctly.
- Confirm loading overlay appears after sign-in and clears into BSPWM.
- Confirm BSPWM workspaces, `sxhkd`, `dunst`, `picom`, `polybar`, and `xss-lock` start correctly.
- Confirm lock/unlock works with `super + shift + l`.
- Confirm the screen no longer auto-locks/DPMS-blanks during startup testing.
- Confirm the 1-second GRUB timeout is acceptable.
- Confirm the slim initramfs consistently boots.
- Confirm `/boot` automount works during normal use and before/after kernel updates.
- Confirm the greeter wallpaper appears quickly during the WebKit warm-up gap.
- Confirm the WebKit first-paint patch removes or improves the black pointer gap seen from `00:50-00:55` in the 2026-08-05 16:03:55 startup video.
- Confirm battery/AC status icon looks correct while Lenovo conservation mode reports `Not charging`.
- Confirm a TTY fallback is still available.
- Boot from the cloned `INSPIRE` drive.
- Confirm the cloned system reaches LightDM and logs into BSPWM.
- Confirm the cloned system root is the new `/dev/sdd3` UUID `1030b9ff-c5b6-4f81-9db5-5b3b45bbb272`.
- Keep the original `/dev/sdc` Arch drive unchanged until the new clone is accepted.
- Confirm LightDM uses the login wallpaper source through the deployed greeter copy.
- Confirm lockscreen refreshes from `/home/guesswho/Pictures/wallpaper/login/wallpaper.jpg`.
- Confirm BSPWM sets `/home/guesswho/Pictures/wallpaper/home/wallpaper.jpg` on login.
- Confirm lockscreen password typing no longer shows the loading/verification animation.
- Confirm the lockscreen clock area/background reads as fully transparent.
- Confirm lockscreen clock shows seconds and the hint text `type your password to unlock`.
- Confirm login and lock screens both use SpaceMono Nerd Font Mono.
- Milestone 1 backups were removed after acceptance.
- Confirm Milestone 2 top Polybar appears with left app/workspace, center media, and right status/tray/date/time structure.
- Confirm Milestone 2.1 four-segment Polybar appears like the surface-dots-inspired structure:
  - left app/workspace pill,
  - center media/window pill,
  - small tray pill,
  - right status/date/time pills.
- Confirm `super + space` opens the Eww top-right hub.
- Confirm clicking the peach window-count/menu chip, date, or time opens the Eww hub.
- Confirm the Eww hub actions work: Wi-Fi manager, Bluetooth menu, volume slider, brightness slider, media controls, Dunst pause, screenshot, power menu, lock, and status display.
- Confirm Milestone 2.2 left bar is only the workspace pill, with no Arch/menu glyph or pinned app icons.
- Confirm a workspace with only Alacritty/terminal still displays an occupied dot, not a terminal icon.
- Confirm a workspace with Firefox or another non-terminal app displays the app icon in place of the dot.
- Confirm the right side shows separate rounded pills for the peach window-count/menu chip, battery, date, and time.
- Confirm there is no visible Bluetooth or Flameshot tray icon.
- Confirm Rofi no longer shows the parser error dialog.
- Confirm the hub no longer shows errors on Escape/cancel.
- Confirm screenshot keybinds work without the Flameshot portal timeout.
- Confirm the bar text appears bold and 2pt larger without clipping.
- Confirm `alt + space` opens the compact centered Type 6-style launcher.
- Confirm the launcher uses the home wallpaper and BrokenBack palette.
- Confirm the background behind the launcher is blurred/dimmed.
- Confirm `super + alt + space` opens the run mode with the same Type 6 theme.
- Confirm `super + Tab` opens the window switcher with the same Type 6 theme.
- Confirm the peach window-count/menu chip shows the total open-window count, including terminal windows.
- Confirm clicking the peach window-count/menu chip opens the hub reliably.
- Confirm the separate far-right hub/menu button is gone.
- Confirm package update count appears read-only inside the Eww hub instead of on the bar.
- Confirm the fallback Rofi hub no longer opens a sudo/pacman update prompt.
- Confirm the left workspace pill no longer clips the last workspace dot/icon.
- Confirm `eww` stays installed and `eww-debug` remains removed unless debugging is explicitly needed.
- Confirm all major bar icons are larger and visually consistent.
- Confirm the center bar only shows media when a player is active, including paused media.
- Confirm the center bar stays blank when no player is active or media is stopped.
- Confirm `super + t`, `super + r`, `alt + space`, `ctrl + shift + v`, `ctrl + w`, and `super + arrow keys` work on the physical keyboard.
- Confirm `super + shift + b` opens the Bluetooth menu.
- Confirm `Print` opens Flameshot region capture.
- Confirm media, volume, and brightness keys work on the final keyboard.
- Confirm Ranger previews are acceptable in Alacritty.
- Confirm the global `ctrl + w` close-window behavior is desirable despite overriding app-level tab close.
- Confirm Milestone 2 after a logout/login or reboot before removing `/var/backups/codex/arch-milestone2-desktop-20260806-004044`.
- Confirm Milestone 2.1 after a logout/login or reboot before removing `/var/backups/codex/arch-milestone2-surface-port-20260806-130453`.
- Confirm Milestone 2.2 after a logout/login or reboot before removing `/var/backups/codex/arch-milestone2-bar-polish-20260806-134552`.
- Confirm Milestone 2.3 after a logout/login or reboot before removing `/var/backups/codex/arch-milestone2-rofi-type6-20260806-143846`.
- Confirm Milestone 2.4 after a logout/login or reboot before removing `/var/backups/codex/arch-milestone2-window-count-menu-20260806-151956`.
- Confirm Milestone 2.5 after a logout/login or reboot before removing `/var/backups/codex/arch-milestone2-eww-hub-20260806-162223`.
- Confirm Milestone 2.7 after a logout/login or reboot before removing `/var/backups/codex/arch-milestone2-hub-workspace-fix-20260826-172415`.
- Confirm Milestone 2.8 after a logout/login or reboot before removing `/var/backups/codex/arch-milestone2-visual-polish-20260826-202458`.
- Confirm Milestone 2.9 after a logout/login or reboot before removing `/var/backups/codex/arch-milestone2-rofi-blur-shape-20260826-213900`.
- Confirm Milestone 2.10.5 after a logout/login or reboot before removing `/var/backups/codex/arch-milestone2-eww-hub-icon-actions-20260827-012606`.
- For future milestones, remove only the backups whose milestone is fully accepted.
