#!/usr/bin/env bash
# ============================================================
#  AIO Debian-based Setup Script — Interactive Edition
#  Hỗ trợ: Ubuntu | Debian | Linux Mint | Kali | Pop!_OS
#           CaramOS | Zorin | Elementary | MX Linux | ...
#  Dành cho cộng đồng Linux Việt Nam 🇻🇳
#
#  Cấu trúc repo:
#  Debian-AIO-Setup-Scripts/
#  ├── AIO-Debian-Setup.sh     ← file này
#  ├── uninstall.sh
#  └── Mac-Theme-Install/
#      ├── demo1.png ~ demo4.png
#      └── Setup-Mac-themes.docx
# ============================================================

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
BG_BLUE='\033[44m'

hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }
cleanup()     { show_cursor; tput cnorm; echo ""; }
trap cleanup EXIT INT TERM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="${SCRIPT_DIR}/Mac-Theme-Install"

# ── APT wrapper ──────────────────────────────────────────────
APT="apt"
APT_OPTS="-y"
export DEBIAN_FRONTEND=noninteractive   # tắt hoàn toàn hỏi xác nhận apt

# ════════════════════════════════════════════════════════════
#  BANNER
# ════════════════════════════════════════════════════════════
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ███████╗██████╗ ██╗ █████╗ ███╗   ██╗"
    echo "  ██╔══██╗██╔════╝██╔══██╗██║██╔══██╗████╗  ██║"
    echo "  ██║  ██║█████╗  ██████╔╝██║███████║██╔██╗ ██║"
    echo "  ██║  ██║██╔══╝  ██╔══██╗██║██╔══██║██║╚██╗██║"
    echo "  ██████╔╝███████╗██████╔╝██║██║  ██║██║ ╚████║"
    echo "  ╚═════╝ ╚══════╝╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
    echo -e "${RESET}"
    echo -e "  ${WHITE}${BOLD}AIO Debian-based Setup Script${RESET}  ${GRAY}Interactive Edition${RESET}"
    echo -e "  ${GRAY}Ubuntu | Debian | Mint | Kali | Pop!_OS | CaramOS | Zorin | ...${RESET}"
    echo -e "  ${GRAY}Dành cho cộng đồng Linux Việt Nam 🇻🇳${RESET}"
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# ════════════════════════════════════════════════════════════
#  CHECKBOX MENU — 1 dòng mỗi item, 1 trang duy nhất
#  Phím: ↑/↓  j/k  di chuyển
#        SPACE      toggle
#        A          chọn tất cả (trừ disabled)
#        N          bỏ hết
#        ENTER      xác nhận
# ════════════════════════════════════════════════════════════
checkbox_menu() {
    local title="$1"
    local -n _names=$2
    local -n _descs=$3
    local -n _sel=$4
    local -n _dis=$5

    local count=${#_names[@]}
    local cursor=0
    local key

    hide_cursor

    while true; do
        tput cup 7 0

        echo -e "  ${BOLD}${WHITE}${title}${RESET}"
        echo -e "  ${GRAY}[SPACE] Toggle  [A] Tất cả  [N] Bỏ hết  [ENTER] Xác nhận  [↑↓/jk] Di chuyển${RESET}"
        echo ""

        local sel_count=0
        for i in "${!_names[@]}"; do
            [[ "${_sel[$i]}" == "1" ]] && (( sel_count++ ))
        done

        for i in "${!_names[@]}"; do
            local box line_color sep

            if [[ "${_dis[$i]}" == "1" ]]; then
                box="${GRAY}[✗]${RESET}"
                line_color="${GRAY}${DIM}"
                sep="${GRAY}${DIM}"
            elif [[ "${_sel[$i]}" == "1" ]]; then
                box="${GREEN}[✓]${RESET}"
                line_color="${GREEN}"
                sep="${GRAY}${DIM}"
            else
                box="${GRAY}[ ]${RESET}"
                line_color="${GRAY}"
                sep="${GRAY}${DIM}"
            fi

            if [[ $i -eq $cursor ]]; then
                printf '\033[2K'
                echo -e "  ${BG_BLUE}${WHITE}  ❯ ${_names[$i]}  —  ${_descs[$i]}${RESET}   "
            else
                printf '\033[2K'
                echo -e "    ${box} ${line_color}${_names[$i]}${RESET}  ${sep}—  ${_descs[$i]}${RESET}   "
            fi
        done

        echo ""
        printf '\033[2K'
        echo -e "  ${GRAY}Đã chọn: ${WHITE}${BOLD}${sel_count}/${count}${RESET}${GRAY} mục${RESET}   "
        echo ""

        IFS= read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
            case "$key" in
                '[A') (( cursor > 0 ))       && (( cursor-- )) ;;
                '[B') (( cursor < count-1 )) && (( cursor++ )) ;;
            esac
        else
            case "$key" in
                'k') (( cursor > 0 ))       && (( cursor-- )) ;;
                'j') (( cursor < count-1 )) && (( cursor++ )) ;;
                ' ')
                    if [[ "${_dis[$cursor]}" != "1" ]]; then
                        [[ "${_sel[$cursor]}" == "1" ]] \
                            && _sel[$cursor]="0" \
                            || _sel[$cursor]="1"
                    fi ;;
                'a'|'A') for i in "${!_names[@]}"; do
                    [[ "${_dis[$i]}" != "1" ]] && _sel[$i]="1"; done ;;
                'n'|'N') for i in "${!_names[@]}"; do
                    [[ "${_dis[$i]}" != "1" ]] && _sel[$i]="0"; done ;;
                '') show_cursor; return 0 ;;
            esac
        fi
    done
}

