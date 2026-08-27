# BrokenBack Arch Rice Changelog

This file records the Arch daily-driver setup changes by milestone. Keep appending to it after each milestone so the system can be audited, cloned, or rolled back later.

Last updated: 2026-08-27

## Current Target

- Current hardware: BrokenBack/server laptop, booting Arch from an external drive.
- Final intended hardware: the Windows PC/laptop after the Arch install is ready to be used as a daily driver.
- Main daily user: `guesswho`.
- Temporary setup user: `codexsetup`, kept until setup and verification are complete.
- Display manager direction: LightDM with a custom WebKit2 greeter.
- Window manager direction: BSPWM, with broader rice deferred until login/lock is solid.

## Milestone 0: Remote Access Bootstrap

Purpose: allow controlled remote setup from the current laptop without sharing the user's personal SSH keys.

Changes made:

- Created/used temporary sudo-capable setup user `codexsetup` on the Arch install.
- Added a dedicated temporary SSH public key to `/home/codexsetup/.ssh/authorized_keys`.
- Installed or verified `sudo` and `openssh`.
- Enabled and started `sshd.service`.
- Confirmed SSH access over the direct Ethernet/link-local route.
- Left `codexsetup` in place for continuing setup work.

Notes:

- This user should be removed only after the Arch daily-driver setup is fully accepted.
- Personal user/root passwords and personal SSH keys were not shared with Codex.

## Milestone 1: LightDM WebKit Login And Lock Base

Purpose: replace `greetd`/`regreet` with a sleek LightDM WebKit2 login screen and matching lock flow.

Packages installed or verified:

- `lightdm`
- `lightdm-webkit2-greeter`
- `betterlockscreen`
- `i3lock-color`
- `xss-lock`
- `imagemagick`
- `xorg-xset`
- `xorg-xrandr`
- `xorg-xdpyinfo`
- `xorg-xrdb`
- `bc`

System changes:

- Performed package update work required by the package state at the time.
- Kernel package was updated; after reboot the running kernel verified as `7.1.5-arch1-2`.
- Disabled `greetd.service`.
- Enabled `lightdm.service`.
- Set graphical target for display-manager boot.
- Configured LightDM seat drop-in at `/etc/lightdm/lightdm.conf.d/50-brokenback.conf`.
- Configured WebKit2 greeter at `/etc/lightdm/lightdm-webkit2-greeter.conf`.
- Created custom greeter theme at `/usr/share/lightdm-webkit/themes/brokenback`.

Theme changes:

- Built a local vanilla HTML/CSS/JS theme.
- No Tailwind, Bootstrap, React, npm runtime, CDN, or remote assets.
- Used the existing wallpaper as the greeter background.
- Added clock/date, password login, status display, session handling, and power controls.

Status feed:

- Added `/usr/local/bin/brokenback-lightdm-status`.
- Added `brokenback-lightdm-status.service`.
- Added `brokenback-lightdm-status.timer`.
- Timer writes greeter-readable JSON to the theme directory.
- Status data includes hostname, battery percent/state, AC state, network status/type, and SSID.
- Login screen intentionally does not expose IP addresses.

Lock integration:

- Added `/usr/local/bin/brokenback-lock`.
- Added `xss-lock` autostart for the main user.
- Added `super + shift + l` lock binding in SXHKD.
- Lock uses `betterlockscreen` with the greeter wallpaper when possible, and falls back to `i3lock`.

Verification:

- Reboot completed successfully.
- SSH returned after reboot.
- `lightdm` was active.
- `systemctl --failed` showed zero failed units.

## Milestone 1.1: Login UI Polish

Purpose: make the greeter match the desired daily-driver flow.

Changes made:

- Centered the login panel.
- Changed the power control from a visible action bar to a bottom-right power button.
- Added a compact power popover menu for suspend, hibernate, restart, and shutdown.
- Kept two-click confirmation for power actions.
- Replaced username-then-password flow with a password-only field.
- Moved user selection to the top-left username control.
- Added a shadcn-inspired dropdown style using only vanilla HTML/CSS/JS.
- Filtered `codexsetup` out of the greeter user menu.
- Made session selection appear only if more than one session is available.
- Current session state: only `bspwm.desktop` exists, so the selector is hidden and BSPWM is selected automatically.

Font changes:

- Installed `ttf-space-mono-nerd 3.5.0-1`.
- Added system fontconfig rule at `/etc/fonts/conf.d/51-brokenback-spacemono-nerd.conf`.
- Verified:
  - `sans-serif` resolves to `SpaceMono Nerd Font`.
  - `serif` resolves to `SpaceMono Nerd Font`.
  - `system-ui` resolves to `SpaceMono Nerd Font`.
  - `monospace` resolves to `SpaceMono Nerd Font Mono`.
- Greeter CSS uses SpaceMono Nerd Font first.

LightDM config changes:

- Set `greeter-hide-users=false`.
- Set `greeter-show-manual-login=false`.
- Kept `user-session=bspwm`.

## Milestone 1.2: Greeter Rendering And Startup Optimization

Problem observed:

- Icons did not render.
- Buttons and the power menu appeared late.
- Power menu did not open for the first few seconds.
- Login screen startup felt slow.

Findings:

- Material Symbols font path was not rendering reliably in the WebKit greeter.
- The greeter theme had expensive effects for older/external-drive hardware.
- The login wallpaper was `3840x2160` and about `1.5 MB`.
- After LightDM restart, the optimized greeter connected at about `+0.79s` and started authentication at about `+1.18s`.

Changes made:

- Removed the Material Symbols dependency from the greeter.
- Replaced battery, network, dropdown, and power icons with inline SVG.
- Removed expensive `backdrop-filter` use.
- Removed continuous background grid/sheen animations.
- Kept the panel animation but reduced it to a short `180ms` entrance.
- Made the power menu also respond through CSS `:focus-within`.
- Started authentication earlier in the JavaScript boot path.
- Disabled WebKit theme error detection with `detect_theme_errors = false`.
- Resized greeter wallpaper to `1920x1080`, about `188 KB`.

Verification:

- Theme files installed under `/usr/share/lightdm-webkit/themes/brokenback`.
- Current theme file sizes seen after optimization:
  - `index.html`: about `4 KB`
  - `style.css`: about `12 KB`
  - `script.js`: about `16 KB`
  - `wallpaper.jpg`: about `188 KB`
- `lightdm` remained active.
- `systemctl --failed` showed zero failed units.

## Milestone 1.3: Login-To-BSPWM Feedback And Startup Cleanup

Problem observed:

- Transition from LightDM login to BSPWM felt slow.
- User requested either improved speed or a loading animation.

Findings:

- LightDM log showed the password-to-session handoff itself was already under about one second.
- BSPWM had several lingering shell wrapper processes from startup commands.
- Original `bspwmrc` launched background services before creating workspaces.
- Original `bspwmrc` pattern such as `pgrep ... || command &` could leave shell wrappers around.

Greeter changes:

- Added full-screen loading overlay to the greeter.
- On submit, overlay shows `Checking password`.
- After successful authentication, overlay shows `Starting BSPWM`.
- Removed the old blank fade-out feeling.
- Kept the actual session start nearly immediate after the overlay paints.
- Added loader reset path for failed authentication.

BSPWM changes:

- Rewrote `/home/guesswho/.config/bspwm/bspwmrc`.
- Workspaces are now created first with:
  - `bspc monitor -d I II III IV V VI VII VIII IX X`
- Added `run_once()` helper.
- Starts `sxhkd`, `dunst`, `picom`, `polybar`, and `xss-lock` cleanly in the background.
- Avoids restarting `polybar` if it is already running.
- Keeps `/usr/local/bin/brokenback-lock` as the lock command.

Current `bspwmrc` behavior:

- Set monitor desktops first.
- Start `sxhkd`.
- Start `dunst`.
- Start `picom`.
- Start `polybar example` if available and not already running.
- Start `xss-lock` if not already running.

Verification:

- `bspwmrc` syntax verified with `sudo -u guesswho sh -n`.
- `lightdm` remained active.
- `systemctl --failed` showed zero failed units.
- LightDM was not restarted during an active `guesswho` BSPWM session to avoid kicking the user out.

## Milestone 1.4: Startup Recording Diagnosis And Boot/Lock Fixes

Purpose: diagnose the startup recording symptoms and fix the causes visible in the system logs.

Recording note:

- The local Codex environment did not have `ffmpeg`, OpenCV, or a browser control tool available to decode the MP4 directly.
- Diagnosis was done from the Arch laptop's boot, LightDM, X, and process logs around the recording time.

Findings:

- Boot before this fix measured about `49.821s` total:
  - `13.029s` firmware
  - `10.589s` loader
  - `1.704s` kernel
  - `10.440s` initrd
  - `14.056s` userspace
- The install is currently booting from an external Seagate USB HDD:
  - Root: `/dev/sdc3`
  - Boot: `/dev/sdc1`
  - Disk model: `Expansion HDD`
  - Transport: USB
  - Rotational: yes
- The external drive/device path was the largest unavoidable delay, around `19s` before the fix and around `16-17s` after reboot.
- GRUB had a visible `5s` menu timeout.
- X had default screen saver/DPMS settings:
  - screen saver timeout `600s`
  - DPMS enabled
  - monitor had gone off
- `xss-lock` launched `betterlockscreen`/`i3lock` after the default idle timeout, which could look like the startup flow had fallen into a lock/black-screen problem during testing.
- There was an XDG autostart file for `xss-lock` even though `xss-lock` is already started from `bspwmrc`.

Changes made:

- Reduced GRUB timeout from `5` to `1` second in `/etc/default/grub`.
- Regenerated `/boot/grub/grub.cfg` with `grub-mkconfig`.
- Added LightDM X server command:
  - `xserver-command=X -s 0 -dpms`
- Added BSPWM startup command:
  - `xset s off -dpms`
- Moved duplicate XDG `xss-lock.desktop` out of `/home/guesswho/.config/autostart`.
- Kept `xss-lock` started from `/home/guesswho/.config/bspwm/bspwmrc`.
- Manual lock remains available through `super + shift + l`.

Post-fix verification:

- Reboot completed successfully.
- Boot after this fix measured about `39.627s` total:
  - `8.329s` firmware
  - `7.462s` loader
  - `1.776s` kernel
  - `7.550s` initrd
  - `14.509s` userspace
- GRUB generated config now contains:
  - `set timeout_style=menu`
  - `set timeout=1`
- LightDM starts X with:
  - `/usr/bin/X -s 0 -dpms :0 ...`
- `/home/guesswho/.config/autostart` is empty.
- Disabled autostart file is stored at:
  - `/home/guesswho/.config/autostart.disabled/xss-lock.desktop.disabled-20260805-144933`
- `lightdm` active after reboot.
- `systemctl --failed` showed zero failed units.

Remaining expected limitation:

- The current external USB HDD boot path is still the main startup bottleneck.
- The final internal SSD/NVMe install should be much faster without needing desktop-level changes.

## Milestone 1.5: Initramfs And Greeter Startup Refinement

Purpose: address the user's specific observation that the screen sat on `Loading initial ramdisk...` for roughly 45 seconds, then showed a pointer before the greeter finished loading.

