#!/usr/bin/env bash

# Arch Linux desktop config setup (interactive only)
# Intended to run after arch-bspwm.sh as the normal sudo user.

set -Eeuo pipefail

log() { printf "[arch-config] %s\n" "$*" >&2; }
die() { printf "[arch-config] ERROR: %s\n" "$*" >&2; exit 1; }

STATE_DIR="/var/lib/arch-config"
BACKUP_DIR="${STATE_DIR}/backups"
TMP_DIR="/tmp/arch-config"
BASE_RAW_URL="https://raw.githubusercontent.com/GuessWho121/arch-scripts/main"

TARGET_USER=${SUDO_USER:-${USER:-}}
TARGET_HOME=${HOME:-}

MODE=""
MODULE=""

SUPPORTED_MODULES=(
    "regreet|greeter,login,wallpaper,greetd,cage,gui|ReGreet graphical login screen with wallpaper"
)

REGREET_FILES=(
    "/etc/greetd/config.toml"
    "/etc/greetd/regreet.toml"
    "/etc/greetd/regreet.css"
    "/usr/share/backgrounds/wallpapers/loginwallpaper.jpg"
)

usage() {
    printf "%s\n" \
        "Usage: ./arch-config.sh [--all] [--module module] [--restore module] [--help]" \
        "" \
        "Options:" \
        "  --all              Apply all implemented config modules." \
        "  --module module    Apply one config module. Currently supported: regreet." \
        "  --restore module   Restore backups for one module. Currently supported: regreet." \
        "  --list-modules     List available modules with tags." \
        "  -h, --help         Show this help."
}

list_modules() {
    local item
    local module
    local tags
    local description

    printf "Available modules:\n\n"

    for item in "${SUPPORTED_MODULES[@]}"; do
        IFS='|' read -r module tags description <<< "${item}"
        printf "  %s\n" "${module}"
        printf "    tags: %s\n" "${tags}"
        printf "    desc: %s\n\n" "${description}"
    done
}

parse_args() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                [[ -z ${MODE} ]] || die "Use only one mode at a time"
                MODE="all"
                shift
                ;;
            --module)
                [[ -z ${MODE} ]] || die "Use only one mode at a time"
                [[ $# -ge 2 ]] || die "--module requires a module name"
                MODE="module"
                MODULE="$2"
                shift 2
                ;;
            --only)
                die "--only has been removed. Use --module instead."
                ;;
            --list-modules)
                list_modules
                exit 0
                ;;
            --restore)
                [[ -z ${MODE} ]] || die "Use only one mode at a time"
                [[ $# -ge 2 ]] || die "--restore requires a module name"
                MODE="restore"
                MODULE="$2"
                shift 2
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

    [[ -n ${MODE} ]] || die "No mode selected"

    if [[ ${MODE} != "all" ]]; then
        [[ ${MODULE} == "regreet" ]] || die "Unsupported module: ${MODULE}"
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

install_package_if_missing() {
    local package="$1"

    if ! pacman -Qq "${package}" >/dev/null 2>&1; then
        log "Installing ${package}"
        sudo pacman -S --needed --noconfirm "${package}"
    fi
}

ensure_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        install_package_if_missing curl
    fi
    require_commands curl
}

check_network_to_github() {
    local probe_url="${BASE_RAW_URL}/README.md"

    log "Checking GitHub raw content reachability"
    curl -fsIL --connect-timeout 10 --max-time 20 "${probe_url}" >/dev/null \
        || die "Could not reach ${probe_url}"
}

preflight() {
    ensure_normal_user
    ensure_sudo
    check_not_chroot
    require_commands id stat pacman systemctl install cp mkdir rm tee mktemp dirname basename
    ensure_curl
    check_network_to_github
}

module_backup_dir() {
    printf "%s/%s\n" "${BACKUP_DIR}" "$1"
}

module_targets() {
    case "$1" in
        regreet)
            printf "%s\n" "${REGREET_FILES[@]}"
            ;;
        *)
            die "Unsupported module: $1"
            ;;
    esac
}

backup_module() {
    local module="$1"
    local module_dir
    local target

    module_dir=$(module_backup_dir "${module}")

    sudo rm -rf "${module_dir}"
    sudo mkdir -p "${module_dir}"

    while IFS= read -r target; do
        [[ -z ${target} ]] && continue

        if [[ -e ${target} || -L ${target} ]]; then
            local dest="${module_dir}${target}"
            sudo mkdir -p "$(dirname "${dest}")"
            sudo cp -a "${target}" "${dest}"
        else
            local marker="${module_dir}${target}.missing"
            sudo mkdir -p "$(dirname "${marker}")"
            printf "missing\n" | sudo tee "${marker}" >/dev/null
        fi
    done < <(module_targets "${module}")

    log "Prepared backups for ${module} in ${module_dir}"
}

restore_module() {
    local module="$1"
    local module_dir
    local target

    module_dir=$(module_backup_dir "${module}")
    sudo test -d "${module_dir}" || die "No backup directory found for ${module}: ${module_dir}"

    while IFS= read -r target; do
        [[ -z ${target} ]] && continue

        local src="${module_dir}${target}"
        local marker="${module_dir}${target}.missing"

        if sudo test -e "${src}" || sudo test -L "${src}"; then
            sudo mkdir -p "$(dirname "${target}")"
            sudo cp -a "${src}" "${target}"
        elif sudo test -f "${marker}"; then
            sudo rm -f "${target}"
        fi
    done < <(module_targets "${module}")

    log "Restored backups for ${module}"
}

download_file() {
    local url="$1"
    local output="$2"

    curl -fL --connect-timeout 10 --max-time 120 "${url}" -o "${output}"
}