# ════════════════════════════════════════════════════════════
#  LOG HELPERS
# ════════════════════════════════════════════════════════════
log_step() { echo -e "\n  ${CYAN}${BOLD}▶ ${1}${RESET}"; }
log_ok()   { echo -e "  ${GREEN}✓ ${1}${RESET}"; }
log_warn() { echo -e "  ${YELLOW}⚠ ${1}${RESET}"; }
log_div()  { echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }

# ════════════════════════════════════════════════════════════
#  DETECT DISTRO
# ════════════════════════════════════════════════════════════
detect_distro() {
    local id="" id_like=""

    if [[ -f /etc/os-release ]]; then
        id=$(grep "^ID=" /etc/os-release \
            | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
        id_like=$(grep "^ID_LIKE=" /etc/os-release \
            | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
    fi

    # ── Lớp 1: ID và ID_LIKE trong /etc/os-release ──────────
    # Hầu hết distro đều có — Ubuntu, Debian, Mint, Kali,
    # Pop, Zorin, Elementary, MX, Parrot, Deepin, CaramOS...
    #
    # Check cả "linuxmint" vì CaramOS dựa trên Mint Cinnamon
    # có thể khai báo ID_LIKE=linuxmint thay vì ubuntu/debian
    if [[ "$id"      == "debian"     || "$id"      == "ubuntu"     || \
          "$id"      == "linuxmint"  || \
          "$id_like" == *"debian"*   || "$id_like" == *"ubuntu"*   || \
          "$id_like" == *"linuxmint"* ]]; then
        echo "$id"
        return 0
    fi

    # ── Lớp 2: /etc/debian_version ──────────────────────────
    # File này tồn tại trên MỌI hệ thống Debian-based
    # kể cả distro mới không khai báo ID_LIKE (Cacaramos, ...)
    if [[ -f /etc/debian_version ]]; then
        echo "${id:-debian-based}"
        return 0
    fi

    # ── Lớp 3: dpkg + apt binary ────────────────────────────
    # Fallback cuối — nếu có dpkg/apt thì chắc chắn là Debian-based
    if command -v dpkg &>/dev/null && command -v apt &>/dev/null; then
        echo "${id:-debian-based}"
        return 0
    fi

    # ── Không phải Debian-based ──────────────────────────────
    echo "unknown"
    return 1
}

get_distro_name() {
    grep "^PRETTY_NAME=" /etc/os-release 2>/dev/null \
        | cut -d= -f2 | tr -d '"' \
        || echo "Unknown Distro"
}

get_distro_version() {
    grep "^VERSION_ID=" /etc/os-release 2>/dev/null \
        | cut -d= -f2 | tr -d '"' \
        || grep "^VERSION=" /etc/os-release 2>/dev/null \
        | cut -d= -f2 | tr -d '"' \
        || cat /etc/debian_version 2>/dev/null \
        || echo ""
}

# Trả về icon + tên distro + thông báo hỗ trợ
print_distro_banner() {
    local id="$1"
    local name="$2"
    local ver="$3"

    local icon="" color="" support_msg=""
    # Một số distro không có version riêng (CaramOS...)
    local hide_ver=0

    case "$id" in
        ubuntu)
            icon="🟠"; color="${YELLOW}"
            support_msg="Hỗ trợ đầy đủ" ;;
        debian)
            icon="🌀"; color="${RED}"
            support_msg="Hỗ trợ đầy đủ" ;;
        linuxmint)
            icon="🍃"; color="${GREEN}"
            support_msg="Hỗ trợ đầy đủ" ;;
        kali)
            icon="🐉"; color="${BLUE:-\033[0;34m}"
            support_msg="Hỗ trợ đầy đủ" ;;
        pop)
            icon="🚀"; color="${CYAN}"
            support_msg="Hỗ trợ đầy đủ" ;;
        zorin)
            icon="💠"; color="${CYAN}"
            support_msg="Hỗ trợ đầy đủ" ;;
        elementary)
            icon="🔵"; color="${CYAN}"
            support_msg="Hỗ trợ đầy đủ" ;;
        mx)
            icon="⚙️ "; color="${GRAY}"
            support_msg="Hỗ trợ đầy đủ" ;;
        parrot)
            icon="🦜"; color="${CYAN}"
            support_msg="Hỗ trợ đầy đủ" ;;
        deepin)
            icon="🎨"; color="${CYAN}"
            support_msg="Hỗ trợ đầy đủ" ;;
        caramos|cacaramos)
            icon="🌟"; color="${YELLOW}"
            support_msg="Hỗ trợ đầy đủ (dựa trên Linux Mint 22.3 Cinnamon)"
            hide_ver=1 ;;
        raspbian)
            icon="🍓"; color="${RED}"
            support_msg="Hỗ trợ — kiến trúc ARM" ;;
        "debian-based")
            icon="📦"; color="${GRAY}"
            support_msg="Phát hiện qua dpkg/apt — có thể hoạt động" ;;
        *)
            icon="🐧"; color="${WHITE}"
            support_msg="Distro chưa được test — tiến hành cẩn thận" ;;
    esac

    echo ""
    echo -e "  ${color}${BOLD}${icon}  Phát hiện: ${name}${RESET}"
    [[ -n "$ver" && $hide_ver -eq 0 ]] &&     echo -e "  ${GRAY}   Phiên bản : ${WHITE}${ver}${RESET}"
    echo -e "  ${GRAY}   Trạng thái: ${GREEN}${support_msg}${RESET}"
    echo ""
}