Findings:

- The active initramfs before this refinement was about `52M`.
- `lsinitcpio -a` showed a large early CPIO section around `38 MiB`.
- The system was already loading `/boot/intel-ucode.img` from GRUB, so the initramfs was carrying duplicate early payload.
- The visible `Loading initial ramdisk...` line was mainly GRUB reading the kernel, Intel microcode image, and large initramfs from the external USB HDD while quiet boot left that line on screen.
- After the initramfs work, `boot.mount` became the next boot-chain delay because `/boot` was being mounted from the same external drive before LightDM.
- `lightdm-webkit2-greeter` itself still takes about `4s` after launch to connect; that is WebKit startup cost, not theme asset size.
- Theme assets are small:
  - `wallpaper.jpg`: about `185K`
  - `style.css`: about `9.3K`
  - `script.js`: about `17K`

Initramfs changes:

- Backed up the pre-optimization initramfs and mkinitcpio config.
- Added `/boot/initramfs-linux-preopt.img` as a GRUB rescue image.
- Added GRUB rescue menu entry:
  - `Arch Linux (pre-initramfs optimization rescue)`
- Removed the `microcode`/large early payload path from the active initramfs.
- Removed `kms` from the active initramfs after testing.
- Kept explicit USB storage support for the external boot drive:
  - `MODULES=(usb_storage uas)`
- Active hooks are:
  - `HOOKS=(base systemd autodetect modconf keyboard sd-vconsole block filesystems fsck)`
- Tested an i915-only initramfs:
  - image size about `21M`
  - early CPIO about `6.24 MiB`
  - no meaningful LightDM/X speed improvement
- Reverted active initramfs back to the smaller profile.
- Left `/boot/initramfs-linux-pre-i915.img` as a temporary rescue/reference image.

Storage/mount changes:

- Changed `/boot` in `/etc/fstab` to use systemd automount:
  - `noauto,x-systemd.automount,x-systemd.idle-timeout=1min`
- This keeps `/boot` available on access, including for kernel updates, but stops it from blocking the greeter path during normal boot.
- Verified `boot.automount` active and `boot.mount` triggered on demand.

Greeter startup changes:

- Added `/usr/local/bin/brokenback-lightdm-display-setup`.
- Added LightDM setting:
  - `display-setup-script=/usr/local/bin/brokenback-lightdm-display-setup`
- The display setup paints the greeter wallpaper with `feh` as soon as the X display is ready, so the WebKit warm-up gap is not a blank screen.
- Optimized `/usr/local/bin/brokenback-lightdm-status`.
- Replaced `nmcli dev wifi` with no-scan active-device/default-route checks.
- Added AC-state inference for this Lenovo hardware, which exposes `BAT0` but no separate AC adapter node:
  - `Charging`, `Full`, and `Not charging` are treated as AC online.
  - `Discharging` is treated as AC offline.
- Delayed first status timer run from `10s` to `25s` after boot so it does not compete with LightDM/WebKit startup.

Final verification:

- Final active initramfs:
  - `/boot/initramfs-linux.img`: about `15M`
  - early CPIO: `440 KiB`
  - included explicit modules: `usb-storage`, `uas`
- Rescue images retained:
  - `/boot/initramfs-linux-preopt.img`: about `52M`
  - `/boot/initramfs-linux-pre-i915.img`: about `15M`
- Final measured boot:
  - `9.148s` firmware
  - `4.569s` loader
  - `1.454s` kernel
  - `2.491s` initrd
  - `17.013s` userspace
  - `34.677s` total
- `graphical.target` reached after about `17.009s` in userspace.
- `lightdm` active after reboot.
- `systemctl --failed` showed zero failed units.
- Greeter status JSON verified battery/network data:
  - battery `58`
  - battery state `Not charging`
  - AC `online`
  - Wi-Fi `BlueBox`

## Milestone 1.6: Startup Video Review And WebKit First-Paint Patch

Purpose: inspect the 2026-08-05 16:03:55 startup video with FFmpeg and address the remaining visible greeter handoff issue.

Video analysis:

- Used local portable FFmpeg/FFprobe from:
  - `C:\Users\aksha\OneDrive\Documents\Server and Setup\tools\ffmpeg\bin`
- Source video:
  - `WhatsApp Video 2026-08-05 at 16.03.55.mp4`
- Video duration:
  - about `74.17s`
- Generated analysis output under:
  - `C:\Users\aksha\OneDrive\Documents\Server and Setup\video-analysis\startup-2026-08-05-160355`
- Observed sequence:
  - boot/initramfs text near the beginning,
  - dark display through roughly `00:40-00:44`,
  - wallpaper visible around `00:45-00:49`,
  - black WebKit greeter window with pointer around `00:50-00:55`,
  - full greeter visible around `00:55.5-00:56`.

Findings:

- The previous LightDM `display-setup-script` made the wallpaper appear before the WebKit greeter window was ready.
- Once WebKit opened its own window, it covered the root wallpaper with a black surface until the theme finished first paint.
- This made the boot feel like it flashed forward and then regressed to black, even though LightDM was still progressing.

Changes made:

- Added inline first-paint CSS directly to `/usr/share/lightdm-webkit/themes/brokenback/index.html`.
- Added a tiny prepaint layer:
  - `#prepaint`
  - wallpaper background
  - small CSS spinner
- Added JS hook to mark the theme ready:
  - `document.documentElement.classList.add("theme-ready")`
- Commented out the LightDM wallpaper display setup hook in:
  - `/etc/lightdm/lightdm.conf.d/50-brokenback.conf`
- Kept `/usr/local/bin/brokenback-lightdm-display-setup` on disk for rollback/reference, but it is no longer active.

Verification status:

- Reboot was initiated after the patch.
- SSH did not return at the previous link-local address `169.254.171.2`.
- Windows ARP did not show the Arch laptop at that old link-local address after the reboot.
- Visual verification is pending a user screen check or renewed network reachability.

Related planning doc:

- Created `BROKENBACK_ARCH_NEXT_CHANGES.md`.
- Added deferred plans for:
  - fingerprint implementation,
  - final-hardware microcode detection,
  - installing only the microcode needed for the intended daily-driver hardware,
  - removing nonmatching/unnecessary microcode after final hardware is known.

## Milestone 1.7: External Arch Drive Clone To Faster 512GB Drive

Purpose: clone the working Arch daily-driver external drive from the larger USB HDD to the faster 512GB external drive so boot and daily use can be tested from faster storage.

Source drive:

- Device: `/dev/sdc`
- Model: `Expansion HDD`
- Transport: USB
- Size: about `931.5G`
- Layout:
  - `/dev/sdc1`: EFI `/boot`, `512M`
  - `/dev/sdc2`: swap, `8G`
  - `/dev/sdc3`: root `/`, ext4, about `923G`

Target drive erased and recreated:

- Device: `/dev/sdd`
- Model: `INSPIRE`
- Serial: `2024031503AB`
- Transport: USB
- Size: about `476.9G`
- Previous contents: one NTFS partition labeled `extdata`

Changes made:

- Installed missing clone tools:
  - `rsync`
  - `dosfstools`
- Created guarded clone script:
  - local: `C:\Users\aksha\OneDrive\Documents\Server and Setup\remote-scripts\arch\clone-sdc-to-sdd-filelevel.sh`
  - remote: `/tmp/clone-sdc-to-sdd-filelevel.sh`
- The script required explicit `CONFIRM_ERASE_DEV_SDD=YES`.
- The script verified:
  - current root came from `/dev/sdc3`,
  - current `/boot` came from `/dev/sdc1`,
  - target disk was `/dev/sdd`,
  - target model matched `INSPIRE`,
  - target had enough capacity for used source data plus headroom,
  - no target partitions were mounted or active as swap.
- Erased `/dev/sdd`.
- Created MBR/DOS partition table on `/dev/sdd`.
- Created target partitions:
  - `/dev/sdd1`: `512M`, EFI/FAT32, label `ARCHBOOT`, bootable
  - `/dev/sdd2`: `8G`, swap, label `ARCHSWAP`
  - `/dev/sdd3`: `468.4G`, ext4, label `ARCHROOT`
- Copied root filesystem file-by-file with `rsync -aAXH --numeric-ids --one-file-system`.
- Copied `/boot` to the target EFI partition.
- Generated target `/etc/fstab` using the new target UUIDs.
- Replaced source root UUID references with target root UUID in target GRUB custom config where applicable.
- Installed GRUB to the target EFI partition with removable fallback boot support.
- Generated target `/boot/grub/grub.cfg`.

Target UUIDs:

- Root `/dev/sdd3`: `1030b9ff-c5b6-4f81-9db5-5b3b45bbb272`
- Boot `/dev/sdd1`: `2248-0E7B`
- Swap `/dev/sdd2`: `54ca4e0b-d776-4665-86ad-14ca2611f829`

Verification:

- Clone completed with exit code `0`.
- Target partitions and filesystem labels verified with `lsblk` and `blkid`.
- Target `fstab` verified to point to the new root, boot, and swap UUIDs.
- Target EFI files verified:
  - `/boot/EFI/BOOT/BOOTX64.EFI`
  - `/boot/EFI/GRUB/grubx64.efi`
- Target boot files verified:
  - `/boot/grub/grub.cfg`
  - `/boot/initramfs-linux.img`
  - `/boot/intel-ucode.img`
  - `/boot/vmlinuz-linux`
- Target GRUB config verified to boot:
  - `root=UUID=1030b9ff-c5b6-4f81-9db5-5b3b45bbb272`

Backup/log directory:

- `/var/backups/codex/arch-drive-clone-sdc-to-sdd-20260805-193106`

Next verification needed:

- Boot the machine from the new `INSPIRE` drive.
- Confirm it reaches the LightDM greeter.
- Confirm login to BSPWM works.
- Confirm `/` is mounted from `/dev/sdd3` after boot.
- Confirm `/boot` automount works from `/dev/sdd1`.
- Keep the original `/dev/sdc` Arch drive untouched as fallback until the new drive is accepted.

## Milestone 1.8: Wallpaper Source Layout For Login, Lock, And Home

Purpose: make the wallpaper layout predictable before continuing the rice, with separate source folders for login/lock and desktop/home wallpapers.

Requested layout:

- Login and lock wallpaper source:
  - `/home/guesswho/Pictures/wallpaper/login/wallpaper.jpg`
- Home/desktop wallpaper source:
  - `/home/guesswho/Pictures/wallpaper/home/wallpaper.jpg`

Changes made:

- Created the wallpaper folders under `/home/guesswho/Pictures/wallpaper`.
- Copied the current LightDM greeter wallpaper into:
  - `/home/guesswho/Pictures/wallpaper/login/wallpaper.jpg`
  - `/home/guesswho/Pictures/wallpaper/home/wallpaper.jpg`
- Kept `/home/guesswho` at its existing private `700` permissions.
- Because LightDM cannot read through that private home path, added a root-readable deployed copy at:
  - `/usr/share/lightdm-webkit/themes/brokenback/wallpaper.jpg`
