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
LIGHTDM_LOGIN_USER=""
LIGHTDM_LOGIN_SESSION="bspwm"

SUPPORTED_MODULES=(
    "lightdm|greeter,login,wallpaper,lightdm,webkit,html,css|LightDM WebKit2 login screen with custom Arch Scripts theme"
)

LIGHTDM_FILES=(
    "/etc/lightdm/lightdm.conf.d/50-arch-scripts.conf"
    "/etc/lightdm/lightdm-webkit2-greeter.conf"
    "/usr/share/lightdm-webkit/themes/arch-scripts/index.html"
    "/usr/share/lightdm-webkit/themes/arch-scripts/style.css"
    "/usr/share/lightdm-webkit/themes/arch-scripts/script.js"
    "/usr/share/lightdm-webkit/themes/arch-scripts/loginwallpaper.jpg"
    "/usr/share/backgrounds/wallpapers/loginwallpaper.jpg"
)

LIGHTDM_PACKAGES=(
    lightdm
    lightdm-webkit2-greeter
    xorg-server
    dbus
    curl
    file
    fontconfig
    adwaita-icon-theme
    gdk-pixbuf2
    webkit2gtk
    ttf-ibm-plex
    inter-font
    ttf-montserrat
    ttf-material-symbols-variable
)

usage() {
    printf "%s\n" \
        "Usage: ./arch-config.sh [--all] [--module module] [--restore module] [--list-modules] [--help]" \
        "" \
        "Options:" \
        "  --all                Apply all implemented config modules." \
        "  --module module      Apply one config module. Currently supported: lightdm." \
        "  --restore module     Restore backups for one module. Currently supported: lightdm." \
        "  --list-modules       List available modules with tags." \
        "  --login-user user    User shown/authenticated by the LightDM theme. Default: current user." \
        "  --login-session ses  Session key used after login. Default: bspwm." \
        "  -h, --help           Show this help."
}

list_modules() {
    local item module tags description

    printf "Available modules:\n\n"
    for item in "${SUPPORTED_MODULES[@]}"; do
        IFS='|' read -r module tags description <<< "${item}"
        printf "  %s\n" "${module}"
        printf "    tags: %s\n" "${tags}"
        printf "    desc: %s\n\n" "${description}"
    done
}

module_supported() {
    [[ $1 == "lightdm" ]]
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
            --login-user)
                [[ $# -ge 2 ]] || die "--login-user requires a username"
                LIGHTDM_LOGIN_USER="$2"
                shift 2
                ;;
            --login-session)
                [[ $# -ge 2 ]] || die "--login-session requires a session key"
                LIGHTDM_LOGIN_SESSION="$2"
                shift 2
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
        module_supported "${MODULE}" || die "Unsupported module: ${MODULE}"
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
    command -v sudo >/dev/null 2>&1 || die "sudo is required"
    log "Checking sudo access"
    sudo -v || die "sudo access is required"
}

check_not_chroot() {
    local current_root init_root
    current_root=$(stat -Lc '%d:%i' / 2>/dev/null || true)
    init_root=$(stat -Lc '%d:%i' /proc/1/root 2>/dev/null || true)

    if [[ -n ${current_root} && -n ${init_root} && ${current_root} != "${init_root}" ]]; then
        die "This script must be run after first boot, not inside arch-chroot"
    fi
}

require_commands() {
    local missing=() command_name

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
    require_commands id stat pacman systemctl install cp mkdir rm tee mktemp dirname basename getent grep sed
    ensure_curl
    check_network_to_github
}

module_backup_dir() {
    printf "%s/%s\n" "${BACKUP_DIR}" "$1"
}

module_targets() {
    case "$1" in
        lightdm)
            printf "%s\n" "${LIGHTDM_FILES[@]}"
            ;;
        *)
            die "Unsupported module: $1"
            ;;
    esac
}

backup_module() {
    local module="$1" module_dir target
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
    local module="$1" module_dir target
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
    local url="$1" output="$2"
    curl -fL --connect-timeout 10 --max-time 120 "${url}" -o "${output}"
}

install_downloaded_root_file() {
    local relative_path="$1" target="$2" mode="$3" tmp_file

    tmp_file=$(mktemp "${TMP_DIR}/download.XXXXXX")
    download_file "${BASE_RAW_URL}/${relative_path}" "${tmp_file}"
    sudo install -Dm "${mode}" "${tmp_file}" "${target}"
    rm -f "${tmp_file}"
}

install_lightdm_packages() {
    log "Installing LightDM WebKit greeter packages"
    sudo pacman -S --needed --noconfirm "${LIGHTDM_PACKAGES[@]}"
}

