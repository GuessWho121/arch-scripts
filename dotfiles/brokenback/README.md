# BrokenBack Dotfiles

Snapshot of the Arch daily-driver rice developed on the external Arch drive.

## Layout

- `home/guesswho/` - user dotfiles and helper scripts.
- `system/` - system-level config snippets used by the rice.
- `scripts/` - deployment/test helpers from the milestone work.
- `docs/` - changelog, backups ledger, next changes, and handover notes.

## Notes

- The target desktop user is currently `guesswho`.
- The live setup uses BSPWM, Polybar, Eww, Rofi, Picom, Dunst, Alacritty, Ranger, and LightDM.
- Polybar owns the left workspace pill and right status pills; Eww owns the control hub, calendar hub, Rofi blur layer, and center media island/popup.
- The media island opens the Eww media popup, which has title, artist, album, progress, elapsed/total time, and media controls.
- Keep temporary access users/keys out of future commits unless they are intentionally documented as public placeholders.