- Added `/usr/local/bin/brokenback-wallpaper-sync`.
  - The source of truth is the login wallpaper in `Pictures`.
  - The script copies that file into the LightDM theme.
  - The script invalidates the lockscreen wallpaper hash so the next lock refreshes Betterlockscreen from the current login wallpaper.
- Updated `/usr/local/bin/brokenback-lock`.
  - It now reads from `/home/guesswho/Pictures/wallpaper/login/wallpaper.jpg`.
  - It falls back to the LightDM theme copy if needed.
  - It refreshes Betterlockscreen cache on the next real lock whenever the login wallpaper hash changes.
- Updated `/home/guesswho/.config/bspwm/bspwmrc`.
  - BSPWM now sets the home wallpaper with `feh --bg-fill "$HOME/Pictures/wallpaper/home/wallpaper.jpg"` during startup.

Verification:

- Active root UUID verified as the cloned target UUID:
  - `1030b9ff-c5b6-4f81-9db5-5b3b45bbb272`
- `feh` already installed:
  - `feh 3.12.2-1`
- Login source wallpaper and LightDM theme copy have matching SHA-256 hashes.
- Wallpaper files verified:
  - login source owned by `guesswho:guesswho`
  - home source owned by `guesswho:guesswho`
  - greeter copy owned by `root:root`
- Syntax verified:
  - `/home/guesswho/.config/bspwm/bspwmrc`
  - `/usr/local/bin/brokenback-lock`
  - `/usr/local/bin/brokenback-wallpaper-sync`
- Lockscreen cache stamp is intentionally pending until the next lock from an active X session.

Backup directory:

- `/var/backups/codex/arch-wallpaper-layout-20260805-211509`

## Milestone 1.9: Lockscreen Input Feedback Cleanup

Purpose: adjust only the lockscreen opened by `super + shift + l`, leaving the LightDM login greeter unchanged.

Problem observed:

- Lockscreen worked, but typing the password showed an unnecessary loading/verification animation.
- The clock area should have a fully transparent background.

Changes made:

- Updated `/usr/local/bin/brokenback-lock`.
- Kept Betterlockscreen for generating the blurred lock wallpaper image from:
  - `/home/guesswho/Pictures/wallpaper/login/wallpaper.jpg`
- Stopped using Betterlockscreen's default `--lock blur` UI path.
- The wrapper now calls `i3lock-color` directly against the Betterlockscreen cached blur image.
- Made lock input feedback visually quiet:
  - transparent normal ring,
  - transparent verifying ring,
  - transparent wrong ring,
  - transparent key highlight,
  - transparent backspace highlight,
  - empty verifying text,
  - empty wrong-password text,
  - empty no-input text.
- Kept the lock clock enabled with:
  - `--clock`
  - `--force-clock`
  - `--time-str "%H:%M"`
  - `SpaceMono Nerd Font`
- Made the clock indicator/background layer transparent by using transparent inside/ring colors.

Verification:

- Saved previous wrapper before installing the new one.
- Syntax verified:
  - `/usr/local/bin/brokenback-lock`
- Ran a fake-display parse check so the command could validate options without locking the real display.
- Parse check produced only the expected X11 connection failure for fake display `:99`; no invalid-option warnings remained.

Backup directory:

- `/var/backups/codex/arch-lockscreen-polish-20260805-212500`

## Milestone 1.10: Lockscreen Clock Seconds And Unlock Hint

Purpose: keep the quiet lockscreen input behavior, but bring back useful text on the `super + shift + l` lockscreen.

Changes made:

- Updated `/usr/local/bin/brokenback-lock`.
- Restored seconds in the lockscreen clock:
  - `--time-str='%H:%M:%S'`
- Added hint text under the clock:
  - `type your password to unlock`
- Kept password typing visually quiet:
  - empty verifying text,
  - empty wrong-password text,
  - transparent key highlight,
  - transparent backspace highlight.
- Kept the lockscreen box/indicator layers fully transparent:
  - `--inside-color=00000000`
  - `--ring-color=00000000`
  - `--separator-color=00000000`
  - verifying/wrong ring and inside colors remain transparent.
- Kept the clock and hint text in SpaceMono Nerd Font.

Verification:

- Saved the previous lock wrapper before installing this version.
- Syntax verified:
  - `/usr/local/bin/brokenback-lock`
- Ran a fake-display dry run to validate i3lock options without locking the real display.
- Dry run produced only the expected fake X11 display connection failure; no invalid option warnings appeared.

Backup directory:

- `/var/backups/codex/arch-lockscreen-clock-hint-20260805-214500`

## Milestone 1.11: SpaceMono Mono Pin For Login And Lock

Purpose: force the login greeter and lockscreen back to SpaceMono Nerd Font Mono without adding a fragile startup dependency.

Changes made:

- Confirmed the installed font family resolves correctly:
  - `SpaceMono Nerd Font Mono`
  - `/usr/share/fonts/TTF/SpaceMonoNerdFontMono-Regular.ttf`
  - `/usr/share/fonts/TTF/SpaceMonoNerdFontMono-Bold.ttf`
- Copied the regular and bold Mono font files into the local LightDM theme:
  - `/usr/share/lightdm-webkit/themes/brokenback/fonts/SpaceMonoNerdFontMono-Regular.ttf`
  - `/usr/share/lightdm-webkit/themes/brokenback/fonts/SpaceMonoNerdFontMono-Bold.ttf`
- Added local `@font-face` rules to the greeter theme using the internal family name:
  - `BrokenbackSpaceMono`
- Set the greeter global font stack to prefer `BrokenbackSpaceMono`, then fall back to `SpaceMono Nerd Font Mono`.
- Updated the critical first-paint CSS in `index.html` so the first visible login frame also uses the same font stack.
- Updated `/usr/local/bin/brokenback-lock` so both the clock and unlock hint use:
  - `SpaceMono Nerd Font Mono`
- Updated the local mirror script:
  - `remote-scripts/arch/brokenback-lock`
- Updated the first-paint helper script so future reruns prefer `SpaceMono Nerd Font Mono`.

Verification:

- Confirmed `fc-match 'SpaceMono Nerd Font Mono'` resolves to `SpaceMonoNerdFontMono-Regular.ttf`.
- Confirmed the greeter CSS and inline first-paint CSS contain valid `@font-face` entries.
- Confirmed `/usr/local/bin/brokenback-lock` references `SpaceMono Nerd Font Mono`.
- Syntax verified:
  - `/usr/local/bin/brokenback-lock`
- Did not restart LightDM to avoid interrupting the active session.

Backup directory:

- `/var/backups/codex/arch-spacemono-login-lock-20260805-215500`

## Milestone 1 Closeout: Accepted Login And Lock Foundation

Status: accepted by the user on 2026-08-05.

Milestone purpose:

- Turn the external-drive Arch install into a stable visual base for a daily-driver rice.
- Replace the old greeter direction with a polished LightDM login flow.
- Make login, lock, wallpaper, font, and early boot behavior predictable before deeper BSPWM desktop work.
- Keep the setup reversible while the install is still being developed on temporary hardware.

Final implemented login stack:

- `lightdm.service` is the enabled display manager.
- `greetd.service` is disabled and inactive.
- The active greeter is `lightdm-webkit2-greeter`.
- The active theme is the local `brokenback` WebKit2 theme:
  - `/usr/share/lightdm-webkit/themes/brokenback`
- The LightDM seat is configured through:
  - `/etc/lightdm/lightdm.conf.d/50-brokenback.conf`
- The WebKit greeter is configured through:
  - `/etc/lightdm/lightdm-webkit2-greeter.conf`
- The theme is plain local HTML/CSS/JS:
  - no Tailwind,
  - no Bootstrap,
  - no React,
  - no npm runtime,
  - no CDN,
  - no remote assets.

Final implemented login UX:

- Login panel is centered.
- Username is shown as the top-left identity control.
- If more than one real login user is available, the username control opens a dropdown.
- `codexsetup` is filtered out of the visual user picker.
- Login uses a password-only field after the user is selected.
- Session selection is hidden when only one session exists.
- BSPWM is selected automatically when it is the only available session.
- Power controls are a compact button plus popover menu, instead of a visible action bar.
- Power actions keep the safer two-step confirmation behavior.
- Status icons use inline SVG so the greeter is not dependent on icon fonts.
- The greeter shows useful state without exposing IP addresses:
  - clock/date,
  - battery percent/state,
  - AC state,
  - network type/status,
  - Wi-Fi SSID when available.

Final implemented font setup:

- `ttf-space-mono-nerd 3.5.0-1` is installed.
- Fontconfig prefers SpaceMono for the system families configured during this milestone.
- The greeter has local pinned font files:
  - `/usr/share/lightdm-webkit/themes/brokenback/fonts/SpaceMonoNerdFontMono-Regular.ttf`
  - `/usr/share/lightdm-webkit/themes/brokenback/fonts/SpaceMonoNerdFontMono-Bold.ttf`
- The greeter CSS defines `BrokenbackSpaceMono` with local `@font-face`.
- The greeter global font stack prefers:
  - `BrokenbackSpaceMono`
  - `SpaceMono Nerd Font Mono`
- The lockscreen clock and unlock hint use:
  - `SpaceMono Nerd Font Mono`

Final implemented wallpaper layout:

- Login and lock source wallpaper:
  - `/home/guesswho/Pictures/wallpaper/login/wallpaper.jpg`
- Home desktop source wallpaper:
  - `/home/guesswho/Pictures/wallpaper/home/wallpaper.jpg`
- LightDM-readable deployed greeter wallpaper:
  - `/usr/share/lightdm-webkit/themes/brokenback/wallpaper.jpg`
- Wallpaper sync helper:
  - `/usr/local/bin/brokenback-wallpaper-sync`
- BSPWM sets the home wallpaper on login with `feh`.
- The lock wrapper refreshes the Betterlockscreen cache when the login wallpaper changes.

Final implemented lock stack:

- Lock command:
  - `/usr/local/bin/brokenback-lock`
- Manual keybind:
  - `super + shift + l`
- Idle/session locking helper:
  - `xss-lock`
- `xss-lock` is managed from BSPWM startup, not duplicate XDG autostart.
- Betterlockscreen remains useful for generating the blurred wallpaper cache.
- The actual lock UI uses `i3lock-color` directly for control over transparency and text.
- Password typing is visually quiet:
  - no visible loading/verifying animation,
  - no wrong-password text layer,
  - no key highlight layer,
  - no box background.
- The lockscreen shows:
  - clock with seconds,
  - `type your password to unlock`,
  - transparent clock/indicator background.

Final implemented boot/startup work:

- GRUB timeout reduced to `1` second.
- X screen blanking and DPMS disabled in the login/session path.
- Duplicate `xss-lock` autostart disabled.
- Active initramfs reduced from the original large profile to a small external-boot-safe profile.
- Explicit external boot modules kept:
  - `usb_storage`
  - `uas`
- Duplicate early microcode payload was removed from the active initramfs path.
- `/boot` is available through systemd automount so it does not block normal greeter startup.
- WebKit first paint was improved with inline critical CSS and a local prepaint layer.
- The old LightDM display setup wallpaper hook is no longer active.