validate_lightdm_user_and_session() {
    LIGHTDM_LOGIN_USER=${LIGHTDM_LOGIN_USER:-${TARGET_USER}}

    [[ ${LIGHTDM_LOGIN_USER} =~ ^[a-z_][a-z0-9_-]*$ ]] || die "Invalid login username: ${LIGHTDM_LOGIN_USER}"
    getent passwd "${LIGHTDM_LOGIN_USER}" >/dev/null 2>&1 || die "Login user does not exist: ${LIGHTDM_LOGIN_USER}"

    [[ ${LIGHTDM_LOGIN_SESSION} =~ ^[A-Za-z0-9_.@+-]+$ ]] || die "Invalid login session key: ${LIGHTDM_LOGIN_SESSION}"
    if [[ ! -f /usr/share/xsessions/${LIGHTDM_LOGIN_SESSION}.desktop && ! -f /usr/share/wayland-sessions/${LIGHTDM_LOGIN_SESSION}.desktop ]]; then
        die "Session file not found for '${LIGHTDM_LOGIN_SESSION}'. Expected /usr/share/xsessions/${LIGHTDM_LOGIN_SESSION}.desktop or /usr/share/wayland-sessions/${LIGHTDM_LOGIN_SESSION}.desktop"
    fi
}

install_lightdm_wallpaper() {
    local user_wallpaper_dir="${TARGET_HOME}/Pictures/wallpaper"
    local user_wallpaper="${user_wallpaper_dir}/loginwallpaper.jpg"
    local system_wallpaper="/usr/share/backgrounds/wallpapers/loginwallpaper.jpg"
    local theme_wallpaper="/usr/share/lightdm-webkit/themes/arch-scripts/loginwallpaper.jpg"
    local tmp_file

    log "Downloading wallpaper"
    mkdir -p "${user_wallpaper_dir}"

    tmp_file=$(mktemp "${TMP_DIR}/wallpaper.XXXXXX")
    download_file "${BASE_RAW_URL}/wallpapers/loginwallpaper.jpg" "${tmp_file}"
    install -Dm 0644 "${tmp_file}" "${user_wallpaper}"
    sudo install -Dm 0644 "${user_wallpaper}" "${system_wallpaper}"
    sudo install -Dm 0644 "${user_wallpaper}" "${theme_wallpaper}"
    sudo chmod 0755 /usr/share/backgrounds /usr/share/backgrounds/wallpapers /usr/share/lightdm-webkit /usr/share/lightdm-webkit/themes /usr/share/lightdm-webkit/themes/arch-scripts
    sudo chmod 0644 "${system_wallpaper}" "${theme_wallpaper}"
    rm -f "${tmp_file}"
}

