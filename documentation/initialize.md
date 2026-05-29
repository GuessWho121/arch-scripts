# Arch Linux Installation Guide

A beginner-friendly Arch Linux installation guide for preparing a system from the Arch ISO, then running `arch-initialize.sh` inside `arch-chroot`.

This guide covers:

- Manual pre-chroot installation steps
- UEFI setup
- Optional dual boot notes
- Partition formatting and mounting
- Base system installation
- Running the post-chroot automation script

The `arch-initialize.sh` script handles the post-chroot work:

- Locale and timezone
- Hostname and user creation
- Root and user passwords
- Sudo wheel configuration
- Kernel, firmware, GRUB, NetworkManager, and useful packages
- Intel or AMD microcode detection
- Optional Windows/other OS detection through `os-prober`
- NetworkManager enablement for first boot
- GRUB installation and config generation

---

## Requirements

Before starting:

- Back up important data
- Disable Secure Boot
- Create a bootable Arch Linux USB
- Boot the USB in UEFI mode if installing UEFI
- Have a working internet connection

Download the Arch Linux ISO:

https://archlinux.org/download/

---

## Boot Into Arch ISO

After booting into the live environment, verify internet access:

```bash
ping archlinux.org
```

If using Wi-Fi:

```bash
iwctl
```

Inside `iwctl`:

```bash
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect WIFI_NAME
exit
```

Replace `wlan0` with your wireless device name if it is different.

Check again:

```bash
ping archlinux.org
```

---

## Confirm Boot Mode

For UEFI installs, this directory should exist:

```bash
ls /sys/firmware/efi/efivars
```

If the directory does not exist, you probably booted the USB in legacy BIOS mode.

---

## Identify Disks

List disks and partitions:

```bash
lsblk
```

Example NVMe drive:

```bash
/dev/nvme0n1
```

Example SATA drive:

```bash
/dev/sda
```

Be careful with disk names. The commands below use `/dev/nvme0n1` as an example.

---

## Partitioning

Open `cfdisk`:

```bash
cfdisk /dev/nvme0n1
```

For a typical UEFI-only Arch install, create:

| Partition | Size | Type |
|---|---:|---|
| EFI | 512M | EFI System |
| Swap | Optional | Linux swap |
| Root | Remaining space | Linux filesystem |

Example result:

| Partition | Usage |
|---|---|
| `/dev/nvme0n1p1` | EFI |
| `/dev/nvme0n1p2` | Swap |
| `/dev/nvme0n1p3` | Root |

### Dual Boot With Windows

If Windows is already installed:

- Reuse the existing EFI System Partition
- Do not format the existing EFI partition
- Make only the Linux root partition and optional swap partition
- Confirm partition names carefully with `lsblk`

---

## Format Partitions

Format the root partition:

```bash
mkfs.ext4 /dev/nvme0n1p3
```

Format the EFI partition only for a clean Arch-only install:

```bash
mkfs.fat -F32 /dev/nvme0n1p1
```

For dual boot, do not run `mkfs.fat` on the Windows EFI partition.

If using swap:

```bash
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
```

---

## Mount Partitions

Mount the root partition:

```bash
mount /dev/nvme0n1p3 /mnt
```

Create and mount the EFI mountpoint:

```bash
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

This guide uses `/boot` as the EFI mountpoint. When the script asks for the EFI mountpoint, enter:

```bash
/boot
```

For dual boot, mount the existing Windows EFI partition at `/mnt/boot` instead.

Check mounts:

```bash
lsblk
findmnt /mnt
findmnt /mnt/boot
```

---

## Install Base System

Install the minimum base system needed before chroot:

```bash
pacstrap -K /mnt base linux linux-firmware git
```

The post-chroot script installs the rest, including:

- `networkmanager`
- `grub`
- `efibootmgr`
- `sudo`
- `base-devel`
- `linux-headers`
- `iputils`
- `openssh`
- `neovim`
- CPU microcode package
- Optional `os-prober`

Generate `fstab`:

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

Check the generated file:

```bash
cat /mnt/etc/fstab
```

---

## Chroot Into The Installed System

```bash
arch-chroot /mnt
```

If you copied the script to `/mnt/root/arch-scripts`, run:

```bash
cd /root/arch-scripts
chmod +x arch-initialize.sh
./arch-initialize.sh
```

If cloning inside chroot:

```bash
git clone https://github.com/GuessWho121/arch-scripts.git
cd arch-scripts
chmod +x arch-initialize.sh
./arch-initialize.sh


---

## Script Prompts

The script will ask for:

- Hostname
- Primary username
- Root password
- User password
- Whether to enable detection for Windows or other operating systems
- Whether to install GRUB
- Boot mode, usually `uefi`
- EFI mountpoint, usually `/boot` if following this guide
- Cleanup choices at the end

For dual boot, answer yes when asked:

```text
Do you have multiple OSes (Windows/etc.) and want GRUB to detect them?
```

The script will install `os-prober`, enable GRUB OS probing, and generate the GRUB config.

---

## Resume Or Restore

The script stores checkpoints under:

```bash
/var/lib/arch-initialize
```

Resume from the saved phase:

```bash
./arch-initialize.sh --resume
```

Restore files backed up for a phase:

```bash
./arch-initialize.sh --restore phase3
```

Valid phases are:

```text
phase1 phase2 phase3 phase4 phase5
```

---

## Finish Installation

After the script completes, exit chroot:

```bash
exit
```

Unmount partitions:

```bash
umount -R /mnt
```

Reboot:

```bash
reboot
```

Remove the USB after reboot.

---

## License

MIT