Final implemented clone/storage work:

- The working Arch install was cloned from the larger external HDD to the faster 512GB `INSPIRE` drive.
- The target root UUID is:
  - `1030b9ff-c5b6-4f81-9db5-5b3b45bbb272`
- The cloned system booted and is the current working daily-driver development base.

Local workspace cleanup completed:

- Removed the portable FFmpeg download/archive folder:
  - `tools/ffmpeg/download`
  - about `106 MB`
- Removed the full extracted FFmpeg tree:
  - `tools/ffmpeg/extract`
  - about `306 MB`
- Removed generated startup video analysis frames:
  - `video-analysis`
  - about `1.7 MB`
- Kept only the useful portable diagnostics binaries:
  - `tools/ffmpeg/bin/ffmpeg.exe`
  - `tools/ffmpeg/bin/ffprobe.exe`

Remote Arch cleanup completed after explicit approval:

- Removed accepted milestone backup directories:
  - `/var/backups/codex/arch-*`
  - `/var/backups/codex` now only contains the empty backup root, about `4K`.
- Removed the old greeter stack:
  - `greetd-regreet`
  - `greetd`
  - `greetd-agreety`
- Pacman also removed orphaned dependencies that were only kept by the old greeter stack:
  - `gtk4`
  - `xdg-desktop-portal`
  - `xdg-desktop-portal-gtk`
  - `fuse3`
  - `fuse-common`
- Removed old rescue initramfs images:
  - `/boot/initramfs-linux-preopt.img`
  - `/boot/initramfs-linux-pre-i915.img`
- Removed the obsolete GRUB rescue entry:
  - `Arch Linux (pre-initramfs optimization rescue)`
- Regenerated:
  - `/boot/grub/grub.cfg`
- Verified no rescue references remain in:
  - `/etc/grub.d/40_custom`
  - `/boot/grub/grub.cfg`
- Removed the inactive first-paint rollback helper:
  - `/usr/local/bin/brokenback-lightdm-display-setup`
- Removed the LightDM seat reference to the inactive display setup helper.
- Cleaned pacman cache:
  - `/var/cache/pacman/pkg` reduced from about `2.8G` to about `1.5G`.
  - removed stale `download-*` temporary cache directories left by interrupted downloads.
- Left the normal installed-package cache intact for safer rollback.

Items intentionally kept:

- `codexsetup`, until the final hardware migration and rice are stable.
- `intel-ucode`, because the current temporary BrokenBack hardware is Intel and the final hardware microcode decision is deferred.
- `betterlockscreen`, because it still generates the lock wallpaper cache.
- `i3lock-color`, because it is the active lock UI.
- `xss-lock`, because BSPWM uses it for lock integration.
- `feh`, because BSPWM uses it for wallpaper setup.
- `rsync` and `dosfstools`, because they remain useful for clone/recovery work.

Remote cleanup verification:

- `lightdm.service` is enabled and active.
- `sshd.service` is enabled and active.
- `greetd.service` is no longer found as an installed service and is inactive.
- Installed login/lock packages still present:
  - `lightdm`
  - `lightdm-webkit2-greeter`
  - `betterlockscreen`
  - `i3lock-color`
  - `xss-lock`
  - `ttf-space-mono-nerd`
- Active boot files still present:
  - `/boot/vmlinuz-linux`
  - `/boot/intel-ucode.img`
  - `/boot/initramfs-linux.img`
- No failed systemd units were reported.
- LightDM can read the pinned SpaceMono font file.
- `/usr/local/bin/brokenback-lock` passes shell syntax validation.

## Milestone 2: BSPWM Daily Desktop Foundation

Status: implemented on 2026-08-06. Visual acceptance is pending the user's eyes on the running desktop, but service/config checks passed.

Purpose:

- Turn the logged-in BSPWM session into a practical daily-driver base.
- Keep the accepted LightDM login and lock layer unchanged.
- Add a cohesive calm dark utility theme using SpaceMono Nerd Font Mono, cyan focus, peach accent, and low-brightness OLED-aware colors.
- Build the first real top bar, launcher/menu flow, terminal/file workflow, screenshot, clipboard, audio, brightness, media, and Bluetooth controls.

Backup:

- Created before desktop changes:
  - `/var/backups/codex/arch-milestone2-desktop-20260806-004044`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-desktop-latest`

Packages installed or verified:

- `starship`
- `fzf`
- `flameshot`
- `clipmenu`
- `playerctl`
- `brightnessctl`
- `pavucontrol`
- `blueman`
- `lxappearance`
- `qt5ct`
- `qt6ct`
- `kvantum`
- `papirus-icon-theme`
- `capitaine-cursors`
- `materia-gtk-theme`
- `chafa`
- `poppler`
- `ffmpegthumbnailer`
- `mediainfo`
- `ueberzugpp`

Desktop configs installed for `guesswho`:

- BSPWM:
  - `/home/guesswho/.config/bspwm/bspwmrc`
- SXHKD:
  - `/home/guesswho/.config/sxhkd/sxhkdrc`
- Polybar:
  - `/home/guesswho/.config/polybar/config.ini`
- Picom:
  - `/home/guesswho/.config/picom/picom.conf`
- Dunst:
  - `/home/guesswho/.config/dunst/dunstrc`
- Alacritty:
  - `/home/guesswho/.config/alacritty/alacritty.toml`
- Rofi:
  - `/home/guesswho/.config/rofi/config.rasi`
- Ranger:
  - `/home/guesswho/.config/ranger/rc.conf`
  - `/home/guesswho/.config/ranger/scope.sh`
- Starship:
  - `/home/guesswho/.config/starship.toml`
- GTK/Qt basics:
  - `/home/guesswho/.config/gtk-3.0/settings.ini`
  - `/home/guesswho/.config/gtk-4.0/settings.ini`
  - `/home/guesswho/.config/qt5ct/qt5ct.conf`
  - `/home/guesswho/.config/qt6ct/qt6ct.conf`
  - `/home/guesswho/.config/Kvantum/kvantum.kvconfig`

Helper scripts installed:

- `/home/guesswho/.local/bin/brokenback-launch`
- `/home/guesswho/.local/bin/brokenback-polybar-launch`
- `/home/guesswho/.local/bin/brokenback-media-status`
- `/home/guesswho/.local/bin/brokenback-battery-status`
- `/home/guesswho/.local/bin/brokenback-bluetooth-status`
- `/home/guesswho/.local/bin/brokenback-clipmenu`
- `/home/guesswho/.local/bin/brokenback-session-menu`
- `/home/guesswho/.local/bin/brokenback-bluetooth-menu`

BSPWM changes:

- Kept workspaces:
  - `I II III IV V VI VII VIII IX X`
- Added:
  - `2px` borders,
  - `10px` window gaps,
  - `44px` top padding for the fixed bar,
  - cyan focused border,
  - peach presel feedback,
  - floating rules for utility windows.
- Startup now launches:
  - `sxhkd`,
  - `dunst`,
  - `picom`,
  - `blueman-applet`,
  - `clipmenud` guarded by the visible `clipnotify` process,
  - `flameshot`,
  - `brokenback-polybar-launch`,
  - existing `xss-lock` flow.
- Existing lock command remains:
  - `/usr/local/bin/brokenback-lock`

Polybar changes:

- Replaced the old `polybar example` bar with the custom `brokenback` bar.
- Bar is fixed at the top.
- Structure follows the user's reference image:
  - left: Arch/menu glyph, pinned app glyph shortcuts, BSPWM workspace dots,
  - center: current media title/artist through `playerctl`/MPRIS,
  - right: CPU, memory, Wi-Fi, volume, brightness, Bluetooth, battery, system tray, date, and time.
- App shortcut glyphs launch:
  - menu/Rofi,
  - Alacritty,
  - Ranger,
  - Firefox,
  - Neovim,
  - Btop.
- Uses Nerd Font glyphs instead of image icons for speed and stability.
- Uses modern `internal/tray` module instead of deprecated bar-level tray settings.
- Added Polybar log:
  - `/home/guesswho/.cache/brokenback/polybar.log`

Keybinds:

- `super + t`: open Alacritty.
- `super + r`: open Ranger in Alacritty.
- `alt + space`: open Rofi app launcher.
- `super + alt + space`: open Rofi run launcher.
- `ctrl + shift + v`: open Rofi clipboard menu.
- `ctrl + w`: close focused window globally.
- `super + arrow keys`: focus windows by direction.
- `super + shift + arrow keys`: move/swap windows by direction.
- `super + alt + arrow keys`: resize windows.
- `super + 1-9,0`: switch workspaces.
- `super + shift + 1-9,0`: send focused window to workspace.
- `super + Tab`: Rofi window switcher.
- `super + shift + e`: session menu.
- `super + shift + b`: Bluetooth menu.
- `super + shift + l`: lock screen.
- `Print`: Flameshot region screenshot.
- `XF86Audio*`: volume/mute through `wpctl`.
- `XF86MonBrightness*`: brightness through `brightnessctl`.
- Media keys:
  - play/pause,
  - previous,
  - next,
  - through `playerctl`.

Bluetooth changes:

- `bluetooth.service` enabled and active.
- `blueman-applet` autostarts in BSPWM.
- Added Rofi Bluetooth menu for:
  - opening Blueman manager,
  - power on/off,
  - scan on/off,
  - connecting/disconnecting paired devices.
- Polybar Bluetooth status is provided by:
  - `/home/guesswho/.local/bin/brokenback-bluetooth-status`

Cleanup:

- Removed stale `/home/guesswho/EOF`.
- Removed obsolete `/home/guesswho/.config/autostart.disabled` if present.
- Removed temporary Milestone 2 transfer archives/directories from `/tmp`.
- Did not remove `codexsetup`.
- Did not touch fingerprint, OLED pixel shifting, or final-hardware microcode.

Verification:

- Shell syntax passed for:
  - BSPWM config,
  - Ranger preview script,
  - all `brokenback-*` helper scripts.
- Rofi config dump passed.
- Starship config print passed.
- Picom diagnostics passed.
- Polybar started successfully as:
  - `polybar --config=/home/guesswho/.config/polybar/config.ini brokenback`
- Polybar loaded all 13 modules:
  - `apps`,
  - `bspwm`,
  - `media`,
  - `cpu`,
  - `memory`,
  - `wlan`,
  - `pulseaudio`,
  - `backlight`,
  - `bluetooth`,
  - `battery`,
  - `systray`,
  - `date`,
  - `time`.
- Polybar loaded fonts:
  - `SpaceMono Nerd Font Mono`,
  - `IBM Plex Sans` fallback for workspace dot glyphs.
- Session processes verified:
  - `bspwm`,
  - `sxhkd`,
  - `dunst`,
  - `picom`,
  - `blueman-applet`,
  - `clipnotify`,
  - `flameshot`,
  - `polybar`,
  - `xss-lock`.
- Clipboard daemon guard verified:
  - `clipnotify before=1 after=1` after rerunning BSPWM startup.
- Helper output verified:
  - media falls back to `no media`,
  - Bluetooth reports `on`,
  - battery reports about `57%`.
- `lightdm.service` remains enabled and active.
- `bluetooth.service` is enabled and active.
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.1: surface-dots Inspired Bar And Hub Port

Status: implemented on 2026-08-06. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Use `snes19xx/surface-dots` as direct design inspiration for the logged-in desktop shell.
- Keep the current BSPWM/X11 stack instead of adding the repo's Hyprland/Quickshell stack.
- Keep the user's existing wallpaper and BrokenBack cyan/peach dark palette.
- Match as much of the top-bar and hub behavior as possible without installing new applications.

Source reference:

- Repository cloned locally for inspection:
  - `C:\Users\aksha\OneDrive\Documents\Server and Setup\references\surface-dots`
- Main upstream reference:
  - `https://github.com/snes19xx/surface-dots`
