#!/usr/bin/env bash

# Arch Linux BSPWM desktop bootstrap (interactive only)
# Intended to run after first boot as the normal sudo user.

set -Eeuo pipefail

log() { printf "[arch-bspwm] %s\n" "$*" >&2; }
die() { printf "[arch-bspwm] ERROR: %s\n" "$*" >&2; exit 1; }

STATE_DIR="/var/lib/arch-bspwm"
STATE_FILE="${STATE_DIR}/state"
BACKUP_DIR="${STATE_DIR}/backups"
TMP_DIR="/tmp/arch-bspwm"

CURRENT_PHASE=""
AUTO_RESUME=0
RESTORE_MODE=0
RESTORE_TARGET=""

TARGET_USER=${SUDO_USER:-${USER:-}}
TARGET_HOME=${HOME:-}
SCRIPT_PATH=""

DETECTED_CPU="unknown"
DETECTED_GPUS="unknown"
HAS_INTEL_GPU=0
HAS_AMD_GPU=0
HAS_NVIDIA_GPU=0
HAS_BATTERY=0
HAS_BLUETOOTH=0
NETWORK_OK=0

BASE_PACKAGES=(
    xorg-server
    xorg-xinit
    bspwm
    sxhkd
    polybar
    picom
    greetd
    greetd-tuigreet
    alacritty
    rofi
    dunst
    feh
    xclip
    firefox
    unzip
    xdg-user-dirs
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
    pulsemixer
    bluez
    bluez-utils
    ttf-profont-nerd
)

GPU_PACKAGES=()

require_commands() {
    local missing=()
    local command_name

    for command_name in "$@"; do
        command -v "${command_name}" >/dev/null 2>&1 || missing+=("${command_name}")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        die "Missing required commands: ${missing[*]}"
    fi
}

ensure_normal_user() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        die "Run this script as your normal user, not root"
    fi

    [[ -n ${TARGET_USER} ]] || die "Could not determine current user"
    [[ -n ${TARGET_HOME} && -d ${TARGET_HOME} ]] || die "Could not determine home directory"
}

ensure_sudo() {
    if ! command -v sudo >/dev/null 2>&1; then
        die "sudo is required"
    fi

    log "Checking sudo access"
    sudo -v || die "sudo access is required"
}

check_not_chroot() {
    local current_root
    local init_root
    current_root=$(stat -Lc '%d:%i' / 2>/dev/null || true)
    init_root=$(stat -Lc '%d:%i' /proc/1/root 2>/dev/null || true)

    if [[ -n ${current_root} && -n ${init_root} && ${current_root} != "${init_root}" ]]; then
        die "This script must be run after first boot, not inside arch-chroot"
    fi
}

check_required_commands() {
    require_commands \
        awk cat chmod cp date dirname find grep id install mkdir mktemp mv pacman readlink rm sed sort stat systemctl tee
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
Usage: ./arch-bspwm.sh [--resume] [--restore phaseX]

Options:
  --resume           Resume from saved checkpoint without resume prompt.
  --restore phaseX   Restore files backed up for phaseX and set state to phaseX.
  -h, --help         Show this help.
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
    case "$1" in
        phase5)
            printf "%s\n" \
                "/etc/greetd/config.toml" \
                "${TARGET_HOME}/.xinitrc" \
                "${TARGET_HOME}/.config/bspwm/bspwmrc" \
                "${TARGET_HOME}/.config/sxhkd/sxhkdrc"
            ;;
        *)
            ;;
    esac
}

backup_for_phase() {
    local phase="$1"
    local phase_backup_dir="${BACKUP_DIR}/${phase}"

    sudo rm -rf "${phase_backup_dir}"
    sudo mkdir -p "${phase_backup_dir}"

    while IFS= read -r target; do
        [[ -z ${target} ]] && continue

        if [[ -e ${target} || -L ${target} ]]; then
            local dest="${phase_backup_dir}${target}"
            sudo mkdir -p "$(dirname "${dest}")"
            sudo cp -a "${target}" "${dest}"
        fi
    done < <(phase_targets "${phase}")

    log "Prepared backups for ${phase} in ${phase_backup_dir}"
}

