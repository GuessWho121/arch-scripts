# BrokenBack AI Handover

Last updated: 2026-08-27

## Current Focus

The active work is the Arch daily-driver rice running from the external/cloned drive on the temporary BrokenBack/server laptop. The final intended hardware is the Windows PC/laptop later, so avoid final-hardware-specific package choices until Arch is booted there.

Most recent completed milestone:

- Milestone 2.10.5: Main Hub Icon-Only Action Tiles

Main local tracking docs:

- `BROKENBACK_ARCH_CHANGELOG.md`
- `BROKENBACK_BACKUPS.md`
- `BROKENBACK_ARCH_NEXT_CHANGES.md`
- `BROKENBACK_AI_HANDOVER.md`

## Remote Access

Current reachable Arch laptop target used in this session:

```text
brokenback-arch
```

Resolved SSH target:

```text
codexsetup@169.254.171.2
```

Fallback Wi-Fi IP visible in user screenshots:

```text
10.223.130.151
```

Windows OpenSSH binary used successfully:

```text
C:\Windows\System32\OpenSSH\ssh.exe
```

Persistent Windows-side SSH key:

```text
C:\Users\aksha\.ssh\brokenback_codex_ed25519
C:\Users\aksha\.ssh\brokenback_codex_ed25519.pub
```

Windows SSH config:

```text
C:\Users\aksha\.ssh\config
```

Expected host entry:

```sshconfig
Host brokenback-arch
    HostName 169.254.171.2
    User codexsetup
    IdentityFile C:\Users\aksha\.ssh\brokenback_codex_ed25519
    StrictHostKeyChecking no
    UserKnownHostsFile C:\Users\aksha\.ssh\known_hosts_brokenback
    IdentitiesOnly yes
```

Do not paste or expose private key contents. If this key stops working, first check for an O/0 typo or duplicate malformed key in `/home/codexsetup/.ssh/authorized_keys`.

Useful SSH prefix:

```powershell
& 'C:\Windows\System32\OpenSSH\ssh.exe' `
  -F 'C:\Users\aksha\.ssh\config' `
  -o BatchMode=yes `
  brokenback-arch
