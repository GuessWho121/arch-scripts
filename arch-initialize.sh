#!/usr/bin/env bash

# Arch Linux post-install bootstrap (interactive only)
# Intended to run inside arch-chroot after pacstrap + genfstab

set -Eeuo pipefail

log() { printf "[arch-initialize] %s\n" "$*" >&2; }
die() { printf "[arch-initialize] ERROR: %s\n" "$*" >&2; exit 1; }

STATE_DIR="/var/lib/arch-initialize"
STATE_FILE="${STATE_DIR}/state"
BACKUP_DIR="${STATE_DIR}/backups"

CURRENT_PHASE=""
AUTO_RESUME=0
RESTORE_MODE=0
RESTORE_TARGET=""

HOSTNAME=${HOSTNAME:-}
USERNAME=${USERNAME:-}
TIMEZONE=${TIMEZONE:-Asia/Kolkata}
LOCALE=${LOCALE:-en_US.UTF-8}
DISK=${DISK:-/dev/nvme0n1}

ensure_root() {
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        die "Run this script as root"
    fi
}

# Verify we're running inside the chroot and not on the live ISO
check_running_in_chroot() {
    # Compare device ID of / and the parent of /proc/$$/root (works for many chroot setups)
    if [[ "$(stat -c %d /)" -eq "$(stat -c %d /proc/$$/root/.. 2>/dev/null || echo 0)" ]]; then
        die "This script must be run INSIDE a chroot environment!"
    fi
}

# Ensure EFI variables are available for UEFI operations
check_efi_vars() {
    if [[ ! -d /sys/firmware/efi/efivars || -z "$(ls -A /sys/firmware/efi/efivars 2>/dev/null)" ]]; then
        die "/sys/firmware/efi/efivars is not available or empty. EFI variables are required for UEFI bootloader installation."
    fi
}

# Ensure a kernel image exists in /boot
check_kernel_in_boot() {
    if ! ls /boot/vmlinuz* >/dev/null 2>&1; then
        die "No kernel image (vmlinuz*) found in /boot. Ensure the 'linux' package was installed in this chroot before proceeding."
    fi
}

# Check network resolution and initialize pacman keyring if necessary
check_dns_and_init_pacman_keyring() {
    # Quick DNS test
    if ! ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
        log "DNS resolution or network appears broken inside chroot. /etc/resolv.conf:"
        sed -n '1,20p' /etc/resolv.conf 2>/dev/null || true
        read -rp "Network appears broken. Continue anyway? (y/N): " netans
        [[ ${netans,,} == y ]] || die "Network required for package installation"
    fi

    # Initialize pacman keyring to avoid signature errors
    if command -v pacman-key >/dev/null 2>&1; then
        log "Initializing pacman keyring (may take a few seconds)"
        pacman-key --init || log "pacman-key --init failed; continuing"
        pacman-key --populate archlinux || log "pacman-key --populate failed; continuing"
    fi
}

# Detect appropriate microcode package (intel-ucode or amd-ucode)
detect_microcode() {
    if grep -q "GenuineIntel" /proc/cpuinfo 2>/dev/null; then
        printf "%s" "intel-ucode"
    elif grep -q "AuthenticAMD" /proc/cpuinfo 2>/dev/null; then
        printf "%s" "amd-ucode"
    else
        # Unknown vendor; return empty
        printf "%s" ""
    fi
}

# Basic /etc/fstab validation
check_fstab() {
    if [[ ! -s /etc/fstab ]]; then
        die "/etc/fstab is empty or missing. Ensure genfstab was run and the root entry is present."
    fi
    if ! grep -Eq 'UUID=|/dev/' /etc/fstab; then
        log "Warning: /etc/fstab does not contain obvious device identifiers (UUID= or /dev/)."
    fi
    # Ensure a root (/) mount entry exists
    if ! awk '$2=="/"{found=1} END{exit !found}' /etc/fstab 2>/dev/null; then
        die "/etc/fstab does not contain a root (/) mount entry. Ensure genfstab was run with the target mountpoint."
    fi
}

# Verify root password is set (not locked)
check_root_password() {
    local root_entry
    root_entry=$(awk -F: '$1=="root"{print $2}' /etc/shadow 2>/dev/null || true)
    if [[ -z ${root_entry} || ${root_entry} == "!" || ${root_entry} == "*" ]]; then
        read -rp "Root password appears locked/empty. Set root password now? (y/N): " rans
        if [[ ${rans,,} == y ]]; then
            passwd root
        else
            die "Root password is required to continue"
        fi
    fi
}