check_lightdm_wallpaper() {
    local user_wallpaper="${TARGET_HOME}/Pictures/wallpaper/loginwallpaper.jpg"
    local system_wallpaper="/usr/share/backgrounds/wallpapers/loginwallpaper.jpg"
    local theme_wallpaper="/usr/share/lightdm-webkit/themes/arch-scripts/loginwallpaper.jpg"
    local file_path mime_type

    for file_path in "${user_wallpaper}" "${system_wallpaper}" "${theme_wallpaper}"; do
        if [[ ${file_path} == /usr/* ]]; then
            sudo test -s "${file_path}" || die "Wallpaper missing or empty at ${file_path}"
            mime_type=$(sudo file -b --mime-type "${file_path}" 2>/dev/null || true)
        else
            [[ -s ${file_path} ]] || die "Wallpaper missing or empty at ${file_path}"
            mime_type=$(file -b --mime-type "${file_path}" 2>/dev/null || true)
        fi

        case "${mime_type}" in
            image/jpeg|image/png|image/webp)
                ;;
            *)
                die "Wallpaper at ${file_path} is not a supported image file; detected MIME: ${mime_type:-unknown}"
                ;;
        esac
    done
}

write_root_file() {
    local target="$1" mode="$2" tmp_file
    tmp_file=$(mktemp "${TMP_DIR}/rootfile.XXXXXX")
    cat > "${tmp_file}"
    sudo install -Dm "${mode}" "${tmp_file}" "${target}"
    rm -f "${tmp_file}"
}

install_lightdm_configs() {
    log "Installing LightDM config and WebKit theme"

    write_root_file "/etc/lightdm/lightdm.conf.d/50-arch-scripts.conf" 0644 <<EOF
[Seat:*]
greeter-session=lightdm-webkit2-greeter
user-session=${LIGHTDM_LOGIN_SESSION}
EOF

    write_root_file "/etc/lightdm/lightdm-webkit2-greeter.conf" 0644 <<'EOF'
[greeter]
webkit-theme=arch-scripts
debug_mode=false
EOF

    install_downloaded_root_file "configs/lightdm-webkit/index.html" "/usr/share/lightdm-webkit/themes/arch-scripts/index.html" 0644
    install_downloaded_root_file "configs/lightdm-webkit/style.css" "/usr/share/lightdm-webkit/themes/arch-scripts/style.css" 0644
    install_downloaded_root_file "configs/lightdm-webkit/script.js" "/usr/share/lightdm-webkit/themes/arch-scripts/script.js" 0644

    sudo sed -i "s/__ARCH_LOGIN_USER__/${LIGHTDM_LOGIN_USER}/g; s/__ARCH_LOGIN_SESSION__/${LIGHTDM_LOGIN_SESSION}/g" "/usr/share/lightdm-webkit/themes/arch-scripts/script.js"
}

lightdm_module_present() {
    command -v lightdm >/dev/null 2>&1 \
        || command -v lightdm-webkit2-greeter >/dev/null 2>&1 \
        || sudo test -e /etc/lightdm/lightdm.conf.d/50-arch-scripts.conf \
        || sudo test -e /etc/lightdm/lightdm-webkit2-greeter.conf \
        || sudo test -e /usr/share/lightdm-webkit/themes/arch-scripts
}

reset_lightdm_module_files() {
    log "Removing existing LightDM module files before reinstall"
    sudo rm -rf /usr/share/lightdm-webkit/themes/arch-scripts
    sudo rm -f /etc/lightdm/lightdm.conf.d/50-arch-scripts.conf /etc/lightdm/lightdm-webkit2-greeter.conf
}

disable_old_greetd() {
    log "Disabling old greetd service if present"
    sudo systemctl disable greetd.service >/dev/null 2>&1 || true
}

remove_old_regreet_packages() {
    local old_packages=(greetd-regreet greetd-tuigreet cage greetd)
    local installed=() package

    for package in "${old_packages[@]}"; do
        if pacman -Qq "${package}" >/dev/null 2>&1; then
            installed+=("${package}")
        fi
    done

    if [[ ${#installed[@]} -gt 0 ]]; then
        log "Removing old greetd/ReGreet packages: ${installed[*]}"
        sudo pacman -Rns --noconfirm "${installed[@]}" || log "Some old packages could not be removed because other packages still require them"
    fi
}

verify_lightdm_fonts() {
    require_commands fc-match fc-cache
    fc-match "IBM Plex Sans" >/dev/null 2>&1 || die "IBM Plex Sans font is not available"
    fc-match "Inter" >/dev/null 2>&1 || die "Inter font is not available"
    fc-match "Montserrat" >/dev/null 2>&1 || die "Montserrat font is not available"
    fc-match "Material Symbols Outlined" >/dev/null 2>&1 || die "Material Symbols Outlined font is not available"
    sudo fc-cache -f >/dev/null 2>&1 || true
}

verify_lightdm() {
    log "Verifying LightDM setup"
    require_commands lightdm lightdm-webkit2-greeter

    sudo test -f /etc/lightdm/lightdm.conf.d/50-arch-scripts.conf || die "LightDM seat config is missing"
    sudo test -f /etc/lightdm/lightdm-webkit2-greeter.conf || die "LightDM WebKit greeter config is missing"
    sudo test -f /usr/share/lightdm-webkit/themes/arch-scripts/index.html || die "Theme index.html is missing"
    sudo test -f /usr/share/lightdm-webkit/themes/arch-scripts/style.css || die "Theme style.css is missing"
    sudo test -f /usr/share/lightdm-webkit/themes/arch-scripts/script.js || die "Theme script.js is missing"
    check_lightdm_wallpaper
    verify_lightdm_fonts

    sudo grep -q 'greeter-session=lightdm-webkit2-greeter' /etc/lightdm/lightdm.conf.d/50-arch-scripts.conf \
        || die "LightDM is not configured to use lightdm-webkit2-greeter"
    sudo grep -q 'webkit-theme=arch-scripts' /etc/lightdm/lightdm-webkit2-greeter.conf \
        || die "LightDM WebKit greeter is not configured to use arch-scripts theme"
}

enable_lightdm() {
    log "Enabling LightDM"
    sudo systemctl enable lightdm.service >/dev/null
    sudo systemctl is-enabled --quiet lightdm.service || die "lightdm.service is not enabled"
}

apply_lightdm() {
    sudo mkdir -p "${STATE_DIR}" "${BACKUP_DIR}"
    rm -rf "${TMP_DIR}"
    mkdir -p "${TMP_DIR}"

    validate_lightdm_user_and_session
    backup_module lightdm

    if lightdm_module_present; then
        log "Existing LightDM module state detected; reinstalling owned files from current configs"
        reset_lightdm_module_files
    fi

    disable_old_greetd
    install_lightdm_packages
    install_lightdm_wallpaper
    install_lightdm_configs
    verify_lightdm
    remove_old_regreet_packages
    enable_lightdm

    log "LightDM module applied"
}

apply_all() {
    apply_lightdm
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
                lightdm)
                    apply_lightdm
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
    echo "Reboot to see the updated LightDM greeter:"
    echo "  sudo reboot"
}

main "$@"