```

Remote shell PATH used:

```bash
export PATH=/home/guesswho/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin
```

## Current Arch State

User:

```text
guesswho
```

Display/session:

- LightDM + `lightdm-webkit2-greeter`.
- BSPWM desktop.
- SXHKD keybind daemon.
- Polybar top pill bar.
- Picom compositor.
- Dunst notifications.
- SpaceMono Nerd Font Mono used across greeter, lock, and desktop styling.

Milestone 1 accepted:

- LightDM WebKit greeter.
- Password-focused login UI.
- Matching lockscreen using direct `i3lock-color` wrapper.
- Login/lock wallpaper stored under:
  - `/home/guesswho/Pictures/wallpaper/login/wallpaper.jpg`
- Home wallpaper stored under:
  - `/home/guesswho/Pictures/wallpaper/home/wallpaper.jpg`
- Old Milestone 1 backups were removed after user acceptance.

Milestone 2 current:

- BSPWM desktop foundation.
- Surface-dots-inspired top bar.
- Rofi Type 6 compact launcher.
- Eww top-right control hub and Eww calendar hub.
- Polybar owns the left app-aware workspace dots/icons, center media pill, and right-side status pills.
- Left workspace area uses Polybar's built-in BSPWM module with simple dots and no rounded active highlight.
- Peach window-count chip opens the Eww control hub.
- Combined date/time pill opens the Eww calendar hub.
- Package update count is read-only inside the Eww hub.
- The fallback Rofi hub remains but has no `sudo pacman -Syu` action.
- Alacritty opacity is `0.88`; Picom blur strength is `8`.
- Type 6 Rofi mode tabs use fixed width so `FILES` matches the other tabs.
- Type 6 Rofi now opens a temporary fullscreen Eww blur layer behind the compact centered card.
- Type 6 Rofi uses fixed window/mainbox/imagebox/listbox/listview heights and non-dynamic listview sizing so `FILES` does not reshape the launcher.

Current active packages relevant to Milestone 2:

```text
eww 0.6.0-1
```

`eww-debug` was removed as an orphan after install and should stay removed unless debugging is explicitly needed.

## Important Active Files On Arch

Core desktop configs:

```text
/home/guesswho/.config/bspwm/bspwmrc
/home/guesswho/.config/sxhkd/sxhkdrc
/home/guesswho/.config/polybar/config.ini
/home/guesswho/.config/picom/picom.conf
/home/guesswho/.config/dunst/dunstrc
```

Launchers/hub:

```text
/home/guesswho/.local/bin/brokenback-rofi-launcher
/home/guesswho/.local/bin/brokenback-hub-toggle
/home/guesswho/.local/bin/brokenback-calendar-toggle
/home/guesswho/.local/bin/brokenback-hub-menu
/home/guesswho/.config/rofi/launchers/type-6/style-brokenback.rasi
/home/guesswho/.config/rofi/launchers/type-6/launcher.sh
/home/guesswho/.config/eww/brokenback-hub/
```

Bar helpers:

```text
/home/guesswho/.local/bin/brokenback-polybar-launch
/home/guesswho/.local/bin/brokenback-eww-launch
/home/guesswho/.local/bin/brokenback-desktop-reload
/home/guesswho/.local/bin/brokenback-workspaces-status
/home/guesswho/.local/bin/brokenback-window-count-status
/home/guesswho/.local/bin/brokenback-battery-status
/home/guesswho/.local/bin/brokenback-center-status
/home/guesswho/.local/bin/brokenback-media-status
```

Other helpers:

```text
/home/guesswho/.local/bin/brokenback-screenshot
/home/guesswho/.local/bin/brokenback-bluetooth-menu
/home/guesswho/.local/bin/brokenback-bluetooth-status
/usr/local/bin/brokenback-lock
```

Local payload mirror:

```text
remote-scripts/arch/milestone2-desktop/
```

When changing Arch configs, edit the local payload first, package/deploy it, then update docs.

## Current Keybinds

Required user keybinds:

```text
super + t              Alacritty
super + r              Ranger in Alacritty
alt + space            Rofi app launcher
ctrl + shift + v       Clipboard menu
ctrl + w               Close focused window
super + arrow keys     Focus windows by direction
super + space          Eww hub toggle
super + shift + b      Bluetooth menu
super + shift + l      Lock
super + shift + e      Session menu
alt + F4               Session menu
Print                  Screenshot area
```

## Milestone 2.7 Current Details

Implemented:

- Left workspace pill moved from Polybar to Eww.
- Persistent Eww window `brokenback_workspaces` is anchored top-left and uses CSS `border-radius` for the active workspace.
- Workspace state helper `/home/guesswho/.local/bin/brokenback-workspaces-eww-state` emits JSON for workspaces `I` through `X`.
- Workspace display behavior:
  - empty workspace: hollow dot,
  - terminal-only workspace: terminal icon,
  - terminal running Neovim: Neovim icon,
  - terminal running `nmtui`: network icon,
  - first non-terminal app: mapped app/window icon.
- Old Polybar `brokenback-left` segment is no longer launched.
- Polybar currently launches only:
  - `brokenback-center`,
  - `brokenback-windowcount`,
  - `brokenback-battery`,
  - `brokenback-datetime`.
- Both Eww hubs use top-right safe geometry with `:x "-16px"` and `:y "54px"` to avoid clipping past the screen edge.
- Hub close actions close both the panel and its transparent background overlay.
- Installer now reloads user desktop pieces through `/home/guesswho/.local/bin/brokenback-desktop-reload` and does not restart LightDM.
- Installer repairs read/execute permissions on key config directories so Eww can read user configs when started from the display session.

Last validation passed:

- SSH key auth and passwordless sudo as `codexsetup`.
- Shell syntax for installed helper scripts.
- Eww active windows initially showed:
  - `brokenback_workspaces`
- Workspace JSON helper produced valid state with the focused workspace highlighted.
- Hub toggle opened and closed:
  - `brokenback_hub`,
  - `brokenback_hub_background`.
- Calendar toggle opened and closed:
  - `brokenback_calendar_hub`,
  - `brokenback_calendar_background`.
- Polybar segments running:
  - `brokenback-center`
  - `brokenback-windowcount`
  - `brokenback-battery`
  - `brokenback-datetime`
- Old `brokenback-left` Polybar segment was not running.
- SXHKD, Eww daemon, Picom, and Dunst were active.
- No failed system units.
- No failed `guesswho` user units.
- Deployed without restarting LightDM.

## Milestone 2.8 Current Details

Implemented:

- Enlarged the Control Hub to `430x460`.
- Enlarged the Calendar Hub to `430x520`.
- Increased and bolded Eww hub text/icons.
- Increased vertical slider troughs to use more of the hub height.
- Changed workspace rendering from Eww `jq(...)` labels to generated Eww `literal` markup.
- Added `--markup` and `--markup-once` modes to `/home/guesswho/.local/bin/brokenback-workspaces-eww-state`.
- Widened the Eww workspace window to `442px`.
- Made the focused workspace button wider with rounded accent styling.
- Lowered Alacritty opacity from `0.94` to `0.88`.
- Increased Picom dual-kawase blur strength from `6` to `8`.
- Changed Picom Alacritty opacity rule from `94` to `88`.
- Fixed Type 6 Rofi mode button width at `54px` so `FILES` matches the other tabs.

Backup:

```text
/var/backups/codex/arch-milestone2-visual-polish-20260826-202458
/var/backups/codex/arch-milestone2-visual-polish-latest
```

Validation passed:

- Corrected root-extraction payload deployment completed.
- Shell syntax passed for installed helper scripts.
- Workspace helper `--markup-once` produced unquoted Eww literal markup.
- Control Hub and Calendar Hub toggled open and closed sequentially.
- Rofi Type 6 theme parse check passed.
- Picom diagnostics passed.
- Deployed Alacritty/Picom blur values were confirmed.
- SXHKD, Eww, Picom, Dunst, and center/right Polybar segments were running.
- No failed system or `guesswho` user units were reported.

## Milestone 2.9 Current Details

Implemented:

- Added Eww fullscreen overlay window:
  - `brokenback_rofi_blur`
- Updated `/home/guesswho/.config/rofi/launchers/type-6/launcher.sh` so Rofi launcher modes open the blur layer first and close it on exit.
- Rofi launcher now closes any open Control/Calendar Hub overlay before opening, avoiding stacked overlays.
- Kept Rofi compact and centered.
- Fixed Type 6 launcher heights:
  - window/mainbox/imagebox/listbox `430px`,
  - listview `300px`.
- Set listview `dynamic: false` so `filebrowser` cannot shrink or reshape the card when its contents differ.

Backup:

```text
/var/backups/codex/arch-milestone2-rofi-blur-shape-20260826-213900
/var/backups/codex/arch-milestone2-rofi-blur-shape-latest
```

Validation passed:

- Rofi Type 6 theme parse check passed.
- Rofi launcher shell syntax passed.
- Eww config reload passed.
- Picom diagnostics passed.
- Live `filebrowser` launcher test showed `brokenback_rofi_blur` active while Rofi was open.
- Test Rofi and blur overlay were closed afterward.
- No failed system or `guesswho` user units were reported.

## Milestone 2.10 Current Details

Implemented:

- Moved the left workspace display back to Polybar.
- Changed `module/workspaces` to Polybar `internal/bspwm`.
- Removed rounded active workspace highlighting from the active display path.
- Workspace dots now render as:
  - focused: accent filled dot,
  - occupied: foreground hollow dot,
  - empty: muted hollow dot,
  - urgent: danger hollow dot.
- `brokenback-polybar-launch` launches `brokenback-left` again.
- `brokenback-eww-launch` closes any stale `brokenback_workspaces` window and no longer opens one.
- Removed the unused deployed Eww workspace helper:
  - `/home/guesswho/.local/bin/brokenback-workspaces-eww-state`
- Eww remains responsible for hubs and the Rofi blur layer only.

Backup:

```text
/var/backups/codex/arch-milestone2-polybar-workspaces-20260827-000412
/var/backups/codex/arch-milestone2-polybar-workspaces-latest
```

Validation passed:

- Polybar processes include `brokenback-left`, `brokenback-center`, `brokenback-windowcount`, `brokenback-battery`, and `brokenback-datetime`.
- Eww active windows were empty after closing validation overlays.
- Old Eww workspace helper removal was confirmed.
- Polybar config showed `type = internal/bspwm`.
- Helper shell syntax passed.
- Rofi theme parse still passed.
- Eww config reload still passed.
- No failed system or `guesswho` user units were reported.

## Milestone 2.10.1 Current Details

Implemented:

- Kept the left workspace strip inside Polybar.
- Changed `module/workspaces` from `internal/bspwm` back to the existing `brokenback-workspaces-status` script.
- Restored app/TUI icon detection for workspaces.
- Removed the focused workspace rounded/powerline cap styling from the script.
- Focused workspace is now only an accent dot/icon.
- Increased left Polybar width clamp to `320-380px`.
- Reduced workspace item spacing slightly.

Backup:

```text
/var/backups/codex/arch-milestone2-polybar-icons-20260827-003502
/var/backups/codex/arch-milestone2-polybar-icons-latest
```

Validation passed:

- Polybar processes include `brokenback-left`, `brokenback-center`, `brokenback-windowcount`, `brokenback-battery`, and `brokenback-datetime`.
- Polybar config showed `type = custom/script` and `exec = ~/.local/bin/brokenback-workspaces-status`.
- `brokenback-polybar-launch` showed the wider `left_w` clamp.
- `brokenback-workspaces-status` had no ``/`` rounded highlight glyphs.
- Helper shell syntax passed.
- Polybar log check reported no errors.
- No failed system or `guesswho` user units were reported.

## Milestone 2.10.2 Current Details

Implemented:

- Kept the left workspace strip in Polybar using `brokenback-workspaces-status`.
- Increased left pill width calculation to `left_w="$(clamp $((screen_w / 4 + 24)) 344 420)"`.
- Increased left pill padding to `padding-left = 3` and `padding-right = 4`.
- Added shared `pill-border = #667ddfe8`.
- Added a 1px border to the rounded Polybar pill bars: workspace, window count, battery, and datetime.