# Ensure NetworkManager is enabled and available
ensure_networkmanager_enabled() {
    if ! command -v nmcli >/dev/null 2>&1; then
        log "nmcli not found after package install"
        return 1
    fi
    if ! systemctl is-enabled --quiet NetworkManager 2>/dev/null; then
        log "Enabling NetworkManager"
        systemctl enable --now NetworkManager || log "Failed to enable NetworkManager"
    fi
}

# Cleanup installer artifacts created by this script (backups/state/tmp)
cleanup_after_install() {
    read -rp "Remove installer state and backups at ${STATE_DIR}? (y/N): " clean_ans
    if [[ ${clean_ans,,} == y ]]; then
        rm -rf "${STATE_DIR}" && log "Removed installer state: ${STATE_DIR}" || log "Failed to remove ${STATE_DIR}"
    else
        log "Leaving installer state at ${STATE_DIR}" 
    fi

    read -rp "Remove pacman package cache (runs 'pacman -Sc')? (y/N): " cache_ans
    if [[ ${cache_ans,,} == y ]]; then
        pacman -Sc --noconfirm || log "pacman -Sc failed or requires interaction"
    fi

    if compgen -G "/tmp/arch-initialize-*" >/dev/null 2>&1; then
        read -rp "Remove temporary files /tmp/arch-initialize-*? (y/N): " tmp_ans
        if [[ ${tmp_ans,,} == y ]]; then
            rm -rf /tmp/arch-initialize-* || log "Failed to remove temporary files"
        fi
    fi
}

is_valid_phase() {
    case "$1" in
        phase1|phase2|phase3|phase4|phase5)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --resume)
                AUTO_RESUME=1
                shift
                ;;
            --restore)
                [[ $# -ge 2 ]] || die "--restore requires a phase name (phase1..phase5)"
                RESTORE_MODE=1
                RESTORE_TARGET="$2"
                shift 2
                ;;
            -h|--help)
                cat <<'EOF'
Usage: ./arch-initialize.sh [--resume] [--restore phaseX]

Options:
  --resume          Resume from saved checkpoint without resume prompt.
  --restore phaseX  Restore files backed up for phaseX and set state to phaseX.
  -h, --help        Show this help.
EOF
                exit 0
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
}

phase_targets() {
    # Files this phase is expected to edit.
    case "$1" in
        phase1)
            printf "%s\n" \
                "/etc/locale.gen" \
                "/etc/locale.conf" \
                "/etc/localtime" \
                "/etc/adjtime"
            ;;
        phase2)
            printf "%s\n" \
                "/etc/hostname" \
                "/etc/hosts" \
                "/etc/vconsole.conf" \
                "/etc/sudoers" \
                "/etc/passwd" \
                "/etc/group" \
                "/etc/shadow" \
                "/etc/gshadow"
            ;;
        phase3)
            printf "%s\n" \
                "/etc/pacman.conf" \
                "/etc/default/grub"
            ;;
        phase4)
            printf "%s\n" \
                "/etc/NetworkManager/NetworkManager.conf"
            ;;
        phase5)
            printf "%s\n" \
                "/etc/default/grub" \
                "/boot/grub/grub.cfg"
            ;;
        *)
            ;;
    esac
}

backup_for_phase() {
    local phase="$1"
    local phase_backup_dir="${BACKUP_DIR}/${phase}"

    rm -rf "${phase_backup_dir}"
    mkdir -p "${phase_backup_dir}"

    while IFS= read -r target; do
        [[ -z ${target} ]] && continue

        if [[ -e ${target} || -L ${target} ]]; then
            local dest="${phase_backup_dir}${target}"
            mkdir -p "$(dirname "${dest}")"
            cp -a "${target}" "${dest}"
        fi
    done < <(phase_targets "${phase}")

    log "Prepared backups for ${phase} in ${phase_backup_dir}"
}

restore_phase_files() {
    local phase="$1"
    local phase_backup_dir="${BACKUP_DIR}/${phase}"

    [[ -d ${phase_backup_dir} ]] || die "No backup directory found for ${phase}: ${phase_backup_dir}"

    while IFS= read -r target; do
        [[ -z ${target} ]] && continue

        local src="${phase_backup_dir}${target}"
        if [[ -e ${src} || -L ${src} ]]; then
            mkdir -p "$(dirname "${target}")"
            cp -a "${src}" "${target}"
        fi
    done < <(phase_targets "${phase}")

    log "Restored backups for ${phase}"
}