- Relevant design areas inspected:
  - Quickshell top bar,
  - Quickshell hub cards,
  - power menu,
  - Rofi theme files,
  - top-bar screenshots.

Backup:

- Created before this port:
  - `/var/backups/codex/arch-milestone2-surface-port-20260806-130453`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-surface-port-latest`

Polybar changes:

- Replaced the single Milestone 2 top bar with four fixed top Polybar segments:
  - `brokenback-left`
  - `brokenback-center`
  - `brokenback-tray`
  - `brokenback-right`
- Left segment now mirrors the surface-dots structure more closely:
  - Arch/menu glyph,
  - compact pinned app glyphs,
  - BSPWM workspace dots.
- Center segment now shows:
  - active `playerctl` media title/artist when available,
  - focused window title when no media is active,
  - `Desktop` fallback when neither is available.
- Right segment now uses compact status chips for:
  - update count,
  - battery,
  - date,
  - time.
- Tray was moved into a small separate pill-style segment.
- Bar launch geometry is calculated dynamically from the active Polybar monitor width.
- Polybar log remains:
  - `/home/guesswho/.cache/brokenback/polybar.log`

Rofi/hub changes:

- Reworked the default Rofi theme into a compact surface-style launcher with:
  - bottom-left placement,
  - rounded search field,
  - local wallpaper header,
  - SpaceMono font,
  - BrokenBack dark/cyan/peach colors.
- Added a new hub theme:
  - `/home/guesswho/.config/rofi/surface-hub.rasi`
- Added a new hub menu script:
  - `/home/guesswho/.local/bin/brokenback-hub-menu`
- Hub opens from:
  - left Arch glyph click,
  - date/time click,
  - `super + space`
- Hub actions include:
  - Wi-Fi manager through `nmtui`,
  - Bluetooth menu,
  - volume panel through `pavucontrol`,
  - brightness bump through `brightnessctl`,
  - media play/pause through `playerctl`,
  - Dunst do-not-disturb toggle,
  - Flameshot screenshot,
  - power/session menu,
  - lock,
  - uptime/system status display.
- Session and Bluetooth menus now use the same `surface-hub.rasi` styling.

Keybind additions:

- `super + space`: open the surface-style hub.
- `super + q`: open Alacritty, matching the surface-dots terminal binding while keeping `super + t`.
- `super + b`: open Firefox.
- `super + x`: close focused window, alongside the requested global `ctrl + w`.
- `super + f`: toggle floating.
- `super + alt + f`: toggle floating and apply a larger utility-window size.
- `super + m`: toggle fullscreen.
- `alt + F4`: open the session/power menu.
- `super + Print`: full screenshot to clipboard.
- `super + shift + Print`: Flameshot region screenshot.

Fixes made during the port:

- Updated the clipboard startup guard to check the visible `clipnotify` process so `clipmenud` does not get spawned repeatedly.
- Kept LightDM/login/lock files untouched.
- Did not install Quickshell, Hyprland, Wayland portals, SDDM, new launchers, or extra applications.

Verification:

- Reloaded active BSPWM session pieces without rebooting.
- Active processes verified:
  - `bspwm`
  - `sxhkd`
  - `dunst`
  - `picom`
  - `blueman-applet`
  - `clipnotify`
  - `flameshot`
  - four `polybar` segments
  - `xss-lock`
- Polybar segments running:
  - `polybar --config=/home/guesswho/.config/polybar/config.ini brokenback-left`
  - `polybar --config=/home/guesswho/.config/polybar/config.ini brokenback-center`
  - `polybar --config=/home/guesswho/.config/polybar/config.ini brokenback-tray`
  - `polybar --config=/home/guesswho/.config/polybar/config.ini brokenback-right`
- Polybar loaded the expected fonts:
  - `SpaceMono Nerd Font Mono`
  - `IBM Plex Sans`
- Helper output verified:
  - center fallback: `Desktop`
  - updates: `0`
  - media fallback: `no media`
  - battery: about `55%`
  - Bluetooth: `on`
- Required commands present:
  - `polybar`
  - `rofi`
  - `playerctl`
  - `bluetoothctl`
  - `brightnessctl`
  - `wpctl`
  - `flameshot`
  - `clipnotify`
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.2: Workspace Pill, Rounded Status Pills, Hub Fixes

Status: implemented on 2026-08-06. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Refine the Milestone 2.1 surface-style bar after physical-screen review.
- Make the left side a pure workspace pill.
- Make the right side separate rounded status pills with a far-right hub button.
- Fix Rofi launcher parsing, quiet hub cancellation, and Flameshot screenshot capture.
- Keep the milestone config-only: no new packages or daily apps added.

Backup:

- Created before this polish:
  - `/var/backups/codex/arch-milestone2-bar-polish-20260806-134552`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-bar-polish-latest`

Workspace/bar changes:

- Removed the visible Arch/menu glyph from the left bar.
- Removed pinned app launcher icons from the left bar.
- Replaced Polybar's built-in BSPWM workspace module with:
  - `/home/guesswho/.local/bin/brokenback-workspaces-status`
- Workspace display behavior:
  - empty workspace: muted hollow dot,
  - focused empty workspace: cyan filled dot,
  - terminal-only workspace: occupied dot,
  - first non-terminal app on a workspace: app glyph instead of the dot.
- App class detection uses:
  - `bspc`,
  - `xprop`,
  - POSIX shell tools.
- No `jq` or new packages are required.

Right-side pill changes:

- Removed the Polybar tray segment:
  - no visible Bluetooth tray icon,
  - no visible Flameshot tray icon.
- Kept Bluetooth accessible through:
  - `super + shift + b`,
  - the hub menu.
- Kept screenshots accessible through:
  - `Print`,
  - `super + Print`,
  - `super + shift + Print`,
  - the hub menu.
- Split the right side into separate rounded Polybar bars:
  - `brokenback-updates`,
  - `brokenback-battery`,
  - `brokenback-date`,
  - `brokenback-time`,
  - `brokenback-hub`.
- Added far-right hub button:
  - left click opens `brokenback-hub-menu`,
  - right click opens `brokenback-session-menu`.

Typography/design changes:

- Increased Polybar height from `40` to `44`.
- Increased Polybar fonts by 2pt:
  - main text `10 -> 12`,
  - icon font `12 -> 14`,
  - large glyph font `15 -> 17`.
- Switched Polybar SpaceMono font entries to `style=Bold`.
- Removed square module backgrounds from right-side status modules.
- Rounded shape is now provided by the individual status bar segments.

Rofi/hub fixes:

- Removed unsupported `linear-gradient(...)` from:
  - `/home/guesswho/.config/rofi/config.rasi`
- Removed duplicate Rofi `Right`/`Left` mode bindings.
- Rofi launcher and hub themes now parse cleanly.
- Updated `/home/guesswho/.local/bin/brokenback-hub-menu` so Escape/cancel exits quietly.
- Hub screenshot action now calls:
  - `brokenback-screenshot area`

Flameshot fixes:

- Stopped autostarting the persistent Flameshot tray daemon from BSPWM.
- Added:
  - `/home/guesswho/.config/flameshot/flameshot.ini`
- Set Flameshot to use X11 legacy screenshot capture:
  - `useX11LegacyScreenshot=true`
- Added screenshot wrapper:
  - `/home/guesswho/.local/bin/brokenback-screenshot`
- Updated screenshot keybinds:
  - `Print`: `brokenback-screenshot area`
  - `super + Print`: `brokenback-screenshot full`
  - `super + shift + Print`: `brokenback-screenshot area-clipboard`

Verification:

- Shell syntax passed for BSPWM, Ranger preview, and all `brokenback-*` helper scripts.
- Rofi parse checks passed for:
  - `/home/guesswho/.config/rofi/config.rasi`
  - `/home/guesswho/.config/rofi/surface-hub.rasi`
- Active Polybar segments after reload:
  - `brokenback-left`
  - `brokenback-center`
  - `brokenback-updates`
  - `brokenback-battery`
  - `brokenback-date`
  - `brokenback-time`
  - `brokenback-hub`
- Polybar loaded bold SpaceMono Nerd Font Mono at the new sizes.
- Helper outputs verified:
  - workspace pill markup generated correctly,
  - center fallback: `Desktop`,
  - updates: `0`,
  - battery: about `55%`.
- Flameshot raw capture smoke test passed with X11 capture.
- No persistent `flameshot` daemon was running after reload.
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.3: Type 6 Rofi Launcher, Blur, Hub Button Fix, Media-Only Center

Status: implemented on 2026-08-06. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Rework the app launcher using `adi1090x/rofi` Launcher Type 6 as the layout reference.
- Keep the user's wallpaper, SpaceMono font, and BrokenBack cyan/peach dark palette.
- Blur/dim the desktop while the app launcher is open.
- Fix the far-right hub/menu button and make its icon more visible.
- Make the center bar show only active media, including paused media.

Source reference:

- Repository cloned locally for inspection:
  - `C:\Users\aksha\OneDrive\Documents\Server and Setup\references\adi1090x-rofi`
- Main upstream reference:
  - `https://github.com/adi1090x/rofi`
- Adapted area:
  - `files/launchers/type-6`
- The full Adi Rofi ecosystem was not installed on Arch.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-rofi-type6-20260806-143846`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-rofi-type6-latest`

Rofi launcher changes:

- Added local Type 6 launcher wrapper:
  - `/home/guesswho/.config/rofi/launchers/type-6/launcher.sh`
- Added BrokenBack Type 6 theme:
  - `/home/guesswho/.config/rofi/launchers/type-6/style-brokenback.rasi`
- Added helper:
  - `/home/guesswho/.local/bin/brokenback-rofi-launcher`
- Launcher uses:
  - centered Type 6 two-panel card,
  - wallpaper/image panel on the left,
  - app/result list on the right,
  - local home wallpaper,
  - Papirus app icons,
  - SpaceMono Nerd Font Mono Bold,
  - BrokenBack dark/cyan/peach colors.
- Launcher modes kept:
  - `drun`,
  - `run`,
  - `filebrowser`,
  - `window`.

Keybind/helper changes:

- `alt + space` now opens:
  - `brokenback-rofi-launcher drun`
- `super + alt + space` now opens:
  - `brokenback-rofi-launcher run`
- `super + Tab` now opens:
  - `brokenback-rofi-launcher window`
- `brokenback-launch menu` now routes to the Type 6 launcher.
- Clipboard and hub menus keep their existing compact/hub themes.