Backup:

```text
/var/backups/codex/arch-milestone2-polybar-border-20260827-010238
/var/backups/codex/arch-milestone2-polybar-border-latest
```

Validation passed:

- Polybar processes include `brokenback-left`, `brokenback-center`, `brokenback-windowcount`, `brokenback-battery`, and `brokenback-datetime`.
- Polybar config showed the shared border color and 1px borders on the rounded pill bars.
- Polybar config still points workspace rendering at `brokenback-workspaces-status`.
- Helper shell syntax passed.
- Polybar log check reported no errors.
- No failed system or `guesswho` user units were reported.

## Milestone 2.10.3 Current Details

Implemented:

- Kept the left workspace strip in Polybar using `brokenback-workspaces-status`.
- Increased left pill width calculation to `left_w="$(clamp $((screen_w / 4 + 56)) 380 460)"`.
- Removed per-item trailing padding from `brokenback-workspaces-status`.
- Kept one final output padding space after the last workspace item.
- App-aware workspace icon detection remains active.
- Rounded active workspace highlight remains removed.

Backup:

```text
/var/backups/codex/arch-milestone2-polybar-left-edge-20260827-010731
/var/backups/codex/arch-milestone2-polybar-left-edge-latest
```

Validation passed:

- Live `brokenback-polybar-launch` showed the wider left pill clamp.
- Live workspace output rendered ten spaced items ending with one final padding space.
- Helper shell syntax passed.
- Polybar log check reported no errors.
- No failed system or `guesswho` user units were reported.