# ════════════════════════════════════════════════════════════
#  DETECT DESKTOP ENVIRONMENT
# ════════════════════════════════════════════════════════════
detect_desktop_env() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || \
       [[ "$DESKTOP_SESSION" == *"gnome"* ]]      || \
       pgrep -x gnome-shell &>/dev/null            || \
       { command -v gsettings &>/dev/null && \
         gsettings get org.gnome.desktop.interface color-scheme &>/dev/null; }; then
        echo "gnome"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]] || \
       [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]        || \
       pgrep -x Hyprland &>/dev/null; then
        echo "hyprland"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || pgrep -x plasmashell &>/dev/null; then
        echo "kde"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"XFCE"* ]] || pgrep -x xfce4-session &>/dev/null; then
        echo "xfce"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"Cinnamon"* ]] || pgrep -x cinnamon &>/dev/null; then
        echo "cinnamon"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"MATE"* ]] || pgrep -x mate-session &>/dev/null; then
        echo "mate"; return
    fi
    echo "other"
}

# ════════════════════════════════════════════════════════════
#  KIỂM TRA DEPENDENCIES CƠ BẢN
# ════════════════════════════════════════════════════════════
check_dependencies() {
    log_step "Kiểm tra dependencies (wget, curl, gpg, software-properties-common)"
    local missing=()
    command -v wget  &>/dev/null || missing+=("wget")
    command -v curl  &>/dev/null || missing+=("curl")
    command -v gpg   &>/dev/null || missing+=("gnupg")
    command -v add-apt-repository &>/dev/null || missing+=("software-properties-common")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Thiếu: ${missing[*]} — đang cài..."
        sudo $APT update $APT_OPTS
        sudo $APT install $APT_OPTS "${missing[@]}"
        log_ok "Đã cài: ${missing[*]}"
    else
        log_ok "Tất cả dependencies đã có sẵn"
    fi
}

# Auto-enable Flathub nếu chưa có
ensure_flathub() {
    # Cài flatpak nếu chưa có
    if ! command -v flatpak &>/dev/null; then
        log_warn "Flatpak chưa có — đang cài..."
        sudo $APT install $APT_OPTS flatpak
    fi
    if ! flatpak remotes 2>/dev/null | grep -q "flathub"; then
        log_warn "Flathub chưa kích hoạt — đang bật..."
        sudo flatpak remote-add --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
        log_ok "Flathub đã kích hoạt"
    fi
}

# ════════════════════════════════════════════════════════════
#  MODULE: HỆ THỐNG & KHO
# ════════════════════════════════════════════════════════════
do_system_update() {
    log_step "Cập nhật hệ thống"
    sudo $APT update $APT_OPTS
    sudo $APT upgrade $APT_OPTS
    sudo $APT dist-upgrade $APT_OPTS
    sudo $APT autoremove $APT_OPTS
    log_ok "Hệ thống đã cập nhật"
}

do_flathub() {
    log_step "Kích hoạt Flathub"
    ensure_flathub
    log_ok "Flathub đã sẵn sàng"
}

# ════════════════════════════════════════════════════════════
#  MODULE: ỨNG DỤNG
# ════════════════════════════════════════════════════════════
do_brave() {
    log_step "Cài Brave Browser"
    sudo $APT install $APT_OPTS curl
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg         https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources         https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
    sudo $APT update $APT_OPTS
    sudo $APT install $APT_OPTS brave-browser
    log_ok "Brave Browser đã cài xong"
}

do_chrome() {
    log_step "Cài Google Chrome"
    local tmp; tmp=$(mktemp -d)
    wget -q --show-progress -O "${tmp}/chrome.deb" \
        https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo $APT install $APT_OPTS "${tmp}/chrome.deb"
    rm -rf "${tmp}"
    log_ok "Google Chrome đã cài xong"
}

do_vlc() {
    log_step "Cài VLC"
    sudo $APT install $APT_OPTS vlc
    log_ok "VLC đã cài xong"
}

do_zoom() {
    log_step "Cài Zoom"
    local tmp; tmp=$(mktemp -d)
    wget -q --show-progress -O "${tmp}/zoom.deb" \
        https://zoom.us/client/latest/zoom_amd64.deb
    sudo $APT install $APT_OPTS "${tmp}/zoom.deb"
    rm -rf "${tmp}"
    log_ok "Zoom đã cài xong"
}