auto_restore_on_error() {
    local exit_code=$?
    local failed_cmd=${BASH_COMMAND:-unknown}

    trap - ERR

    if [[ -n ${CURRENT_PHASE} ]] && is_valid_phase "${CURRENT_PHASE}"; then
        log "Error in ${CURRENT_PHASE} while running: ${failed_cmd}"
        if [[ -d ${BACKUP_DIR}/${CURRENT_PHASE} ]]; then
            log "Attempting automatic restore for ${CURRENT_PHASE}"
            if restore_phase_files "${CURRENT_PHASE}"; then
                log "Auto-restore completed for ${CURRENT_PHASE}. Re-run script to resume."
            else
                log "Auto-restore failed for ${CURRENT_PHASE}. Manual recovery may be required."
            fi
        else
            log "No backup found for ${CURRENT_PHASE}; cannot auto-restore."
        fi
    fi

    exit "${exit_code}"
}

set_next_phase() {
    local next_phase="$1"

    : > "${STATE_FILE}"
    printf "%s\n" "${next_phase}" > "${STATE_FILE}"

    backup_for_phase "${next_phase}"
    log "Checkpoint saved: next phase is ${next_phase}"
}

read_or_init_state() {
    mkdir -p "${STATE_DIR}" "${BACKUP_DIR}"

    if [[ -s ${STATE_FILE} ]]; then
        local saved_phase
        saved_phase=$(<"${STATE_FILE}")

        is_valid_phase "${saved_phase}" || die "Invalid checkpoint in state file: ${saved_phase}"

        if [[ ${AUTO_RESUME} -eq 1 ]]; then
            printf "%s\n" "${saved_phase}"
            return 0
        fi

        read -rp "Found existing checkpoint '${saved_phase}'. Resume from it? (y/N): " resume_ans

        if [[ ${resume_ans,,} == y ]]; then
            printf "%s\n" "${saved_phase}"
            return 0
        fi

        read -rp "Restart from phase1 and overwrite checkpoints? (y/N): " restart_ans
        if [[ ${restart_ans,,} != y ]]; then
            die "Aborted by user"
        fi

        rm -rf "${BACKUP_DIR}"
        mkdir -p "${BACKUP_DIR}"
    fi

    if [[ ${AUTO_RESUME} -eq 1 ]]; then
        die "--resume requested but no checkpoint state file exists"
    fi

    : > "${STATE_FILE}"
    printf "%s\n" "phase1" > "${STATE_FILE}"
    backup_for_phase "phase1"
    log "Initialized new state file"
    printf "%s\n" "phase1"
}

prompt_identity_if_needed() {
    if [[ -z ${HOSTNAME} ]]; then
        read -rp "Enter hostname: " HOSTNAME
    fi

    if [[ -z ${USERNAME} ]]; then
        read -rp "Enter primary username: " USERNAME
    fi

    if [[ ! ${USERNAME} =~ ^[a-z_][a-z0-9_-]{0,30}$ ]]; then
        die "Invalid username: ${USERNAME}"
    fi

    if [[ ! ${HOSTNAME} =~ ^[a-zA-Z0-9._-]{1,63}$ ]]; then
        die "Invalid hostname: ${HOSTNAME}"
    fi
}

summary_and_confirm() {
    local root_fs
    local efi_fs

    root_fs=$(findmnt -no SOURCE / 2>/dev/null || true)
    efi_fs=$(findmnt -no SOURCE /boot/efi 2>/dev/null || true)

    echo "========================================="
    echo "Arch Linux Installation Script"
    echo "========================================="
    echo "Hostname : ${HOSTNAME}"
    echo "Username : ${USERNAME}"
    echo "Timezone : ${TIMEZONE}"
    echo "Locale   : ${LOCALE}"
    echo "Disk     : ${DISK}"
    echo "Root FS  : ${root_fs}"
    echo "EFI FS   : ${efi_fs}"
    echo ""

    read -rp "Continue installation? (y/N): " ans
    [[ ${ans,,} == y ]] || die "Installation cancelled by user"
}