## Milestone 2.10.4 Current Details

Implemented:

- Removed the top stats button from the main Eww Control Hub.
- Removed the top settings button from the main Eww Control Hub.
- Kept only lock, power, and close in the top header action row.
- Added Screenshot and Stats buttons between the sliders and Updates row.
- Added `stats)` to `hub-action`, opening `alacritty -e btop`.
- Set top header action icon size to `17px`, matching the Polybar large icon slot.
- Increased `brokenback_hub` height to `510px`.

Backup:

```text
/var/backups/codex/arch-milestone2-eww-main-hub-layout-20260827-011608
/var/backups/codex/arch-milestone2-eww-main-hub-layout-latest
```

Validation passed:

- `hub-action` shell syntax passed.
- Eww reload passed.
- `brokenback_hub` opened and closed successfully.
- Eww log check reported no errors.
- No failed system or `guesswho` user units were reported.

## Milestone 2.10.5 Current Details

Implemented:

- Increased top main hub lock/power/close icon font size to `24px`.
- Moved Screenshot and Stats into the right-side control column under the vertical sliders.
- Made Screenshot and Stats icon-only rounded square tiles.
- Removed Screenshot and Stats text labels from the main hub.
- Reduced slider trough height to `190px` so the new tiles fit beside the Notify tile.
- Increased the two action tile icons to `28px`.