install_downloaded_root_file() {
    local relative_path="$1"
    local target="$2"
    local mode="$3"
    local tmp_file

    tmp_file=$(mktemp "${TMP_DIR}/download.XXXXXX")
    download_file "${BASE_RAW_URL}/${relative_path}" "${tmp_file}"
    sudo install -Dm "${mode}" "${tmp_file}" "${target}"
    rm -f "${tmp_file}"
}

install_regreet_packages() {
    log "Installing ReGreet packages"
    sudo pacman -S --needed --noconfirm cage greetd-regreet dbus curl
}

install_regreet_wallpaper() {
    local user_wallpaper_dir="${TARGET_HOME}/Pictures/wallpaper"
    local user_wallpaper="${user_wallpaper_dir}/loginwallpaper.jpg"
    local tmp_file

    log "Downloading wallpaper"
    mkdir -p "${user_wallpaper_dir}"

    tmp_file=$(mktemp "${TMP_DIR}/wallpaper.XXXXXX")
    download_file "${BASE_RAW_URL}/wallpapers/loginwallpaper.jpg" "${tmp_file}"
    install -Dm 0644 "${tmp_file}" "${user_wallpaper}"
    sudo install -Dm 0644 "${user_wallpaper}" "/usr/share/backgrounds/wallpapers/loginwallpaper.jpg"
    rm -f "${tmp_file}"
}

check_regreet_wallpaper() {
    local user_wallpaper="${TARGET_HOME}/Pictures/wallpaper/loginwallpaper.jpg"
    local system_wallpaper="/usr/share/backgrounds/wallpapers/loginwallpaper.jpg"

    [[ -s ${user_wallpaper} ]] || die "Wallpaper missing or empty at ${user_wallpaper}"
    sudo test -s "${system_wallpaper}" || die "Wallpaper missing or empty at ${system_wallpaper}"
}

check_regreet_background_config() {
    sudo grep -Eq '^[[:space:]]*path[[:space:]]*=[[:space:]]*"/usr/share/backgrounds/wallpapers/loginwallpaper\.jpg"' /etc/greetd/regreet.toml \
        || die "/etc/greetd/regreet.toml must point background.path to /usr/share/backgrounds/wallpapers/loginwallpaper.jpg"
}

install_regreet_configs() {
    log "Downloading and installing ReGreet configs"
    install_downloaded_root_file "configs/regreet/config.toml" "/etc/greetd/config.toml" 0644
    install_downloaded_root_file "configs/regreet/regreet.toml" "/etc/greetd/regreet.toml" 0644
    install_downloaded_root_file "configs/regreet/regreet.css" "/etc/greetd/regreet.css" 0644
}

regreet_is_setup() {
    command -v regreet >/dev/null 2>&1 \
        && command -v cage >/dev/null 2>&1 \
        && command -v dbus-run-session >/dev/null 2>&1 \
        && sudo test -f /usr/share/backgrounds/wallpapers/loginwallpaper.jpg \
        && [[ -f "${TARGET_HOME}/Pictures/wallpaper/loginwallpaper.jpg" ]] \
        && sudo test -f /etc/greetd/config.toml \
        && sudo test -f /etc/greetd/regreet.toml \
        && sudo test -f /etc/greetd/regreet.css \
        && ! pacman -Qq greetd-tuigreet >/dev/null 2>&1
}

verify_regreet() {
    log "Verifying ReGreet setup"

    require_commands regreet cage dbus-run-session

    sudo test -f /etc/greetd/config.toml || die "/etc/greetd/config.toml is missing"
    sudo test -f /etc/greetd/regreet.toml || die "/etc/greetd/regreet.toml is missing"
    sudo test -f /etc/greetd/regreet.css || die "/etc/greetd/regreet.css is missing"
    check_regreet_wallpaper
    check_regreet_background_config

    sudo systemctl enable greetd.service >/dev/null
    sudo systemctl is-enabled --quiet greetd.service || die "greetd.service is not enabled"
}

remove_tuigreet() {
    if pacman -Qq greetd-tuigreet >/dev/null 2>&1; then
        log "Removing greetd-tuigreet"
        sudo pacman -Rns --noconfirm greetd-tuigreet
    else
        log "greetd-tuigreet is not installed; skipping removal"
    fi
}

apply_regreet() {
    sudo mkdir -p "${STATE_DIR}" "${BACKUP_DIR}"
    rm -rf "${TMP_DIR}"
    mkdir -p "${TMP_DIR}"

    backup_module regreet

    if regreet_is_setup; then
        log "ReGreet module already appears installed; updating config files only"
        install_regreet_configs
        verify_regreet
        log "ReGreet module configs updated"
        return 0
    fi

    install_regreet_packages
    install_regreet_wallpaper
    install_regreet_configs
    verify_regreet
    remove_tuigreet

    log "ReGreet module applied"
}

apply_all() {
    apply_regreet
}

main() {
    parse_args "$@"

    if [[ ${MODE} == "restore" ]]; then
        ensure_normal_user
        ensure_sudo
        restore_module "${MODULE}"
        exit 0
    fi

    preflight

    case "${MODE}" in
        all)
            apply_all
            ;;
        module)
            case "${MODULE}" in
                regreet)
                    apply_regreet
                    ;;
                *)
                    die "Unsupported module: ${MODULE}"
                    ;;
            esac
            ;;
        *)
            die "Unknown mode: ${MODE}"
            ;;
    esac

    log "Config setup complete"
    echo "Reboot to see the updated greeter:"
    echo "  sudo reboot"
}

main "$@"