run_phase1() {
    log "Running phase1: locale/timezone"

    if ! grep -q "^#${LOCALE}" /etc/locale.gen && ! grep -q "^${LOCALE}" /etc/locale.gen; then
        die "Locale ${LOCALE} not found in /etc/locale.gen"
    fi

    if [[ ! -f /usr/share/zoneinfo/${TIMEZONE} ]]; then
        die "Timezone /usr/share/zoneinfo/${TIMEZONE} not found"
    fi

    ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
    timedatectl set-ntp true || log "timedatectl set-ntp true failed; continuing"
    hwclock --systohc

    sed -i "s/^#\?${LOCALE}/${LOCALE}/" /etc/locale.gen
    locale-gen
    printf "LANG=%s\n" "${LOCALE}" > /etc/locale.conf

    set_next_phase "phase2"
}

run_phase2() {
    log "Running phase2: hostname/user/sudo"

    prompt_identity_if_needed

    printf "%s\n" "${HOSTNAME}" > /etc/hostname
    cat > /etc/hosts <<EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

    printf "KEYMAP=us\n" > /etc/vconsole.conf

    log "Set ROOT password"
    passwd

    if id -u "${USERNAME}" >/dev/null 2>&1; then
        log "User ${USERNAME} already exists; ensuring groups"
        usermod -aG wheel,audio,video,storage,input "${USERNAME}"
        read -rp "User exists. Reset password for ${USERNAME}? (y/N): " pwans
        if [[ ${pwans,,} == y ]]; then
            passwd "${USERNAME}"
        fi
    else
        log "Creating user ${USERNAME}"
        useradd -m -G wheel,audio,video,storage,input -s /bin/bash "${USERNAME}"
        log "Set password for ${USERNAME}"
        passwd "${USERNAME}"
    fi

    if ! grep -q '^%wheel ALL=(ALL:ALL) ALL' /etc/sudoers; then
        sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers || true
    fi

    # Verify root password is set and not locked
    check_root_password

    set_next_phase "phase3"
}

run_phase3() {
    log "Running phase3: packages"

    # Detect and include appropriate microcode package (if any)
    microcode_pkg=$(detect_microcode)

    packages=(
        networkmanager
        grub
        efibootmgr
        sudo
        neovim
        base-devel
        linux-headers
        linux-firmware
    )
    if [[ -n ${microcode_pkg} ]]; then
        packages+=("${microcode_pkg}")
    fi

    read -rp "Do you have multiple OSes (Windows/etc.) and want GRUB to detect them? (y/N): " multios
    if [[ ${multios,,} == y ]]; then
        packages+=(os-prober)
        enable_os_prober=1
    else
        enable_os_prober=0
    fi

    if pacman -Qq iwd >/dev/null 2>&1; then
        read -rp "iwd is installed and may conflict with NetworkManager. Remove iwd and continue? (y/N): " iwdans
        if [[ ${iwdans,,} == y ]]; then
            systemctl disable --now iwd.service || true
            systemctl mask iwd.service || true
            pacman -Rns iwd
        else
            die "Please disable/remove iwd before proceeding"
        fi
    fi

    # Ensure network/resolution and pacman keyring are OK before package operations
    check_dns_and_init_pacman_keyring

    log "Installing packages: ${packages[*]}"
    pacman -Syu --needed "${packages[@]}"

    if [[ ${enable_os_prober} -eq 1 ]]; then
        if grep -q '^#\?GRUB_DISABLE_OS_PROBER=' /etc/default/grub; then
            sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub || true
        else
            printf '\nGRUB_DISABLE_OS_PROBER=false\n' >> /etc/default/grub
        fi
    fi

    set_next_phase "phase4"
}

run_phase4() {
    log "Running phase4: network setup"

    systemctl enable --now NetworkManager
    ensure_networkmanager_enabled || log "NetworkManager enablement check failed; continuing"

    nmcli radio wifi on || true
    nmcli device wifi rescan || true
    nmcli device wifi list || true

    if command -v nmcli >/dev/null 2>&1; then
        read -rp "Connect to a Wi-Fi network now? (y/N): " connect_now
        if [[ ${connect_now,,} == y ]]; then
            while true; do
                read -rp "Enter SSID to connect to (or leave empty to cancel): " ssid
                if [[ -z ${ssid} ]]; then
                    log "Wi-Fi connect cancelled by user"
                    break
                fi

                log "Attempting to connect to '${ssid}' (no password)"
                if nmcli device wifi connect "${ssid}"; then
                    log "Connected to ${ssid}"
                    break
                fi

                echo "Connect failed (SSID may be secured or out of range)."
                read -rp "Try with a password? (y/N): " try_pass
                if [[ ${try_pass,,} == y ]]; then
                    read -rsp "Enter password: " wpass
                    echo
                    if nmcli device wifi connect "${ssid}" password "${wpass}"; then
                        log "Connected to ${ssid}"
                        break
                    fi
                    echo "Connect failed with provided password."
                fi

                read -rp "Try a different SSID? (y/N): " retry
                [[ ${retry,,} == y ]] || break
            done
        fi
    else
        log "nmcli not found; cannot offer interactive Wi-Fi connection"
    fi

    set_next_phase "phase5"
}