Backup:

```text
/var/backups/codex/arch-milestone2-eww-hub-icon-actions-20260827-012606
/var/backups/codex/arch-milestone2-eww-hub-icon-actions-latest
```

Validation passed:

- Eww reload passed after daemon restart.
- `brokenback_hub` opened and closed successfully.
- Eww active windows were clean after validation.
- Eww log check reported no errors.
- No failed system or `guesswho` user units were reported.

## Backups To Keep

Do not delete these until the user visually accepts Milestone 2 after logout/login or reboot:

```text
/var/backups/codex/arch-milestone2-desktop-20260806-004044
/var/backups/codex/arch-milestone2-surface-port-20260806-130453
/var/backups/codex/arch-milestone2-bar-polish-20260806-134552
/var/backups/codex/arch-milestone2-rofi-type6-20260806-143846
/var/backups/codex/arch-milestone2-window-count-menu-20260806-151956
/var/backups/codex/arch-milestone2-eww-hub-20260806-162223
/var/backups/codex/arch-milestone2-hub-workspace-fix-20260826-172415
/var/backups/codex/arch-milestone2-visual-polish-20260826-202458
/var/backups/codex/arch-milestone2-rofi-blur-shape-20260826-213900
/var/backups/codex/arch-milestone2-polybar-workspaces-20260827-000412
/var/backups/codex/arch-milestone2-polybar-icons-20260827-003502
/var/backups/codex/arch-milestone2-polybar-border-20260827-010238
/var/backups/codex/arch-milestone2-polybar-left-edge-20260827-010731
/var/backups/codex/arch-milestone2-eww-main-hub-layout-20260827-011608
/var/backups/codex/arch-milestone2-eww-hub-icon-actions-20260827-012606
```

Latest marker for Milestone 2.10.5:

```text
/var/backups/codex/arch-milestone2-eww-hub-icon-actions-latest
```

## Known Issues / Things To Visually Confirm

Ask the user to confirm on the physical screen:

- Left workspace pill no longer clips the last workspace dot/icon.
- Left workspace pill is back in Polybar with app-aware dots/icons.
- Active workspace is only an accent dot/icon; there is no rounded highlight.
- Rounded Polybar pills have a visible border.
- Main Control Hub top row only has lock, power, and close.
- Screenshot and Stats buttons sit cleanly between sliders and Updates.
- Screenshot and Stats are icon-only square tiles aligned beside Notify.
- Top hub action icons are large enough.
- Workspace click switching still works from Polybar.
- Peach window-count chip opens the Eww hub.
- `super + space` opens/closes the Eww hub.
- Date/time chip clicks open the Eww calendar hub.
- Both Eww hubs stay fully inside the right edge.
- Clicking outside either hub closes it fully.
- Hub text/icons are readable at normal viewing distance.
- Longer volume and brightness sliders use the Control Hub height cleanly.
- Volume and brightness sliders feel usable.
- Hub visual design fits the rice.
- No unexpected sudo/pacman terminal appears anymore.
- Rofi launcher remains compact and centered.
- Rofi `FILES` tab matches the other Type 6 launcher mode tabs.
- Switching into Rofi `FILES` keeps the same launcher card shape.
- Opening Rofi blurs/dims the whole desktop background behind the compact card.
- Alacritty background blur/transparency is visible while text remains readable.
- Screenshots still work.