restore_phase_files() {
    local phase="$1"
    local phase_backup_dir="${BACKUP_DIR}/${phase}"

    sudo test -d "${phase_backup_dir}" || die "No backup directory found for ${phase}: ${phase_backup_dir}"

    while IFS= read -r target; do
        [[ -z ${target} ]] && continue

        local src="${phase_backup_dir}${target}"
        if sudo test -e "${src}" || sudo test -L "${src}"; then
            sudo mkdir -p "$(dirname "${target}")"
            sudo cp -a "${src}" "${target}"
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
        if sudo test -d "${BACKUP_DIR}/${CURRENT_PHASE}"; then
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

    printf "%s\n" "${next_phase}" | sudo tee "${STATE_FILE}" >/dev/null
    backup_for_phase "${next_phase}"
    log "Checkpoint saved: next phase is ${next_phase}"
}

read_or_init_state() {
    sudo mkdir -p "${STATE_DIR}" "${BACKUP_DIR}"

    if sudo test -s "${STATE_FILE}"; then
        local saved_phase
        saved_phase=$(sudo cat "${STATE_FILE}")

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

        sudo rm -rf "${BACKUP_DIR}"
        sudo mkdir -p "${BACKUP_DIR}"
    fi

    if [[ ${AUTO_RESUME} -eq 1 ]]; then
        die "--resume requested but no checkpoint state file exists"
    fi

    printf "%s\n" "phase1" | sudo tee "${STATE_FILE}" >/dev/null
    backup_for_phase "phase1"
    log "Initialized new state file"
    printf "%s\n" "phase1"
}

detect_cpu() {
    DETECTED_CPU=$(awk -F: '/model name/ { sub(/^[ \t]+/, "", $2); print $2; exit }' /proc/cpuinfo 2>/dev/null || true)
    [[ -n ${DETECTED_CPU} ]] || DETECTED_CPU="unknown"
}

detect_gpus_from_sysfs() {
    local vendor
    local found=0

    HAS_INTEL_GPU=0
    HAS_AMD_GPU=0
    HAS_NVIDIA_GPU=0

    if compgen -G "/sys/class/drm/card*/device/vendor" >/dev/null 2>&1; then
        while IFS= read -r vendor_file; do
            vendor=$(cat "${vendor_file}" 2>/dev/null || true)
            case "${vendor}" in
                0x8086)
                    HAS_INTEL_GPU=1
                    found=1
                    ;;
                0x1002|0x1022)
                    HAS_AMD_GPU=1
                    found=1
                    ;;
                0x10de)
                    HAS_NVIDIA_GPU=1
                    found=1
                    ;;
                *)
                    ;;
            esac
        done < <(find /sys/class/drm -maxdepth 3 -path '/sys/class/drm/card*/device/vendor' 2>/dev/null | sort)
    fi

    if [[ ${found} -eq 0 ]]; then
        DETECTED_GPUS="none detected"
    else
        local names=()
        [[ ${HAS_INTEL_GPU} -eq 1 ]] && names+=("Intel")
        [[ ${HAS_AMD_GPU} -eq 1 ]] && names+=("AMD")
        [[ ${HAS_NVIDIA_GPU} -eq 1 ]] && names+=("NVIDIA")
        DETECTED_GPUS="${names[*]}"
    fi
}

detect_battery() {
    if compgen -G "/sys/class/power_supply/BAT*" >/dev/null 2>&1; then
        HAS_BATTERY=1
    else
        HAS_BATTERY=0
    fi
}

detect_bluetooth() {
    if compgen -G "/sys/class/bluetooth/hci*" >/dev/null 2>&1; then
        HAS_BLUETOOTH=1
    elif command -v rfkill >/dev/null 2>&1 && rfkill list bluetooth >/dev/null 2>&1; then
        HAS_BLUETOOTH=1
    else
        HAS_BLUETOOTH=0
    fi
}

check_network() {
    if command -v ping >/dev/null 2>&1 && ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
        NETWORK_OK=1
    else
        NETWORK_OK=0
    fi
}

detect_system_info() {
    detect_cpu
    detect_gpus_from_sysfs
    detect_battery
    detect_bluetooth
    check_network
}

gpu_packages_from_detection() {
    GPU_PACKAGES=()

    if [[ ${HAS_NVIDIA_GPU} -eq 1 ]]; then
        GPU_PACKAGES+=(nvidia)
    fi

    if [[ ${HAS_AMD_GPU} -eq 1 ]]; then
        GPU_PACKAGES+=(mesa vulkan-radeon)
    fi

    if [[ ${HAS_INTEL_GPU} -eq 1 ]]; then
        GPU_PACKAGES+=(mesa vulkan-intel intel-media-driver)
    fi
}