do_discord() {
    log_step "Cài Discord"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub com.discordapp.Discord
    log_ok "Discord đã cài xong"
}

do_bluerecorder() {
    log_step "Cài Blue Recorder"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub sa.sy.bluerecorder
    log_ok "Blue Recorder đã cài xong"
}

do_obs() {
    log_step "Cài OBS Studio"
    # Dùng Flatpak để đảm bảo version mới nhất trên mọi distro
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub com.obsproject.Studio
    log_ok "OBS Studio đã cài xong"
}

do_fcitx5() {
    log_step "Cài Fcitx5 + Unikey (gõ tiếng Việt)"
    sudo $APT install $APT_OPTS \
        fcitx5 \
        fcitx5-config-qt \
        fcitx5-unikey \
        fcitx5-frontend-gtk3 \
        fcitx5-frontend-gtk4 \
        fcitx5-frontend-qt5

    mkdir -p "${HOME}/.config/environment.d"
    cat > "${HOME}/.config/environment.d/fcitx5.conf" << 'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
EOF

    mkdir -p "${HOME}/.config/autostart"
    local src="/usr/share/applications/org.fcitx.Fcitx5.desktop"
    [[ -f "$src" ]] && cp "$src" "${HOME}/.config/autostart/" \
        && log_ok "Autostart: ~/.config/autostart/org.fcitx.Fcitx5.desktop"

    log_ok "Fcitx5 + Unikey đã cài xong"
    log_warn "Đăng xuất rồi đăng nhập lại để Fcitx5 tự khởi động"
}

do_dev_tools() {
    log_step "Cài Git + Fastfetch + build-essential"
    sudo $APT install $APT_OPTS git build-essential curl

    # Fastfetch không có trong apt mặc định — dùng .deb release
    local tmp; tmp=$(mktemp -d)
    local ff_url
    ff_url=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
        | grep "browser_download_url.*linux-amd64.deb" \
        | cut -d '"' -f 4 | head -1)
    if [[ -n "$ff_url" ]]; then
        wget -q --show-progress -O "${tmp}/fastfetch.deb" "$ff_url"
        sudo $APT install $APT_OPTS "${tmp}/fastfetch.deb"
        log_ok "Fastfetch đã cài xong"
    else
        log_warn "Không tải được Fastfetch — bỏ qua"
    fi
    rm -rf "${tmp}"
    log_ok "Git + Dev tools đã cài xong"
}

do_onlyoffice() {
    log_step "Cài OnlyOffice Desktop Editors"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub org.onlyoffice.desktopeditors
    log_ok "OnlyOffice đã cài xong"
}

do_wps() {
    log_step "Cài WPS Office"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub com.wps.Office
    log_ok "WPS Office đã cài xong"
}

do_libreoffice() {
    log_step "Cài LibreOffice"
    sudo $APT install $APT_OPTS libreoffice libreoffice-l10n-vi
    log_ok "LibreOffice đã cài xong"
}

do_vscode() {
    log_step "Cài Visual Studio Code"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    sudo $APT update $APT_OPTS
    sudo $APT install $APT_OPTS code
    log_ok "VS Code đã cài xong"
}

do_tlauncher() {
    log_step "Cài TLauncher Minecraft"
    echo -e "  ${YELLOW}⚠ TLauncher yêu cầu đúng Java 17 — Java 18+ sẽ bị lỗi!${RESET}"

    sudo $APT install $APT_OPTS curl zip unzip

    if [[ ! -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]]; then
        log_step "  Cài SDKMAN"
        curl -s "https://get.sdkman.io" | bash
    else
        log_ok "SDKMAN đã có sẵn"
    fi

    export SDKMAN_DIR="${HOME}/.sdkman"
    # shellcheck source=/dev/null
    source "${HOME}/.sdkman/bin/sdkman-init.sh"

    local JAVA_VER="17.0.12-tem"
    log_step "  Cài Java ${JAVA_VER} (bắt buộc)"
    if ! sdk list java 2>/dev/null | grep -q "${JAVA_VER}.*installed"; then
        sdk install java "${JAVA_VER}" </dev/null
    else
        log_ok "Java ${JAVA_VER} đã có sẵn"
    fi
    sdk default java "${JAVA_VER}" </dev/null

    local active_ver major_ver
    active_ver=$(java -version 2>&1 | grep -oP '(?<=version ")[^"]+')
    major_ver=$(echo "$active_ver" | cut -d'.' -f1)
    if   [[ "$major_ver" -gt 17 ]]; then
        log_warn "Java ${active_ver} > 17 — TLauncher có thể lỗi!"
    elif [[ "$major_ver" -lt 17 ]]; then
        log_warn "Java ${active_ver} < 17"
    else
        log_ok "Java ${active_ver} — đúng phiên bản ✓"
    fi

    log_step "  Tải TLauncher.jar"
    mkdir -p "${HOME}/TLauncher.v17"
    local jar="${HOME}/TLauncher.v17/TLauncher.jar"
    if [[ ! -f "$jar" ]]; then
        wget -q --show-progress \
            "https://drive.google.com/uc?export=download&id=1BvI0WmzZbzOjp4b3VPp9KsnRCjZhXVJb" \
            -O "$jar"
        log_ok "Đã tải: ${jar}"
    else
        log_ok "TLauncher.jar đã có sẵn"
    fi

    # Wrapper đảm bảo LUÔN dùng Java 17
    local wrapper="${HOME}/TLauncher.v17/tlauncher.sh"
    cat > "$wrapper" << 'WRAPEOF'
#!/usr/bin/env bash
export SDKMAN_DIR="$HOME/.sdkman"
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk use java 17.0.12-tem > /dev/null 2>&1
exec java -jar "$HOME/TLauncher.v17/TLauncher.jar" "$@"
WRAPEOF
    chmod +x "$wrapper"

    mkdir -p "${HOME}/.local/share/applications"
    cat > "${HOME}/.local/share/applications/tlauncher.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=TLauncher
Comment=Minecraft Launcher — Java 17.0.12 Temurin
Exec=${HOME}/TLauncher.v17/tlauncher.sh
Icon=minecraft
Terminal=false
Categories=Game;
StartupNotify=true
EOF
    chmod +x "${HOME}/.local/share/applications/tlauncher.desktop"
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true

    log_ok "TLauncher đã cài xong!"
    log_warn "Chỉ dùng Java 17 — wrapper script tự đảm bảo"
}