One possible visual issue:

- Eww hub geometry is currently anchored top-right with `x=-16px`, `y=54px`. If it still feels too close to the edge on the physical display, adjust `/home/guesswho/.config/eww/brokenback-hub/eww.yuck` and trim inner widget widths in SCSS.

## Next Good Milestone

Recommended next milestone after visual acceptance:

```text
Milestone 2.11: Eww Hub Visual Polish And Interaction Pass
```

Suggested scope:

- Tune Eww hub spacing/size after physical-screen feedback.
- Add mute state and microphone control.
- Improve Bluetooth status/paired device display.
- Refine click-outside-to-close if physical testing reveals edge cases.
- Improve media card if Spotify/player state is important.
- Do not add daily apps yet unless the desktop shell is visually accepted.

After that:

```text
Milestone 3: Daily Apps And Visual Refinement
```

Possible Milestone 3 scope:

- Browser/default app choices.
- Editor/dev app defaults.
- Terminal/Ranger preview refinements.
- Wallpaper pack/rotation.
- GTK/Qt theme fixes.
- Backup cleanup after Milestone 2 acceptance.

## Deferred Work

Keep deferred until final hardware or explicit user request:

- Fingerprint auth.
- OLED care/pixel shifting/burn-in mitigation.
- Final-hardware microcode cleanup.
- Removing `codexsetup`.
- Removing Milestone 2 backups.

Important final-hardware note:

- Do not decide Intel vs AMD microcode until Arch is booted on the final Windows PC/laptop or the final CPU vendor is confirmed.

## Common Remote Validation Commands

Check failed units:

```bash
systemctl --failed --no-legend
sudo -u guesswho env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus systemctl --user --failed --no-legend
```

Check desktop processes:

```bash
pgrep -a sxhkd
pgrep -a polybar
pgrep -a eww
```

Test hub:

```bash
sudo -u guesswho env HOME=/home/guesswho USER=guesswho DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus /home/guesswho/.local/bin/brokenback-hub-toggle
sudo -u guesswho env HOME=/home/guesswho USER=guesswho DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus eww --config /home/guesswho/.config/eww/brokenback-hub active-windows
```

Close hub:

```bash
sudo -u guesswho env HOME=/home/guesswho USER=guesswho DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus eww --config /home/guesswho/.config/eww/brokenback-hub close brokenback_hub
```

Reload desktop pieces:

```bash
sudo -u guesswho env HOME=/home/guesswho USER=guesswho DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus pkill -x sxhkd
sudo -u guesswho env HOME=/home/guesswho USER=guesswho DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus sxhkd -c /home/guesswho/.config/sxhkd/sxhkdrc &
sudo -u guesswho env HOME=/home/guesswho USER=guesswho DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus /home/guesswho/.local/bin/brokenback-polybar-launch
```

## Gotchas For The Next AI

- Use `rg -uu` for hidden local payload files; normal `rg --files` hides dot-directories.
- Avoid Windows PowerShell quoting for complex remote shell commands. Prefer simple SSH commands or upload a script/payload.
- Windows system `scp.exe` rejected the temporary key ACL. The Git-bundled `ssh.exe` worked.
- Previous base64-over-PowerShell attempts were fragile. Chunked SSH transfer worked.
- Do not run `git reset`, `git checkout --`, or destructive cleanup unless the user explicitly asks.
- Always back up remote configs under `/var/backups/codex/...` before changing Arch.
- Update the three docs after every milestone:
  - changelog,
  - backup ledger,
  - next changes.