dedupe_packages() {
    local seen=""
    local package

    for package in "$@"; do
        case " ${seen} " in
            *" ${package} "*)
                ;;
            *)
                seen="${seen} ${package}"
                printf "%s\n" "${package}"
                ;;
        esac
    done
}

print_system_summary() {
    echo "========================================="
    echo "Arch BSPWM Desktop Setup"
    echo "========================================="
    echo "User      : ${TARGET_USER}"
    echo "Home      : ${TARGET_HOME}"
    echo "CPU       : ${DETECTED_CPU}"
    echo "GPUs      : ${DETECTED_GPUS}"
    echo "Battery   : $([[ ${HAS_BATTERY} -eq 1 ]] && echo yes || echo no)"
    echo "Bluetooth : $([[ ${HAS_BLUETOOTH} -eq 1 ]] && echo detected || echo not-detected)"
    echo "Network   : $([[ ${NETWORK_OK} -eq 1 ]] && echo reachable || echo not-confirmed)"

    if command -v lspci >/dev/null 2>&1; then
        echo ""
        echo "GPU details:"
        lspci | grep -Ei 'vga|3d|display' || true
    fi

    gpu_packages_from_detection

    echo ""
    if [[ ${#GPU_PACKAGES[@]} -gt 0 ]]; then
        echo "GPU packages: ${GPU_PACKAGES[*]}"
    else
        echo "GPU packages: none selected from detection"
    fi
    echo ""

    read -rp "Continue BSPWM desktop setup? (y/N): " ans
    [[ ${ans,,} == y ]] || die "Setup cancelled by user"
}

install_yay() {
    if command -v yay >/dev/null 2>&1; then
        log "yay already installed"
        return 0
    fi

    sudo pacman -Syu --needed --noconfirm git base-devel
    require_commands git makepkg

    mkdir -p "${TMP_DIR}"
    rm -rf "${TMP_DIR}/yay"

    log "Cloning yay from AUR"
    git clone https://aur.archlinux.org/yay.git "${TMP_DIR}/yay"

    log "Building and installing yay"
    (cd "${TMP_DIR}/yay" && makepkg -si --noconfirm)
}

install_packages() {
    local packages=("${BASE_PACKAGES[@]}")

    gpu_packages_from_detection
    if [[ ${#GPU_PACKAGES[@]} -gt 0 ]]; then
        packages+=("${GPU_PACKAGES[@]}")
    fi

    mapfile -t packages < <(dedupe_packages "${packages[@]}")

    log "Updating system"
    sudo pacman -Syu --noconfirm

    log "Installing packages: ${packages[*]}"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

enable_services_and_user_setup() {
    log "Enabling greetd"
    sudo systemctl enable greetd.service

    log "Enabling Bluetooth"
    sudo systemctl enable --now bluetooth.service || log "Failed to enable/start bluetooth.service"

    log "Updating XDG user directories"
    xdg-user-dirs-update || log "xdg-user-dirs-update failed"

    log "Enabling PipeWire user services"
    systemctl --user enable --now pipewire pipewire-pulse wireplumber || log "Failed to enable PipeWire user services"
}

write_user_file() {
    local target="$1"
    local mode="$2"
    local tmp_file

    tmp_file=$(mktemp)
    cat > "${tmp_file}"
    install -Dm "${mode}" "${tmp_file}" "${target}"
    rm -f "${tmp_file}"
}

write_root_file() {
    local target="$1"
    local mode="$2"
    local tmp_file

    tmp_file=$(mktemp)
    cat > "${tmp_file}"
    sudo install -Dm "${mode}" "${tmp_file}" "${target}"
    rm -f "${tmp_file}"
}

write_configs() {
    log "Writing greetd configuration"
    write_root_file "/etc/greetd/config.toml" 0644 <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --remember --time --cmd startx"
user = "greeter"
EOF

    log "Writing .xinitrc"
    write_user_file "${TARGET_HOME}/.xinitrc" 0755 <<'EOF'
#!/usr/bin/env sh

exec bspwm
EOF

    log "Writing minimal bspwmrc"
    write_user_file "${TARGET_HOME}/.config/bspwm/bspwmrc" 0755 <<'EOF'
#!/usr/bin/env sh

pgrep -x sxhkd >/dev/null || sxhkd &
pgrep -x dunst >/dev/null || dunst &
pgrep -x picom >/dev/null || picom &

if command -v polybar >/dev/null 2>&1; then
    polybar-msg cmd quit >/dev/null 2>&1 || true
    polybar example >/dev/null 2>&1 &
fi

bspc monitor -d I II III IV V VI VII VIII IX X
EOF

    log "Writing minimal sxhkdrc"
    write_user_file "${TARGET_HOME}/.config/sxhkd/sxhkdrc" 0644 <<'EOF'
super + Return
    alacritty

super + d
    rofi -show drun

super + shift + q
    bspc node -c

super + Escape
    pkill -USR1 -x sxhkd

super + alt + r
    bspc wm -r

super + alt + q
    bspc quit
EOF

    chown_user_configs
}

chown_user_configs() {
    sudo chown "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.xinitrc" || true
    sudo chown -R "${TARGET_USER}:${TARGET_USER}" "${TARGET_HOME}/.config/bspwm" "${TARGET_HOME}/.config/sxhkd" || true
}

cleanup_after_install() {
    read -rp "Remove BSPWM installer state and backups at ${STATE_DIR}? (y/N): " clean_state
    if [[ ${clean_state,,} == y ]]; then
        sudo rm -rf "${STATE_DIR}" && log "Removed ${STATE_DIR}" || log "Failed to remove ${STATE_DIR}"
    else
        log "Leaving installer state at ${STATE_DIR}"
    fi

    if [[ -d ${TMP_DIR} ]]; then
        read -rp "Remove temporary build/download directory ${TMP_DIR}? (y/N): " clean_tmp
        if [[ ${clean_tmp,,} == y ]]; then
            rm -rf "${TMP_DIR}" && log "Removed ${TMP_DIR}" || log "Failed to remove ${TMP_DIR}"
        fi
    fi

    if [[ -n ${SCRIPT_PATH} && -f ${SCRIPT_PATH} && $(basename "${SCRIPT_PATH}") == "arch-bspwm.sh" ]]; then
        read -rp "Remove this installer script (${SCRIPT_PATH})? (y/N): " clean_script
        if [[ ${clean_script,,} == y ]]; then
            rm -f "${SCRIPT_PATH}" && log "Removed ${SCRIPT_PATH}" || log "Failed to remove ${SCRIPT_PATH}"
        fi
    fi
}

run_phase1() {
    log "Running phase1: preflight and hardware detection"
    ensure_normal_user
    ensure_sudo
    check_not_chroot
    check_required_commands
    detect_system_info
    print_system_summary
    set_next_phase "phase2"
}

run_phase2() {
    log "Running phase2: yay"
    install_yay
    set_next_phase "phase3"
}

run_phase3() {
    log "Running phase3: packages"
    detect_system_info
    install_packages
    set_next_phase "phase4"
}

run_phase4() {
    log "Running phase4: services and user setup"
    enable_services_and_user_setup
    set_next_phase "phase5"
}

run_phase5() {
    log "Running phase5: launch/session configuration"
    write_configs
    sudo rm -f "${STATE_FILE}"
    log "Checkpoint state cleaned"
    cleanup_after_install
}

main() {
    SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || printf "%s" "$0")

    parse_args "$@"
    ensure_normal_user
    ensure_sudo

    if [[ ${RESTORE_MODE} -eq 1 ]]; then
        is_valid_phase "${RESTORE_TARGET}" || die "Invalid restore target '${RESTORE_TARGET}'"
        sudo mkdir -p "${STATE_DIR}" "${BACKUP_DIR}"
        restore_phase_files "${RESTORE_TARGET}"
        printf "%s\n" "${RESTORE_TARGET}" | sudo tee "${STATE_FILE}" >/dev/null
        log "Restore mode complete; state set to ${RESTORE_TARGET}"
        exit 0
    fi

    local current_phase
    current_phase=$(read_or_init_state)

    if [[ ${current_phase} != "phase1" ]]; then
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

    log "BSPWM desktop setup complete"
    echo "Reboot, then log in through tuigreet."
}

main "$@"