# ════════════════════════════════════════════════════════════
#  MODULE: MACTAHOE THEME
# ════════════════════════════════════════════════════════════
open_demo_images() {
    [[ -z "$DISPLAY$WAYLAND_DISPLAY" ]] && return 1
    local viewer=""
    # Tìm image viewer phù hợp với distro
    for v in eog loupe eom shotwell feh xdg-open; do
        command -v "$v" &>/dev/null && viewer="$v" && break
    done
    [[ -z "$viewer" ]] && return 1

    local opened=0
    for i in 1 2 3 4; do
        for ext in png jpg jpeg webp; do
            local f="${THEME_DIR}/demo${i}.${ext}"
            if [[ -f "$f" ]]; then
                "$viewer" "$f" &>/dev/null & disown
                (( opened++ )); break
            fi
        done
    done
    [[ $opened -gt 0 ]]
}

open_guide() {
    local docx="${THEME_DIR}/Setup-Mac-themes.docx"
    local url="https://docs.google.com/document/d/18JCycVsugTkMA7JXGYiuwgSTse80--oI/edit?usp=sharing&ouid=113234984388764662222&rtpof=true&sd=true"
    [[ -z "$DISPLAY$WAYLAND_DISPLAY" ]] && \
        echo -e "  ${GRAY}Link hướng dẫn: ${WHITE}${url}${RESET}" && return

    if [[ -f "$docx" ]] && command -v libreoffice &>/dev/null; then
        echo -e "  ${CYAN}📄 Mở hướng dẫn offline (LibreOffice Writer)...${RESET}"
        libreoffice --writer "$docx" &>/dev/null & disown
        log_ok "Đã mở: Setup-Mac-themes.docx"
    else
        log_warn "Không tìm thấy ${docx} hoặc LibreOffice chưa cài"
    fi

    local browser=""
    for b in xdg-open google-chrome brave-browser firefox chromium-browser; do
        command -v "$b" &>/dev/null && browser="$b" && break
    done
    if [[ -n "$browser" ]]; then
        echo -e "  ${CYAN}🌐 Mở hướng dẫn online (Google Docs)...${RESET}"
        "$browser" "$url" &>/dev/null & disown
        log_ok "Đã mở link hướng dẫn online"
    else
        echo -e "  ${GRAY}Link hướng dẫn: ${WHITE}${url}${RESET}"
    fi
}