Picom blur changes:

- Enabled background blur with the existing GLX backend.
- Added lightweight dual-kawase blur:
  - `blur-method = "dual_kawase"`
  - `blur-strength = 3`
- Kept dock/desktop windows excluded from blur.
- The launcher theme provides a fullscreen transparent/dim Rofi window with the centered Type 6 card.

Hub button changes:

- Increased the far-right hub pill width from `48` to `60`.
- Increased the hub glyph visibility by rendering it with Polybar's largest font slot.
- Embedded click actions directly into the hub glyph:
  - left click: `/home/guesswho/.local/bin/brokenback-hub-menu`
  - right click: `/home/guesswho/.local/bin/brokenback-session-menu`

Center bar changes:

- Updated:
  - `/home/guesswho/.local/bin/brokenback-center-status`
- Center bar now shows media only when `playerctl` reports:
  - `Playing`
  - `Paused`
- Removed:
  - focused-window title fallback,
  - `Desktop` fallback.
- Center output is blank when no player exists or media is stopped.

Verification:

- Shell syntax passed for:
  - Type 6 launcher wrapper,
  - all `brokenback-*` helpers.
- Rofi parse checks passed for:
  - Type 6 launcher theme,
  - hub theme,
  - default/clipboard-compatible config.
- Picom diagnostics accepted the updated blur config.
- Reloaded:
  - Picom,
  - SXHKD,
  - Polybar.
- Active processes verified:
  - `picom --config /home/guesswho/.config/picom/picom.conf`
  - `sxhkd`
  - seven Polybar segments.
- Type 6 launcher smoke test passed:
  - opened through `brokenback-rofi-launcher drun`,
  - no parser/runtime errors,
  - closed by timeout as expected.
- Center helper output was blank with no active media.
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.4: Window Count Menu Chip, Larger Bar Icons, Compact Launcher

Status: implemented on 2026-08-06. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Repurpose the peach chip beside battery from package updates to global window count.
- Make the peach count chip open the hub menu.
- Remove the separate far-right hub/menu bar segment.
- Make bar glyphs visually consistent with the former large hub icon.
- Make the Type 6 launcher a compact centered card instead of a fullscreen overlay.
- Keep the current Rofi hub for now, and defer real slider widgets to a later richer-hub milestone.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-window-count-menu-20260806-151956`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-window-count-menu-latest`

Bar/window-count changes:

- Added:
  - `/home/guesswho/.local/bin/brokenback-window-count-status`
- The helper counts all BSPWM-managed windows, including terminal windows, with:
  - `bspc query -N -n .window | wc -l`
- Rewired the peach status chip beside battery:
  - old helper: `/home/guesswho/.local/bin/brokenback-update-status`
  - new helper: `/home/guesswho/.local/bin/brokenback-window-count-status`
- Removed the old package-update click action:
  - `sudo pacman -Syu`
- Added the new click action:
  - left click opens `/home/guesswho/.local/bin/brokenback-hub-menu`
- Kept the internal Polybar segment name `brokenback-updates` for continuity, but its visible role is now the window-count/menu chip.
- Removed the separate far-right hub/menu segment from active Polybar launch:
  - `[bar/brokenback-hub]`
  - `[module/hub]`
  - related hub width/offset launch calculations

Larger icon changes:

- Updated bar helper output to use Polybar font slot `T3` for larger glyphs.
- Applied this to:
  - workspace dots/app glyphs,
  - window-count chip glyph,
  - battery glyph,
  - center media glyph.
- Text remains on the existing bold SpaceMono bar font.

Launcher changes:

- Updated:
  - `/home/guesswho/.config/rofi/launchers/type-6/style-brokenback.rasi`
- The Type 6 launcher is now a compact centered card instead of fullscreen:
  - total width: about `760px`
  - wallpaper/image panel: about `270px`
  - list panel: about `490px`
  - visible result rows: `6`
- Kept:
  - home wallpaper image panel,
  - BrokenBack color palette,
  - SpaceMono Nerd Font Mono,
  - Papirus icons,
  - Picom blur support.

Hub changes:

- Updated:
  - `/home/guesswho/.local/bin/brokenback-hub-menu`
- Added package update count as a hub row instead of a bar chip.
- Added a hub action for the updates row that opens an Alacritty pacman upgrade prompt.
- Stripped Polybar formatting tags from status helper output before showing those values inside the Rofi hub.
- Confirmed the current hub remains Rofi/list based; real volume/brightness sliders are deferred because Rofi does not provide native slider widgets.

Verification:

- Shell syntax passed for:
  - Type 6 launcher wrapper,
  - all `brokenback-*` helpers.
- Rofi parse checks passed for:
  - `/home/guesswho/.config/rofi/launchers/type-6/style-brokenback.rasi`
  - `/home/guesswho/.config/rofi/surface-hub.rasi`
- Active Polybar segments after reload:
  - `brokenback-left`
  - `brokenback-center`
  - `brokenback-updates`
  - `brokenback-battery`
  - `brokenback-date`
  - `brokenback-time`
- Confirmed no `brokenback-hub` Polybar segment is running.
- Window-count helper output verified:
  - `0` windows at final check
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.5: Bar Overflow Fix And Eww Control Hub

Status: implemented on 2026-08-06. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Fix the left workspace pill clipping after the large icon bump.
- Replace the broken Rofi hub entrypoint with an Eww top-right control hub.
- Keep the peach window-count chip as the main hub button.
- Make package update information read-only inside the hub.
- Keep LightDM, login, and lock behavior untouched.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-eww-hub-20260806-162223`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-eww-hub-latest`
- The backup also records package state before and after the Eww install.

Package changes:

- Installed stable AUR package:
  - `eww 0.6.0-1`
- Build/runtime dependencies pulled by the package include Rust and GTK layer-shell/dbusmenu dependencies.
- Removed orphaned split package after install:
  - `eww-debug`

Bar changes:

- Increased the left workspace pill width calculation:
  - from `clamp(screen_w / 5, 280, 360)`
  - to `clamp(screen_w / 4, 360, 440)`
- Tightened workspace helper output by removing extra spaces around each glyph.
- Kept the left bar workspace-only.
- Rewired bar hub entrypoints to:
  - `/home/guesswho/.local/bin/brokenback-hub-toggle`
- Updated entrypoints:
  - peach window-count chip,
  - date chip,
  - time chip,
  - `super + space`.

Eww hub changes:

- Added Eww config:
  - `/home/guesswho/.config/eww/brokenback-hub/`
- Added helper:
  - `/home/guesswho/.local/bin/brokenback-hub-toggle`
- Added hub scripts:
  - `hub-state`
  - `hub-set`
  - `hub-action`
- Hub opens as a top-right floating panel below the bar.
- Styling uses:
  - SpaceMono Nerd Font Mono,
  - BrokenBack dark/cyan/peach palette,
  - rounded cards/buttons,
  - subtle transparent dark shell.
- Hub contents:
  - volume slider through `wpctl`,
  - brightness slider through `brightnessctl`,
  - media controls through `playerctl`,
  - quick actions for Wi-Fi, Bluetooth, screenshot, DND, lock, and power/session menu,
  - status rows for battery, network, windows, update count, and DND.

Fallback hub changes:

- Kept the old Rofi hub helper as a fallback:
  - `/home/guesswho/.local/bin/brokenback-hub-menu`
- Removed its old update action completely:
  - no `sudo pacman -Syu`
  - no accidental sudo prompt from the fallback hub.

Verification:

- Shell syntax passed for payload helper scripts before install.
- Eww hub smoke test passed:
  - daemon started,
  - `brokenback_hub` opened,
  - active window listed,
  - closed cleanly.
- Removed the initial unsupported Eww `:truncate` attributes after parser warnings.
- Final Eww toggle path passed:
  - `/home/guesswho/.local/bin/brokenback-hub-toggle`
- Same-value volume and brightness setter checks passed.
- Reloaded:
  - `sxhkd`,
  - six Polybar segments.
- Active Polybar segments after reload:
  - `brokenback-left`
  - `brokenback-center`
  - `brokenback-updates`
  - `brokenback-battery`
  - `brokenback-date`
  - `brokenback-time`
- Confirmed the old fallback hub contains no `pacman` update action.
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Current Known State

- `lightdm.service`: enabled and active at the latest Milestone 2.5 verification.
- Failed systemd units: none at the last successful Milestone 2.5 checks.
- Active theme path: `/usr/share/lightdm-webkit/themes/brokenback`.
- Active LightDM seat config: `/etc/lightdm/lightdm.conf.d/50-brokenback.conf`.
- Active WebKit greeter config: `/etc/lightdm/lightdm-webkit2-greeter.conf`.
- Active BSPWM config: `/home/guesswho/.config/bspwm/bspwmrc`.
- Active lock wrapper: `/usr/local/bin/brokenback-lock`.
- Inactive display setup rollback helper removed:
  - `/usr/local/bin/brokenback-lightdm-display-setup`
- Active initramfs is the small non-KMS profile, with `/boot` available through automount.
- SpaceMono Nerd Font installed and active through fontconfig.
- Login greeter is pinned to local theme fonts through `BrokenbackSpaceMono`.
- Lockscreen clock and unlock hint use `SpaceMono Nerd Font Mono`.
- GRUB timeout: `1` second.
- X blanking/DPMS: disabled through LightDM and BSPWM config.
- Duplicate XDG `xss-lock` autostart: disabled/moved out of active autostart.
- Old `greetd`/`regreet` stack: removed.
- Current running system is on the cloned target root UUID `1030b9ff-c5b6-4f81-9db5-5b3b45bbb272`; the kernel currently enumerates it as `/dev/sdc3`.
- New cloned target drive: model `INSPIRE`, root UUID `1030b9ff-c5b6-4f81-9db5-5b3b45bbb272`.
- Login/lock wallpaper source: `/home/guesswho/Pictures/wallpaper/login/wallpaper.jpg`.
- Home wallpaper source: `/home/guesswho/Pictures/wallpaper/home/wallpaper.jpg`.
- Greeter wallpaper deployed copy: `/usr/share/lightdm-webkit/themes/brokenback/wallpaper.jpg`.
- Lock wrapper now bypasses Betterlockscreen's default lock UI and calls `i3lock-color` directly with transparent input feedback, seconds in the clock, and the hint text `type your password to unlock`.
- Active Milestone 2.5 bar config: `/home/guesswho/.config/polybar/config.ini`.
- Active Milestone 2.5 bar processes:
  - `brokenback-left`
  - `brokenback-center`
  - `brokenback-updates`
  - `brokenback-battery`
  - `brokenback-date`
  - `brokenback-time`
