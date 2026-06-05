#!/usr/bin/env bash

# Remove the old greetd/ReGreet/tuigreet setup before switching to LightDM.
# Intended to run after first boot as the normal sudo user.

set -Eeuo pipefail

log() { printf "[arch-remove-regreet] %s\n" "$*" >&2; }
die() { printf "[arch-remove-regreet] ERROR: %s\n" "$*" >&2; exit 1; }

DRY_RUN=0
REMOVE_SHARED_WALLPAPER=0

TARGET_USER=${SUDO_USER:-${USER:-}}
TARGET_HOME=${HOME:-}

OLD_PACKAGES=(
    greetd-regreet
    greetd-tuigreet
    greetd
    cage
)

OLD_FILES=(
    /etc/greetd/config.toml
    /etc/greetd/regreet.toml
    /etc/greetd/regreet.css
    /var/lib/regreet/state.toml
)

OLD_DIRS=(
    /var/lib/regreet
    /var/lib/greetd
    /var/log/greetd
    /tmp/arch-config
)

usage() {
    cat <<'EOF'
Usage: ./arch-remove-regreet.sh [--dry-run] [--remove-wallpaper] [--help]

Options:
  --dry-run           Show what would be removed without removing it.
  --remove-wallpaper  Also remove shared login wallpaper copies. Do this only after LightDM has been reinstalled or if you do not want the wallpaper anymore.
  -h, --help          Show this help.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --remove-wallpaper)
                REMOVE_SHARED_WALLPAPER=1
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                die "Unknown option: $1"
                ;;
        esac
    done
}

run() {
    if [[ ${DRY_RUN} -eq 1 ]]; then
        printf '[dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

sudo_rm_rf() {
    local target="$1"

    if [[ ${DRY_RUN} -eq 1 ]]; then
        printf '[dry-run] sudo rm -rf -- %s\n' "${target}"
        return 0
    fi

    sudo rm -rf -- "${target}" 2>/dev/null && return 0

    log "Normal removal failed for ${target}; retrying after resetting permissions"
    sudo find "${target}" -depth -exec chmod u+rwX {} + 2>/dev/null || true
    sudo rm -rf -- "${target}"
}

sudo_rm_f() {
    local target="$1"

    if [[ ${DRY_RUN} -eq 1 ]]; then
        printf '[dry-run] sudo rm -f -- %s\n' "${target}"
        return 0
    fi

    sudo rm -f -- "${target}" 2>/dev/null && return 0

    log "Normal removal failed for ${target}; retrying after resetting permissions"
    sudo chmod u+rw -- "${target}" 2>/dev/null || true
    sudo rm -f -- "${target}"
}

ensure_normal_user() {
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        die "Run this script as your normal user, not root"
    fi

    [[ -n ${TARGET_USER} ]] || die "Could not determine current user"
    [[ -n ${TARGET_HOME} && -d ${TARGET_HOME} ]] || die "Could not determine home directory"
}

ensure_sudo() {
    command -v sudo >/dev/null 2>&1 || die "sudo is required"
    log "Checking sudo access"
    sudo -v || die "sudo access is required"
}

disable_greetd() {
    log "Disabling and stopping old greetd service"
    run sudo systemctl disable --now greetd.service >/dev/null 2>&1 || true
}

remove_old_files() {
    local file dir

    log "Removing old greetd/ReGreet files"
    for file in "${OLD_FILES[@]}"; do
        if sudo test -e "${file}" || sudo test -L "${file}"; then
            sudo_rm_f "${file}"
        fi
    done

    for dir in "${OLD_DIRS[@]}"; do
        if sudo test -e "${dir}" || [[ -e ${dir} ]]; then
            sudo_rm_rf "${dir}"
        fi
    done

    if sudo test -d /etc/greetd; then
        if [[ ${DRY_RUN} -eq 1 ]]; then
            printf '[dry-run] sudo rmdir /etc/greetd\n'
        else
            sudo rmdir /etc/greetd >/dev/null 2>&1 || true
        fi
    fi
}

remove_old_wallpaper() {
    if [[ ${REMOVE_SHARED_WALLPAPER} -ne 1 ]]; then
        log "Keeping shared wallpaper copies. Use --remove-wallpaper to remove them."
        return 0
    fi

    log "Removing shared wallpaper copies"
    sudo_rm_f /usr/share/backgrounds/wallpapers/loginwallpaper.jpg
    sudo_rm_f /usr/share/lightdm-webkit/themes/arch-scripts/loginwallpaper.jpg
    sudo_rm_f "${TARGET_HOME}/Pictures/wallpaper/loginwallpaper.jpg"
}

remove_old_packages() {
    local installed=() package

    for package in "${OLD_PACKAGES[@]}"; do
        if pacman -Qq "${package}" >/dev/null 2>&1; then
            installed+=("${package}")
        fi
    done

    if [[ ${#installed[@]} -eq 0 ]]; then
        log "No old greetd/ReGreet packages are installed"
        return 0
    fi

    log "Removing old packages: ${installed[*]}"
    if [[ ${DRY_RUN} -eq 1 ]]; then
        printf '[dry-run] sudo pacman -Rns --noconfirm %s\n' "${installed[*]}"
    else
        sudo pacman -Rns --noconfirm "${installed[@]}" \
            || log "Some packages could not be removed because another package still needs them"
    fi
}

main() {
    parse_args "$@"
    ensure_normal_user
    ensure_sudo

    disable_greetd
    remove_old_files
    remove_old_wallpaper
    remove_old_packages

    log "Old greetd/ReGreet cleanup complete"
    echo "Next step: run ./arch-config.sh --module lightdm, then reboot."
}

main "$@"