create_mactahoe_scripts() {
    local mac_dir="${HOME}/AIO-MacTahoe-Themes"
    mkdir -p "${mac_dir}"
    cat > "${mac_dir}/SCRIPTS.sh" << 'SCRIPTEOF'
#!/usr/bin/env bash
# MacTahoe Theme Installer — Standalone (Debian/Ubuntu)
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; GRAY='\033[0;90m'
BOLD='\033[1m'; RESET='\033[0m'

export DEBIAN_FRONTEND=noninteractive
clear
echo -e "${CYAN}"
echo "  ███╗   ███╗ █████╗  ██████╗████████╗ █████╗ ██╗  ██╗ ██████╗ ███████╗"
echo "  ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██║  ██║██╔═══██╗██╔════╝"
echo "  ██╔████╔██║███████║██║        ██║   ███████║███████║██║   ██║█████╗  "
echo "  ██║╚██╔╝██║██╔══██║██║        ██║   ██╔══██║██╔══██║██║   ██║██╔══╝  "
echo "  ██║ ╚═╝ ██║██║  ██║╚██████╗   ██║   ██║  ██║██║  ██║╚██████╔╝███████╗"
echo "  ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${RESET}"
set -e
log_step() { echo -e "\n  ${CYAN}${BOLD}▶ ${1}${RESET}"; }
log_ok()   { echo -e "  ${GREEN}✓ ${1}${RESET}"; }

log_step "Cài dependencies"
# Gói đúng cho Debian/Ubuntu/Mint/CaramOS
sudo apt install -y --no-install-recommends \
    gcc make cmake curl wget git \
    sassc wmctrl gnome-tweaks \
    libgtk-4-dev libadwaita-1-dev \
    libglib2.0-dev-bin glib-compile-schemas \
    inkscape optipng

BUILD="${HOME}/.local/share/aio-mactahoe-build"
mkdir -p "$BUILD"; cd "$BUILD"

log_step "Icon Theme"
[[ -d MacTahoe-icon-theme ]] && git -C MacTahoe-icon-theme pull --ff-only \
    || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git
cd MacTahoe-icon-theme && ./install.sh -b && cd "$BUILD"

log_step "GTK Theme"
[[ -d MacTahoe-gtk-theme ]] && git -C MacTahoe-gtk-theme pull --ff-only \
    || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git
cd MacTahoe-gtk-theme
./install.sh -n macTahoe -t all -l --shell -i simple -h bigger --round
sudo ./tweaks.sh -g -nd
sudo flatpak override --filesystem=xdg-config/gtk-3.0
sudo flatpak override --filesystem=xdg-config/gtk-4.0

log_step "Wallpapers"
cd wallpaper && sudo ./install-gnome-backgrounds.sh && cd "$BUILD"

log_ok "MacTahoe Theme đã cài xong!"
read -rp "  Reboot ngay? [y/N]: " rb
[[ "$rb" =~ ^[Yy]$ ]] && sudo systemctl reboot || echo -e "  ${GRAY}Nhớ reboot sau!${RESET}"
SCRIPTEOF
    chmod +x "${mac_dir}/SCRIPTS.sh"
    log_ok "Đã tạo: ${mac_dir}/SCRIPTS.sh"
}

do_mactahoe() {
    create_mactahoe_scripts

    if ! command -v libreoffice &>/dev/null; then
        log_warn "LibreOffice chưa có — đang cài để mở file hướng dẫn..."
        sudo $APT install $APT_OPTS libreoffice libreoffice-l10n-vi
        log_ok "LibreOffice đã cài xong"
    fi

    log_step "Cài MacTahoe Theme"
    # Gói dependencies đúng cho Debian/Ubuntu/Mint
    sudo $APT install $APT_OPTS \
        gcc make cmake curl wget git \
        sassc wmctrl gnome-tweaks \
        libgtk-4-dev libadwaita-1-dev \
        libglib2.0-dev-bin glib-compile-schemas \
        inkscape optipng

    local BUILD="${HOME}/.local/share/aio-mactahoe-build"
    mkdir -p "$BUILD"; cd "$BUILD"

    log_step "  Icon Theme"
    [[ -d MacTahoe-icon-theme ]] && git -C MacTahoe-icon-theme pull --ff-only \
        || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-icon-theme.git
    cd MacTahoe-icon-theme && ./install.sh -b && cd "$BUILD"

    log_step "  GTK Theme"
    [[ -d MacTahoe-gtk-theme ]] && git -C MacTahoe-gtk-theme pull --ff-only \
        || git clone --depth=1 https://github.com/vinceliuice/MacTahoe-gtk-theme.git
    cd MacTahoe-gtk-theme
    ./install.sh -n macTahoe -t all -l --shell -i simple -h bigger --round
    sudo ./tweaks.sh -g -nd
    ensure_flathub
    sudo flatpak override --filesystem=xdg-config/gtk-3.0
    sudo flatpak override --filesystem=xdg-config/gtk-4.0

    log_step "  Wallpapers"
    cd wallpaper && sudo ./install-gnome-backgrounds.sh && cd "$BUILD"

    log_ok "MacTahoe Theme đã cài xong!"
    echo ""
    log_div
    echo -e "  ${WHITE}${BOLD}📁 ~/AIO-MacTahoe-Themes/SCRIPTS.sh${RESET}"
    echo -e "  ${GRAY}     Chạy lại để cài theme bất cứ lúc nào${RESET}"
    echo ""
    echo -e "  ${YELLOW}${BOLD}Bước tiếp theo:${RESET}"
    echo -e "  ${GRAY}  GNOME Tweaks → Appearance → Shell: macTahoe | Icons: MacTahoe${RESET}"
    log_div
    echo ""
    open_guide
}

prompt_mactahoe_gnome() {
    echo ""
    log_div
    echo -e "  ${CYAN}${BOLD}🍎 Phát hiện GNOME — Bạn có muốn cài giao diện macOS Tahoe không?${RESET}"
    echo ""

    if [[ -d "$THEME_DIR" ]]; then
        echo -e "  ${GREEN}🖼  Đang mở ảnh demo (demo1~4)...${RESET}"
        if open_demo_images; then
            echo -e "  ${GRAY}  Xem xong quay lại terminal để chọn.${RESET}"
        else
            echo -e "  ${YELLOW}  Không mở được image viewer. Xem tại: ${WHITE}${THEME_DIR}${RESET}"
        fi
    else
        echo -e "  ${YELLOW}  Không tìm thấy thư mục Mac-Theme-Install.${RESET}"
        echo -e "  ${GRAY}  Cần có: ${WHITE}${THEME_DIR}${RESET}"
    fi

    echo ""
    log_div
    echo ""
    echo -ne "  ${BOLD}Cài giao diện macOS Tahoe? [y/N]: ${RESET}"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] && do_mactahoe \
        || echo -e "  ${GRAY}Bỏ qua. Chạy lại script bất cứ lúc nào để cài.${RESET}"
}