- Active Milestone 2.5 launcher/theme: `/home/guesswho/.config/rofi/config.rasi`.
- Active Milestone 2.5 Eww hub config: `/home/guesswho/.config/eww/brokenback-hub/`.
- Active Milestone 2.5 hub toggle helper: `/home/guesswho/.local/bin/brokenback-hub-toggle`.
- Active Milestone 2.5 fallback Rofi hub helper: `/home/guesswho/.local/bin/brokenback-hub-menu`.
- Active Milestone 2.5 workspace helper: `/home/guesswho/.local/bin/brokenback-workspaces-status`.
- Active Milestone 2.5 window-count helper: `/home/guesswho/.local/bin/brokenback-window-count-status`.
- Active Milestone 2.5 screenshot helper: `/home/guesswho/.local/bin/brokenback-screenshot`.
- Active Milestone 2.5 Flameshot config: `/home/guesswho/.config/flameshot/flameshot.ini`.
- Active Milestone 2.5 launcher helper: `/home/guesswho/.local/bin/brokenback-rofi-launcher`.
- Active Milestone 2.5 Type 6 launcher theme:
  - `/home/guesswho/.config/rofi/launchers/type-6/style-brokenback.rasi`
- Active Milestone 2.5 Picom blur config:
  - `/home/guesswho/.config/picom/picom.conf`
- Active Milestone 2.5 added package:
  - `eww 0.6.0-1`
- Active Milestone 2 terminal theme: `/home/guesswho/.config/alacritty/alacritty.toml`.
- Active Milestone 2 notification theme: `/home/guesswho/.config/dunst/dunstrc`.
- Active Milestone 2 compositor theme: `/home/guesswho/.config/picom/picom.conf`.
- Active Milestone 2 backups to keep until acceptance:
  - `/var/backups/codex/arch-milestone2-desktop-20260806-004044`
  - `/var/backups/codex/arch-milestone2-surface-port-20260806-130453`
  - `/var/backups/codex/arch-milestone2-bar-polish-20260806-134552`
  - `/var/backups/codex/arch-milestone2-rofi-type6-20260806-143846`
  - `/var/backups/codex/arch-milestone2-window-count-menu-20260806-151956`
  - `/var/backups/codex/arch-milestone2-eww-hub-20260806-162223`

## Milestone 2.6: Eww Hub Rebuild, Weather Integration & Split Layout

Purpose: split the Eww hub into two separate menus (Control Settings and Calendar/Weather), space out workspace dots and add focused workspace pills, add TUI app/terminal icon detection, cache last played media, and fix Rofi button height alignment and Picom dual-kawase blur.

Packages installed or verified:
- `brightnessctl` (with new udev rules)
- `xorg-xprop`

System changes:
- Created and deployed `/etc/udev/rules.d/90-backlight.rules` to allow `guesswho` to write to the brightness backlight interface without root.
- Reloaded udev rules and triggered backlight subsystem.
- Added `export PATH="/home/guesswho/.local/bin:$PATH"` at the top of Eww helper scripts `hub-action`, `hub-set`, and `hub-state` to fix script execution paths.
- Tweaked `picom.conf` to set Rofi window class to 90 opacity and increased `blur-strength` to `6` to make dual-kawase blur clearly visible.

Polybar changes:
- Combined `brokenback-date` and `brokenback-time` into a single `brokenback-datetime` pill.
- Renamed `brokenback-updates` to `brokenback-windowcount` and changed its background color to the theme's peach color (`#ffb08a`).
- Modified `brokenback-polybar-launch` to handle repositioning and width calculation for the new pills layout.
- Modified `brokenback-center-status` to write last played media to `~/.cache/brokenback/last-media.txt` and display it with a stopped `` icon when the player is off.
- Rebuilt `brokenback-workspaces-status` to add margins/spacing between icons and wrap the active workspace in round powerline glyphs (`` and ``). Added child PID querying (`xprop` + `pgrep`) to detect `nvim`/`neovim` (shows ``) or `nmtui` (shows `󰖩`), and display a terminal icon (``) if only terminals are open.

Eww changes:
- Defined `brokenback_hub` Control Hub (quick setting toggles, vertical volume/brightness sliders, package update count, avatar header with actions).
- Defined `brokenback_calendar_hub` Calendar Hub (date, calendar widget, weather panel, upcoming events/notifications).
- Integrated `hub-weather` background script to fetch weather once every 30 mins from `wttr.in` and cache it in `~/.cache/brokenback/weather.json`.
- Created fullscreen transparent windows `brokenback_hub_background` and `brokenback_calendar_background` for click-outside-to-close behavior.
- Created `/home/guesswho/.local/bin/brokenback-calendar-toggle` to toggle the calendar hub, and updated `brokenback-hub-toggle` to toggle the control hub.

Rofi changes:
- Standardized vertical alignment (`vertical-align: 0.5; horizontal-align: 0.5`) in `style-brokenback.rasi` for `.button` elements.

Verification:
- eww config checks passed.
- Settings Control Hub toggles and clears Calendar Hub.
- Calendar Hub toggles and clears Settings Hub.
- Spacing and rounded wrappers confirmed on workspace status scripts.

## Milestone 2.7: Hub Edge Fix And True Rounded Workspace Pill

Status: implemented on 2026-08-26. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Fix the two reported UI issues:
  - Control Hub and Calendar Hub clipping past the right screen edge.
  - active workspace highlight looking rectangular instead of truly rounded.
- Preserve the existing login, lock screen, Rofi launcher, center media, and right status behavior.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-hub-workspace-fix-20260826-172415`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-hub-workspace-fix-latest`

Remote access change:

- Created a persistent Windows-side setup key and SSH alias:
  - key: `C:\Users\aksha\.ssh\brokenback_codex_ed25519`
  - alias: `brokenback-arch`
- The alias targets:
  - `codexsetup@169.254.171.2`
- This avoids recreating temporary SSH keys from `%TEMP%` every session.

Eww hub changes:

- Changed both hubs to stay inside the right screen edge:
  - `brokenback_hub`: top-right anchor with `x="-16px"`, `y="54px"`, `360x330`.
  - `brokenback_calendar_hub`: top-right anchor with `x="-16px"`, `y="54px"`, `380x460`.
- Kept the fullscreen transparent click-outside background overlays.
- Updated hub actions so closing the Control Hub also closes `brokenback_hub_background`.
- Updated hub toggles so the Eww daemon starts only if needed.

Workspace bar changes:

- Added Eww-owned persistent left workspace window:
  - `brokenback_workspaces`
- Added workspace state helper:
  - `/home/guesswho/.local/bin/brokenback-workspaces-eww-state`
- Added Eww launcher helper:
  - `/home/guesswho/.local/bin/brokenback-eww-launch`
- The active workspace now uses real GTK/CSS `border-radius`, not Polybar powerline glyphs.
- Workspace states remain:
  - empty workspace: hollow dot,
  - terminal-only workspace: terminal icon,
  - Neovim in terminal: Neovim icon,
  - `nmtui` in terminal: network icon,
  - first non-terminal app: mapped app icon.

Polybar/reload changes:

- Stopped launching the old `brokenback-left` Polybar bar.
- Active Polybar is now center/right only:
  - `brokenback-center`
  - `brokenback-windowcount`
  - `brokenback-battery`
  - `brokenback-datetime`
- Added reload-only desktop helper:
  - `/home/guesswho/.local/bin/brokenback-desktop-reload`
- Updated the installer to reload the active desktop session without restarting LightDM.
- Fixed copied directory permissions so `/home/guesswho/.config` and `/home/guesswho/.local` remain writable by `guesswho`.

Verification:

- Permanent SSH alias worked after the public key was corrected on the Arch side.
- Remote backup completed before install.
- Shell syntax passed on the staged payload and installed helpers.
- Installed with reload-only behavior:
  - no `systemctl restart lightdm`.
- Eww active windows after reload:
  - `brokenback_workspaces`
- Hub toggle check:
  - opens `brokenback_hub` plus `brokenback_hub_background`,
  - closes both cleanly.
- Calendar toggle check:
  - opens `brokenback_calendar_hub` plus `brokenback_calendar_background`,
  - closes both cleanly.
- Workspace helper one-shot output showed workspace `I` focused with a terminal icon and other workspaces empty.
- Confirmed active Polybar processes exclude `brokenback-left`.
- Confirmed fixed permissions:
  - `/home/guesswho/.config`: `drwxr-xr-x`
  - `/home/guesswho/.local`: `drwxr-xr-x`
  - `/home/guesswho/.local/bin`: `drwxr-xr-x`
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.8: Hub Readability, Workspace Text Fix, And Terminal Blur

Status: implemented on 2026-08-26. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Fix the three reported UI issues:
  - Control/Calendar Hub text and icons were too small.
  - Workspace icons were rendering with visible quote marks and the active state looked like text instead of a pill.
  - Alacritty transparency/blur was too subtle, and the Rofi `FILES` mode tab looked wider than the other tabs.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-visual-polish-20260826-202458`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-visual-polish-latest`

Eww hub changes:

- Increased the Control Hub window to `430x460`.
- Increased the Calendar Hub window to `430x520`.
- Increased hub text and icon sizes across quick toggles, header action buttons, close buttons, updates card, calendar title/date/weather, and notification/event rows.
- Made hub text/icons bold through the shared Eww CSS base.
- Increased vertical slider trough width and height so volume and brightness use more of the panel area.
- Enlarged the avatar/header area to match the stronger typography.

Workspace pill changes:

- Replaced per-label Eww `jq(...)` interpolation with generated Eww `literal` markup from `/home/guesswho/.local/bin/brokenback-workspaces-eww-state --markup`.
- Added `--markup` and `--markup-once` modes to the workspace helper.
- This removes literal quote marks around workspace icons and lets CSS classes apply normally.
- Widened the workspace Eww window to `442px`.
- Tightened workspace button spacing while making the focused workspace a wider rounded accent pill.

Rofi/Picom/Alacritty changes:

- Changed Alacritty opacity from `0.94` to `0.88`.
- Changed Picom Alacritty opacity rule from `94` to `88`.
- Increased Picom dual-kawase blur strength from `6` to `8`.
- Set fixed `54px` width on Type 6 Rofi mode buttons so `APPS`, `RUN`, `FILES`, and `WINDOW` render with matching tab sizes.

Deployment notes:

- Added local helper `remote-scripts/arch/milestone2-desktop/backup-milestone2-visual-polish.sh` for targeted remote backups.
- Added local helper `remote-scripts/arch/milestone2-desktop/deploy-payload-from-tar.sh` so future tar payloads extract as root and avoid permission issues with hidden config directories.
- The first non-root tar extraction attempt failed on hidden config directory permissions, then the corrected root-extraction deployment succeeded.
- LightDM was not restarted.

Verification:

- Remote backup completed before install.
- Corrected payload installed with desktop reload-only behavior.
- Shell syntax passed for installed helper scripts.
- Workspace helper `--markup-once` produced unquoted Eww button markup.
- Eww active-window checks passed:
  - Control Hub opens with `brokenback_hub` and `brokenback_hub_background`, then closes back to `brokenback_workspaces`.
  - Calendar Hub opens with `brokenback_calendar_hub` and `brokenback_calendar_background`, then closes back to `brokenback_workspaces`.
- Rofi Type 6 theme parse check passed.
- Picom config diagnostics passed.
- Deployed Alacritty/Picom values confirmed:
  - Alacritty `opacity = 0.88`
  - Picom blur `strength = 8`
  - Picom Alacritty opacity rule `88`