run_phase5() {
    log "Running phase5: bootloader"

    read -rp "Install and configure GRUB bootloader now? (y/N): " install_grub
    if [[ ${install_grub,,} != y ]]; then
        log "Skipping GRUB installation as requested"
        # Offer to clean up state/backups before exiting
        cleanup_after_install

        : > "${STATE_FILE}"
        rm -f "${STATE_FILE}"
        return 0
    fi

    read -rp "Select boot mode (uefi/bios): " boot_type
    boot_type=${boot_type,,}

    if [[ ${boot_type} == "uefi" ]]; then
        read -rp "Enter EFI mountpoint (e.g. /boot or /boot/efi): " efi_dir
        [[ -n ${efi_dir} ]] || die "EFI mountpoint is required for UEFI"
        findmnt -no TARGET "${efi_dir}" >/dev/null 2>&1 || die "${efi_dir} is not a mounted filesystem"

        # Ensure EFI vars are accessible and kernel images exist
        check_efi_vars
        check_kernel_in_boot

        log "Installing GRUB for UEFI at ${efi_dir}"
        grub-install --target=x86_64-efi --efi-directory="${efi_dir}" --bootloader-id=GRUB || die "grub-install failed"
        grub-mkconfig -o /boot/grub/grub.cfg || die "grub-mkconfig failed"
    elif [[ ${boot_type} == "bios" ]]; then
        read -rp "Enter target disk for BIOS GRUB install (e.g. /dev/sda) [${DISK}]: " target_disk
        target_disk=${target_disk:-${DISK}}
        [[ -b ${target_disk} ]] || die "${target_disk} is not a block device"

        # Ensure kernel images exist before installing GRUB
        check_kernel_in_boot

        log "Installing GRUB for BIOS on ${target_disk}"
        grub-install --target=i386-pc "${target_disk}" || die "grub-install failed"
        grub-mkconfig -o /boot/grub/grub.cfg || die "grub-mkconfig failed"
    else
        die "Invalid boot mode '${boot_type}'. Use 'uefi' or 'bios'"
    fi

    # Final cleanup: clear checkpoint state.
    : > "${STATE_FILE}"
    rm -f "${STATE_FILE}"
    log "Checkpoint state cleaned"

    # Offer to remove installer artifacts before finishing
    cleanup_after_install
}

main() {
    parse_args "$@"
    ensure_root
    check_running_in_chroot

    if [[ ${RESTORE_MODE} -eq 1 ]]; then
        is_valid_phase "${RESTORE_TARGET}" || die "Invalid restore target '${RESTORE_TARGET}'"
        mkdir -p "${STATE_DIR}" "${BACKUP_DIR}"
        restore_phase_files "${RESTORE_TARGET}"
        printf "%s\n" "${RESTORE_TARGET}" > "${STATE_FILE}"
        log "Restore mode complete; state set to ${RESTORE_TARGET}"
        exit 0
    fi

    local current_phase
    current_phase=$(read_or_init_state)

    if [[ ${current_phase} == "phase1" ]]; then
        prompt_identity_if_needed
        check_fstab || true
        summary_and_confirm
    else
        log "Resuming from ${current_phase}"
    fi

    trap auto_restore_on_error ERR

    while true; do
        case "${current_phase}" in
            phase1)
                CURRENT_PHASE="phase1"
                run_phase1
                current_phase="phase2"
                ;;
            phase2)
                CURRENT_PHASE="phase2"
                run_phase2
                current_phase="phase3"
                ;;
            phase3)
                CURRENT_PHASE="phase3"
                run_phase3
                current_phase="phase4"
                ;;
            phase4)
                CURRENT_PHASE="phase4"
                run_phase4
                current_phase="phase5"
                ;;
            phase5)
                CURRENT_PHASE="phase5"
                run_phase5
                break
                ;;
            *)
                die "Unknown checkpoint '${current_phase}'"
                ;;
        esac
    done

    log "Bootstrap complete"
    echo "Exit chroot and reboot:"
    echo "  exit"
    echo "  umount -R /mnt"
    echo "  reboot"
}

main "$@"