# ════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════
main() {
    show_banner

    [[ $EUID -eq 0 ]] && \
        echo -e "  ${RED}✗ Đừng chạy bằng root! Dùng user thường.${RESET}" && exit 1

    # ── Kiểm tra Debian-based ────────────────────────────────
    local DISTRO_ID DISTRO_NAME
    DISTRO_ID=$(detect_distro)
    DISTRO_NAME=$(get_distro_name)
    DISTRO_VER=$(get_distro_version)

    if [[ "$DISTRO_ID" == "unknown" ]]; then
        echo ""
        echo -e "  ${RED}${BOLD}✗ Không phát hiện distro Debian-based!${RESET}"
        echo ""
        echo -e "  ${GRAY}  Script hỗ trợ:${RESET}"
        echo -e "  ${GRAY}   🟠 Ubuntu        🌀 Debian        🍃 Linux Mint${RESET}"
        echo -e "  ${GRAY}   🐉 Kali Linux    🚀 Pop!_OS       💠 Zorin OS${RESET}"
        echo -e "  ${GRAY}   🔵 Elementary    ⚙️  MX Linux       🦜 Parrot OS${RESET}"
        echo -e "  ${GRAY}   🎨 Deepin        🍓 Raspbian       🌟 CaramOS${RESET}"
        echo ""
        echo -ne "  ${YELLOW}⚠ Tiếp tục dù vậy? (có thể lỗi) [y/N]: ${RESET}"
        read -r force
        [[ ! "$force" =~ ^[Yy]$ ]] && exit 1
        DISTRO_ID="unknown"
    else
        print_distro_banner "$DISTRO_ID" "$DISTRO_NAME" "$DISTRO_VER"
    fi

    # ── Detect Desktop Environment ───────────────────────────
    local CURRENT_DE
    CURRENT_DE=$(detect_desktop_env)
    echo -e "  ${CYAN}▶ Desktop Environment : ${WHITE}${BOLD}${CURRENT_DE}${RESET}"
    echo ""

    # ── Kiểm tra dependencies ────────────────────────────────
    check_dependencies
    echo ""

    if [[ "$CURRENT_DE" != "gnome" ]]; then
        echo -e "  ${YELLOW}⚠ Không phát hiện GNOME (đang dùng: ${CURRENT_DE})${RESET}"
        echo ""
    fi

    # ════════════════════════════════════════════════════════
    #  BƯỚC 1 — THIẾT LẬP CƠ BẢN
    # ════════════════════════════════════════════════════════
    local base_names=("System Upgrade" "Flathub")
    local base_descs=(
        "apt update + upgrade + dist-upgrade + autoremove"
        "Thêm kho Flathub để cài app Flatpak (tự cài flatpak nếu thiếu)"
    )
    local base_sel=("1" "1")
    local base_dis=("0" "0")

    show_banner
    tput cup 7 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 1/4 — Thiết lập cơ bản${RESET}"
    echo ""
    checkbox_menu "Chọn:" base_names base_descs base_sel base_dis

    # ════════════════════════════════════════════════════════
    #  BƯỚC 2 — ỨNG DỤNG
    # ════════════════════════════════════════════════════════
    local app_names=(
        "Brave Browser"
        "Google Chrome"
        "VLC"
        "Zoom"
        "Discord"
        "Blue Recorder"
        "OBS Studio"
        "Fcitx5 + Unikey  (Gõ tiếng Việt)"
        "Git + Fastfetch + build-essential"
        "LibreOffice"
        "OnlyOffice"
        "WPS Office"
        "VS Code"
        "TLauncher Minecraft"
    )
    local app_descs=(
        "Trình duyệt bảo mật, chặn quảng cáo — apt repo chính thức"
        "Trình duyệt Google Chrome — tải .deb từ Google"
        "Xem phim đa năng — apt"
        "Họp online — tải .deb từ zoom.us"
        "Chat gaming — Flatpak (tự enable Flathub)"
        "Quay màn hình đơn giản — Flatpak (tự enable Flathub)"
        "Quay màn hình chuyên nghiệp — Flatpak (tự enable Flathub)"
        "Bộ gõ Unikey, hỗ trợ GTK4/Qt/Wayland/X11"
        "Quản lý source code + thông tin hệ thống + công cụ build"
        "Bộ Office đầy đủ, hỗ trợ tiếng Việt — apt"
        "Bộ Office miễn phí .docx/.xlsx/.pptx — Flatpak (tự enable Flathub)"
        "Bộ Office nhẹ tương thích MS Office — Flatpak (tự enable Flathub)"
        "Editor mạnh mẽ cho lập trình — apt repo Microsoft"
        "SDKMAN + Java 17.0.12 Temurin (bắt buộc) + TLauncher.jar"
    )
    local app_sel=("0" "0" "0" "0" "0" "0" "0" "0" "1" "0" "0" "0" "0" "0")
    local app_dis=("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")

    show_banner
    tput cup 7 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 2/4 — Chọn ứng dụng${RESET}"
    echo ""
    checkbox_menu "Chọn:" app_names app_descs app_sel app_dis

    # ════════════════════════════════════════════════════════
    #  BƯỚC 3 — XÁC NHẬN
    # ════════════════════════════════════════════════════════
    show_banner
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 3/4 — Xác nhận${RESET}"
    echo ""
    echo -e "  ${BOLD}${WHITE}Danh sách sẽ cài trên ${DISTRO_NAME}:${RESET}"
    echo ""

    local any=0
    [[ "${base_sel[0]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} System Upgrade"                      && any=1
    [[ "${base_sel[1]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Flathub"                             && any=1
    [[ "${app_sel[0]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Brave Browser"                       && any=1
    [[ "${app_sel[1]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Google Chrome"                       && any=1
    [[ "${app_sel[2]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} VLC"                                 && any=1
    [[ "${app_sel[3]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Zoom"                                && any=1
    [[ "${app_sel[4]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Discord (Flatpak)"                   && any=1
    [[ "${app_sel[5]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Blue Recorder (Flatpak)"             && any=1
    [[ "${app_sel[6]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} OBS Studio (Flatpak)"                && any=1
    [[ "${app_sel[7]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Fcitx5 + Unikey"                     && any=1
    [[ "${app_sel[8]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Git + Fastfetch + build-essential"   && any=1
    [[ "${app_sel[9]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} LibreOffice"                         && any=1
    [[ "${app_sel[10]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} OnlyOffice (Flatpak)"                && any=1
    [[ "${app_sel[11]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} WPS Office (Flatpak)"                && any=1
    [[ "${app_sel[12]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} VS Code"                             && any=1
    [[ "${app_sel[13]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} TLauncher Minecraft (Java 17)"       && any=1

    echo ""
    echo -e "  ${DIM}${GRAY}(Giao diện macOS Tahoe sẽ được hỏi sau nếu đang dùng GNOME)${RESET}"
    echo ""

    if [[ $any -eq 0 ]]; then
        echo -e "  ${YELLOW}⚠ Chưa chọn gì cả. Thoát.${RESET}"; exit 0
    fi

    echo -ne "  ${BOLD}Xác nhận bắt đầu cài? [Y/n]: ${RESET}"
    read -r confirm
    [[ "$confirm" =~ ^[Nn]$ ]] && echo -e "\n  ${GRAY}Đã huỷ.${RESET}\n" && exit 0

    # ════════════════════════════════════════════════════════
    #  BƯỚC 4 — CÀI ĐẶT
    # ════════════════════════════════════════════════════════
    echo ""
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 4/4 — Đang cài đặt...${RESET}"
    log_div
    set -e

    [[ "${base_sel[0]}" == "1" ]] && do_system_update
    [[ "${base_sel[1]}" == "1" ]] && do_flathub

    [[ "${app_sel[0]}"  == "1" ]] && do_brave
    [[ "${app_sel[1]}"  == "1" ]] && do_chrome
    [[ "${app_sel[2]}"  == "1" ]] && do_vlc
    [[ "${app_sel[3]}"  == "1" ]] && do_zoom
    [[ "${app_sel[4]}"  == "1" ]] && do_discord
    [[ "${app_sel[5]}"  == "1" ]] && do_bluerecorder
    [[ "${app_sel[6]}"  == "1" ]] && do_obs
    [[ "${app_sel[7]}"  == "1" ]] && do_fcitx5
    [[ "${app_sel[8]}"  == "1" ]] && do_dev_tools
    [[ "${app_sel[9]}"  == "1" ]] && do_libreoffice
    [[ "${app_sel[10]}" == "1" ]] && do_onlyoffice
    [[ "${app_sel[11]}" == "1" ]] && do_wps
    [[ "${app_sel[12]}" == "1" ]] && do_vscode
    [[ "${app_sel[13]}" == "1" ]] && do_tlauncher

    # Dọn dẹp cuối
    log_step "Dọn dẹp"
    sudo $APT autoremove $APT_OPTS
    sudo $APT autoclean $APT_OPTS
    log_ok "Hoàn tất"

    echo ""
    log_div
    echo -e "  ${GREEN}${BOLD}🎉 Setup xong ${DISTRO_NAME}! Chúc bạn vọc vui vẻ 🇻🇳${RESET}"

    # Auto-detect GNOME → đề xuất MacTahoe
    set +e
    [[ "$CURRENT_DE" == "gnome" ]] && prompt_mactahoe_gnome \
        || echo -e "  ${GRAY}  (Không phải GNOME — bỏ qua đề xuất MacTahoe)${RESET}"
    set -e

    echo ""
    log_div
    echo ""
    echo -ne "  ${BOLD}Reboot ngay? [y/N]: ${RESET}"
    read -r rb
    if [[ "$rb" =~ ^[Yy]$ ]]; then
        echo -e "  ${CYAN}Đang reboot...${RESET}"
        sudo systemctl reboot
    else
        echo -e "  ${GRAY}Nhớ reboot sau để áp dụng toàn bộ thay đổi!${RESET}\n"
    fi
}

main "$@"