- Active desktop processes confirmed:
  - `sxhkd`
  - `eww`
  - `picom`
  - `dunst`
  - Polybar `brokenback-center`, `brokenback-windowcount`, `brokenback-battery`, and `brokenback-datetime`
- No failed system units were reported.
- No failed `guesswho` user units were reported.
- Lock wrapper syntax still passes.

## Milestone 2.9: Rofi Full-Background Blur And Stable Type 6 Shape

Status: implemented on 2026-08-26. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Fix two reported Rofi launcher issues:
  - opening Rofi did not blur the whole desktop background,
  - switching to the `FILES` mode kept the tab size correct but changed the launcher card shape.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-rofi-blur-shape-20260826-213900`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-rofi-blur-shape-latest`

Rofi blur changes:

- Added temporary Eww window `brokenback_rofi_blur`.
- The blur layer is fullscreen, non-focusable, WM-ignored, and styled with a subtle dark transparent background.
- Updated `/home/guesswho/.config/rofi/launchers/type-6/launcher.sh` so every Type 6 launcher mode:
  - starts the Eww daemon if needed,
  - closes any open Control/Calendar Hub overlays,
  - opens `brokenback_rofi_blur`,
  - launches Rofi,
  - closes the blur layer on exit/cancel/termination.
- Kept the launcher itself compact and centered.

Rofi shape changes:

- Fixed Type 6 launcher geometry:
  - window height `430px`,
  - mainbox height `430px`,
  - imagebox height `430px`,
  - listbox height `430px`,
  - listview height `300px`.
- Changed listview `dynamic` from `true` to `false`, so modes with fewer/different results do not resize the card.
- Kept fixed `54px` mode buttons from Milestone 2.8.

Deployment notes:

- Added local test helper:
  - `remote-scripts/arch/milestone2-desktop/test-rofi-overlay.sh`
- Deployed through the existing root-extraction helper:
  - `remote-scripts/arch/milestone2-desktop/deploy-payload-from-tar.sh`
- LightDM was not restarted.

Verification:

- Remote backup completed before install.
- Rofi Type 6 theme parse check passed.
- Rofi launcher shell syntax passed.
- Eww config reload passed.
- Picom config diagnostics passed.
- Live Rofi `filebrowser` test confirmed:
  - `brokenback_rofi_blur` opens while Rofi is active,
  - Rofi process starts in `filebrowser` mode,
  - blur overlay closes afterward.
- No leftover Rofi process or blur overlay remained after testing.
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.10: Polybar Default Workspace Dots

Status: implemented on 2026-08-27. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Follow the user's request to stop using the Eww workspace pill and return the left workspace bar to Polybar.
- Remove the rounded active workspace highlight entirely.
- Use simple Polybar BSPWM workspace dots instead of generated app/TUI icons.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-polybar-workspaces-20260827-000412`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-polybar-workspaces-latest`
- The backup was augmented to include the old `/home/guesswho/.local/bin/brokenback-workspaces-eww-state` helper before it was removed.

Polybar changes:

- Replaced the left workspace custom script module with Polybar's built-in `internal/bspwm` module.
- Workspace rendering is now:
  - focused workspace: accent filled dot,
  - occupied workspace: foreground hollow dot,
  - empty workspace: muted hollow dot,
  - urgent workspace: danger hollow dot.
- Removed per-workspace rounded/powerline highlight behavior from the active display path.
- `brokenback-polybar-launch` once again launches `brokenback-left`.
- Left workspace pill width now clamps around `260-320px`, which is enough for default dots without the oversized Eww workspace strip.

Eww cleanup:

- Removed the persistent `brokenback_workspaces` Eww window from the hub config.
- Removed `workspaces_markup` and `workspaces-layout` from the Eww config.
- Removed workspace-specific CSS classes from the Eww SCSS.
- Updated `brokenback-eww-launch` to close stale `brokenback_workspaces` windows and not reopen them.
- Removed unused `/home/guesswho/.local/bin/brokenback-workspaces-eww-state` from the deployed Arch system.
- Eww remains in use for:
  - Control Hub,
  - Calendar Hub,
  - temporary Rofi fullscreen blur layer.

Deployment notes:

- Added local backup helper:
  - `remote-scripts/arch/milestone2-desktop/backup-milestone2-polybar-workspaces.sh`
- Rebuilt the payload after removing the unused Eww workspace helper.
- Deployed through the root-extraction helper.
- LightDM was not restarted.

Verification:

- Active Polybar processes now include:
  - `brokenback-left`,
  - `brokenback-center`,
  - `brokenback-windowcount`,
  - `brokenback-battery`,
  - `brokenback-datetime`.
- Eww active windows are empty after cleanup; no persistent Eww workspace window remains.
- Deployed Polybar config uses `type = internal/bspwm` for `module/workspaces`.
- Installed helper shell syntax passed.
- Old Eww workspace helper removal was confirmed.
- Rofi theme parse still passed.
- Eww config reload still passed.
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.10.1: Polybar Workspace Icons And Width Nudge

Status: implemented on 2026-08-27. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Keep the left workspace bar owned by Polybar.
- Restore app/TUI icon detection inside the Polybar workspace pill.
- Keep the active workspace highlight simple, with no rounded/powerline capsule.
- Widen the left pill slightly so the last workspace item does not overflow.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-polybar-icons-20260827-003502`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-polybar-icons-latest`

Polybar changes:

- Changed `module/workspaces` back to the existing `brokenback-workspaces-status` custom script.
- Kept workspace rendering inside Polybar; Eww still does not own the workspace strip.
- Removed the old focused workspace powerline cap styling from `brokenback-workspaces-status`.
- Focused empty workspace now shows only the accent filled dot.
- Focused occupied workspace now shows only the detected app/TUI icon in accent color.
- Non-focused empty workspaces stay muted hollow dots.
- Non-focused terminal-only workspaces show the terminal glyph.
- Workspaces with Neovim, `nmtui`, Firefox, file managers, system monitors, Rofi/dialog tools, or unknown GUI apps keep their app-aware glyphs.
- Reduced inter-item spacing slightly.
- Increased left Polybar width clamp from `260-320px` to `320-380px`.

Deployment notes:

- Rebuilt and deployed the Milestone 2 desktop payload.
- Reloaded the active desktop session only.
- LightDM was not restarted.

Verification:

- Active Polybar processes include `brokenback-left`, `brokenback-center`, `brokenback-windowcount`, `brokenback-battery`, and `brokenback-datetime`.
- Deployed Polybar config uses `type = custom/script` and executes `~/.local/bin/brokenback-workspaces-status`.
- Deployed `brokenback-polybar-launch` uses `left_w="$(clamp $((screen_w / 4)) 320 380)"`.
- Deployed workspace script contains no ``/`` rounded powerline highlight glyphs.
- Helper shell syntax passed.
- Polybar log check reported no errors.
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.10.4: Main Hub Header And Action Row Cleanup

Status: implemented on 2026-08-27. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Remove the stats and settings buttons from the top of the main Control Hub.
- Add Screenshot and Stats buttons between the sliders and update row.
- Match the top lock, power, and close icon size to the Polybar large icon size.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-eww-main-hub-layout-20260827-011608`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-eww-main-hub-layout-latest`

Changes:

- Increased `brokenback_hub` height from `460px` to `510px`.
- Removed the top `btop` stats button.
- Removed the top `lxappearance` settings button.
- Kept only lock, power, and close in the top header actions.
- Added a two-button action row above Updates:
  - Screenshot opens `hub-action screenshot`,
  - Stats opens `hub-action stats`.
- Added `stats)` support to `hub-action`, which opens `alacritty -e btop`.
- Set `.action-btn` and `.close-circle-btn` icon font size to `17px`.

Verification:

- `hub-action` shell syntax passed.
- Eww reload passed.
- `brokenback_hub` opened and closed successfully.
- Eww log check reported no errors.
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.10.5: Main Hub Icon-Only Action Tiles

Status: implemented on 2026-08-27. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Make the top lock, power, and close icons visibly larger and bolder.
- Move Screenshot and Stats into the empty area under the sliders.
- Make Screenshot and Stats icon-only rounded square tiles aligned beside the Notify tile.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-eww-hub-icon-actions-20260827-012606`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-eww-hub-icon-actions-latest`

Changes:

- Moved the Screenshot and Stats buttons into a new `right-controls` column under the sliders.
- Removed visible Screenshot and Stats text labels from the main hub.
- Reduced vertical slider trough height from `230px` to `190px` to make room for the icon tiles.
- Added icon-only `mid-action-btn` tiles sized around the Notify tile height.
- Increased `.action-btn` and `.close-circle-btn` icon font size to `24px`.
- Increased action tile icons to `28px`.

Verification:

- Eww reload passed after daemon restart.
- `brokenback_hub` opened and closed successfully.
- Eww active windows were clean after validation.
- Eww log check reported no errors.
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.10.3: Polybar Workspace Right-Edge Fix

Status: implemented on 2026-08-27. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Fix the last workspace dot overflowing on the right edge of the left Polybar pill.
- Keep app-aware workspace icons.
- Keep the rounded active workspace highlight removed.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-polybar-left-edge-20260827-010731`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-polybar-left-edge-latest`

Changes:

- Increased left pill width calculation to `left_w="$(clamp $((screen_w / 4 + 56)) 380 460)"`.
- Removed per-item trailing padding from `brokenback-workspaces-status`.
- Kept one final output padding space after the last workspace item.

Verification:

- Live `brokenback-polybar-launch` showed the wider left pill clamp.
- Live workspace output rendered ten spaced items ending with one final padding space.
- Helper shell syntax passed.
- Polybar log check reported no errors.
- No failed system units were reported.
- No failed `guesswho` user units were reported.

## Milestone 2.10.2: Polybar Pill Border And Workspace Breathing Room

Status: implemented on 2026-08-27. Visual acceptance is pending the user's eyes on the physical screen.

Purpose:

- Give the left Polybar workspace pill a little more room so the last workspace item is not on the edge.
- Add a visible border to the rounded Polybar pills.
- Keep Polybar workspace icon detection active.

Backup:

- Created before this change:
  - `/var/backups/codex/arch-milestone2-polybar-border-20260827-010238`
- Latest marker:
  - `/var/backups/codex/arch-milestone2-polybar-border-latest`

Polybar changes:

- Increased left pill width calculation to `left_w="$(clamp $((screen_w / 4 + 24)) 344 420)"`.
- Increased left pill padding to `padding-left = 3` and `padding-right = 4`.
- Added shared `pill-border = #667ddfe8`.
- Added `border-size = 1` and `border-color = ${colors.pill-border}` to the rounded Polybar pill bars:
  - `brokenback-left`,
  - `brokenback-windowcount`,
  - `brokenback-battery`,
  - `brokenback-datetime`.

Verification:

- Active Polybar processes include `brokenback-left`, `brokenback-center`, `brokenback-windowcount`, `brokenback-battery`, and `brokenback-datetime`.
- Deployed Polybar config uses the app-aware `brokenback-workspaces-status` script.
- Deployed `brokenback-polybar-launch` showed the wider left pill clamp.
- Helper shell syntax passed.
- Polybar log check reported no errors.
- No failed system units were reported.
- No failed `guesswho` user units were reported.
