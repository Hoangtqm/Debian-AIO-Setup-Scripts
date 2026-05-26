#!/usr/bin/env bash
# ============================================================
#  AIO Debian Based Setup Script
# ============================================================

# -- Colors ---------------------------------------------------
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
cleanup()     { show_cursor; tput cnorm 2>/dev/null || true; echo ""; }
trap cleanup EXIT INT TERM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APT_OPTS="-y"
export DEBIAN_FRONTEND=noninteractive

# ============================================================
#  BANNER
# ============================================================
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
    echo -e "  ${WHITE}${BOLD}AIO APT Based Setup Script${RESET}  ${GRAY}Debian/Ubuntu/Mint và distro dùng APT${RESET}"
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# ============================================================
#  CHECKBOX MENU
#  Phím: UP/DOWN, j/k di chuyển
#        SPACE      toggle
#        A          chọn tất cả (trừ mục bị khóa)
#        N          bỏ hết
#        ENTER      xác nhận
# ============================================================
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
        echo -e "  ${GRAY}[SPACE] Chọn/bỏ  [A] Tất cả  [N] Bỏ hết  [ENTER] Xác nhận  [UP/DOWN/jk] Di chuyển${RESET}"
        echo ""

        local sel_count=0
        for i in "${!_names[@]}"; do
            [[ "${_sel[$i]}" == "1" ]] && (( sel_count++ ))
        done

        for i in "${!_names[@]}"; do
            local box line_color sep

            if [[ "${_dis[$i]}" == "1" ]]; then
                box="${GRAY}[x]${RESET}"
                line_color="${GRAY}${DIM}"
                sep="${GRAY}${DIM}"
            elif [[ "${_sel[$i]}" == "1" ]]; then
                box="${GREEN}[v]${RESET}"
                line_color="${GREEN}"
                sep="${GRAY}${DIM}"
            else
                box="${GRAY}[ ]${RESET}"
                line_color="${GRAY}"
                sep="${GRAY}${DIM}"
            fi

            if [[ $i -eq $cursor ]]; then
                printf '\033[2K'
                echo -e "  ${BG_BLUE}${WHITE}  > ${_names[$i]}  -  ${_descs[$i]}${RESET}   "
            else
                printf '\033[2K'
                echo -e "    ${box} ${line_color}${_names[$i]}${RESET}  ${sep}-  ${_descs[$i]}${RESET}   "
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

# ============================================================
#  LOG HELPERS
# ============================================================
log_step() { echo -e "\n  ${CYAN}${BOLD}> ${1}${RESET}"; }
log_ok()   { echo -e "  ${GREEN}✓ ${1}${RESET}"; }
log_warn() { echo -e "  ${YELLOW}! ${1}${RESET}"; }
log_div()  { echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }

FAILED_ITEMS=()

run_task() {
    local name="$1"
    local func="$2"

    # Hiển thị module đang chạy trên thanh tiêu đề terminal
    echo -e "
  ${MAGENTA}${BOLD}━━━ Đang chạy module: ${WHITE}${name}${MAGENTA} ━━━${RESET}"

    if ( set -e; "$func" ); then
        return 0
    fi

    FAILED_ITEMS+=("$name")
    echo -e "  ${RED}✗ ${name} bị lỗi - sẽ báo lại ở cuối script${RESET}"
    return 0
}

# ============================================================
#  CHECKS & HELPERS
# ============================================================
check_debian_based() {
    if ! command -v apt-get &>/dev/null; then
        echo -e "  ${RED}Không tìm thấy apt-get.${RESET}"
        exit 1
    fi

    local pretty_name="APT based distro"
    if [[ -r /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        pretty_name="${PRETTY_NAME:-$pretty_name}"
    fi

    echo -e "  ${GREEN}✓ ${pretty_name} - APT sẵn sàng${RESET}"
}

check_dependencies() {
    log_step "Kiểm tra phụ thuộc (wget, curl)"
    local missing=()
    command -v wget &>/dev/null || missing+=("wget")
    command -v curl &>/dev/null || missing+=("curl")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Thiếu: ${missing[*]} - đang cài..."
        sudo apt-get update
        sudo apt-get install ${APT_OPTS} "${missing[@]}"
        log_ok "Đã cài: ${missing[*]}"
    else
        log_ok "wget và curl đã có sẵn"
    fi
}

detect_desktop_env() {
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]] || \
       [[ "$DESKTOP_SESSION" == *"gnome"* ]]      || \
       [[ "$GDMSESSION"      == *"gnome"* ]]      || \
       pgrep -x gnome-shell &>/dev/null; then
        echo "gnome"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || pgrep -x plasmashell &>/dev/null; then
        echo "kde"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"XFCE"* ]]; then
        echo "xfce"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"MATE"* ]]; then
        echo "mate"; return
    fi
    if [[ "$XDG_CURRENT_DESKTOP" == *"Cinnamon"* ]]; then
        echo "cinnamon"; return
    fi
    echo "other"
}

apt_install() {
    sudo apt-get install ${APT_OPTS} "$@"
}

package_available() {
    apt-cache show "$1" &>/dev/null
}

install_deb_from_url() {
    local name="$1"
    local url="$2"
    local filename="$3"
    local tmp
    tmp=$(mktemp -d)

    log_step "Tải ${name}"
    if ! wget -q --show-progress -O "${tmp}/${filename}" "$url"; then
        rm -rf "$tmp"
        echo -e "  ${RED}Tải ${name} thất bại: ${url}${RESET}"
        return 1
    fi

    log_step "Cài ${name}"
    sudo apt-get install ${APT_OPTS} "${tmp}/${filename}"
    rm -rf "$tmp"
    log_ok "${name} đã cài xong, file cài đặt tạm đã xóa"
}

ensure_flathub() {
    if ! command -v flatpak &>/dev/null; then
        log_warn "Flatpak chưa có - đang cài..."
        sudo apt-get update
        apt_install flatpak
    fi

    if ! flatpak remotes 2>/dev/null | grep -q "^flathub"; then
        log_warn "Flathub chưa được kích hoạt - đang bật tự động..."
        sudo flatpak remote-add --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
        log_ok "Flathub đã kích hoạt"
    fi
}

ensure_snapd() {
    if ! command -v snap &>/dev/null; then
        log_warn "Snap chưa có - đang cài snapd..."
        sudo apt-get update
        apt_install snapd
    fi

    if command -v systemctl &>/dev/null; then
        sudo systemctl enable --now snapd.socket 2>/dev/null || true
    fi

    if [[ ! -e /snap && -d /var/lib/snapd/snap ]]; then
        sudo ln -s /var/lib/snapd/snap /snap 2>/dev/null || true
    fi
}

# ============================================================
#  MODULE: HỆ THỐNG & KHO
# ============================================================
# Cập nhật toàn bộ danh sách package và nâng cấp tất cả package đã cài.
# Dùng full-upgrade thay vì upgrade để xử lý đúng các thay đổi dependencies.
do_system_update() {
    log_step "Cập nhật hệ thống"
    sudo apt-get update
    sudo apt-get full-upgrade ${APT_OPTS}
    log_ok "Hệ thống đã cập nhật"
}

# Chỉ áp dụng cho Debian thuần (ID=debian).
# Bật thêm kho contrib, non-free, non-free-firmware để cài được
# firmware, codec và driver độc quyền (ví dụ: GPU, WiFi card).
# Ubuntu/Mint/Pop và các distro APT khác giữ nguyên sources.
do_debian_repos() {
    log_step "Kiểm tra kho contrib/non-free cho Debian"

    # Chỉ Debian thuần dùng contrib/non-free theo cách này.
    # Ubuntu/Mint/Pop và các distro APT khác sẽ giữ sources hiện tại.
    if [[ ! -r /etc/os-release ]]; then
        sudo apt-get update
        log_warn "Không đọc được /etc/os-release - giữ nguyên sources hiện tại"
        return 0
    fi

    # shellcheck source=/dev/null
    source /etc/os-release
    if [[ "${ID:-}" != "debian" ]]; then
        sudo apt-get update
        log_ok "Distro ${PRETTY_NAME:-APT based}: giữ nguyên sources hiện tại"
        return 0
    fi

    if ! command -v apt-add-repository &>/dev/null; then
        sudo apt-get update
        apt_install software-properties-common || true
    fi

    if command -v apt-add-repository &>/dev/null; then
        sudo apt-add-repository -y contrib || true
        sudo apt-add-repository -y non-free || true
        sudo apt-add-repository -y non-free-firmware || true
    else
        log_warn "Không có apt-add-repository; hãy kiểm tra sources nếu cần non-free firmware"
    fi
    sudo apt-get update
    log_ok "Đã xử lý kho Debian contrib/non-free nếu được hỗ trợ"
}

# Thêm remote Flathub vào Flatpak.
# Nếu Flatpak chưa được cài, ensure_flathub() sẽ tự cài trước.
do_flathub() {
    log_step "Kích hoạt Flathub"
    ensure_flathub
    log_ok "Flathub sẵn sàng"
}

# Cài snapd và kích hoạt socket để dùng ứng dụng từ Snap Store.
# Tạo symlink /snap nếu chưa có (cần thiết cho một số distro).
do_snap_support() {
    log_step "Kích hoạt Snap"
    ensure_snapd
    log_ok "Snap sẵn sàng"
}

# ============================================================
#  MODULE: ỨNG DỤNG
# ============================================================
# Cài Brave Browser qua APT repo chính thức của Brave.
# Thêm GPG key và file .sources (DEB822 format) vào sources.list.d.
# Không dùng PPA hay file .list cũ — đây là cách Brave khuyến nghị.
do_brave() {
    log_step "Cài Brave Browser"
    apt_install curl gnupg
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
        https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
    sudo apt-get update
    apt_install brave-browser
    log_ok "Brave Browser đã cài xong"
}

# Tải file .deb Google Chrome trực tiếp từ dl.google.com.
# Cài bằng apt-get để tự xử lý dependency.
# Chrome sẽ tự thêm repo Google vào sources sau khi cài xong.
do_chrome() {
    install_deb_from_url \
        "Google Chrome" \
        "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
        "google-chrome-stable_current_amd64.deb"
}

# Cài VLC, FFmpeg và các codec cần thiết.
# Tự detect và cài thêm libavcodec-extra, ubuntu-restricted-extras
# nếu package đó có sẵn trên distro đang dùng.
# Tự động chấp nhận EULA của ttf-mscorefonts nếu được hỏi.
do_vlc_ffmpeg() {
    log_step "Cài VLC + FFmpeg + codec"
    sudo apt-get update
    local packages=(ffmpeg vlc)

    if package_available libavcodec-extra; then
        packages+=(libavcodec-extra)
    fi

    if package_available ubuntu-restricted-extras; then
        packages+=(ubuntu-restricted-extras)
        if command -v debconf-set-selections &>/dev/null; then
            echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | \
                sudo debconf-set-selections || true
        fi
    else
        log_warn "ubuntu-restricted-extras không có trên distro này - bỏ qua"
    fi

    apt_install "${packages[@]}"
    log_ok "VLC + FFmpeg + codec đã cài xong"
}

# Tải file .deb Zoom mới nhất từ zoom.us.
# Cài bằng apt-get để tự xử lý dependency (libxcb, libglib...).
do_zoom() {
    install_deb_from_url \
        "Zoom" \
        "https://zoom.us/client/latest/zoom_amd64.deb" \
        "zoom_amd64.deb"
}

# Tải file .deb Discord mới nhất từ server Discord.
# Cài bằng apt-get để tự xử lý dependency.
do_discord() {
    install_deb_from_url \
        "Discord" \
        "https://discord.com/api/download?platform=linux&format=deb" \
        "discord.deb"
}

# Cài Blue Recorder qua Flatpak từ Flathub.
# Tự động bật Flathub nếu chưa có.
do_bluerecorder() {
    log_step "Cài Blue Recorder"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub sa.sy.bluerecorder
    log_ok "Blue Recorder đã cài xong"
}

# Cài Fcitx5 và plugin Unikey để gõ tiếng Việt.
# Tự detect và cài thêm fcitx5-frontend-gtk4, fcitx5-frontend-qt5
# nếu package có sẵn trên distro đang dùng.
# Cấu hình autostart qua .desktop file chính thức của Fcitx5.
# Ghi biến môi trường vào ~/.xprofile (X11) và ~/.config/environment.d (Wayland).
do_fcitx5() {
    log_step "Cài Fcitx5 + Unikey"
    sudo apt-get update
    apt_install fcitx5 fcitx5-unikey fcitx5-configtool fcitx5-gtk

    if package_available fcitx5-frontend-gtk4; then
        apt_install fcitx5-frontend-gtk4
    fi
    if package_available fcitx5-frontend-qt5; then
        apt_install fcitx5-frontend-qt5
    fi

    mkdir -p "${HOME}/.config/autostart"
    local src="/usr/share/applications/org.fcitx.Fcitx5.desktop"
    [[ -f "$src" ]] && cp "$src" "${HOME}/.config/autostart/" \
        && log_ok "Autostart: ~/.config/autostart/org.fcitx.Fcitx5.desktop"

    touch "${HOME}/.xprofile"
    if ! grep -q "GTK_IM_MODULE=fcitx" "${HOME}/.xprofile"; then
        cat >> "${HOME}/.xprofile" << 'EOF'

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export INPUT_METHOD=fcitx
EOF
    fi

    mkdir -p "${HOME}/.config/environment.d"
    cat > "${HOME}/.config/environment.d/fcitx5.conf" << 'EOF'
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
INPUT_METHOD=fcitx
EOF

    log_ok "Fcitx5 + Unikey đã cài xong"
    log_warn "Đăng xuất rồi đăng nhập lại để Fcitx5 tự khởi động"
}

# Cài Git và Fastfetch.
# Fastfetch được tải file .deb từ GitHub Releases — tự detect kiến trúc CPU:
# amd64, arm64, armhf, armel, i386, ppc64el, riscv64, s390x.
# Nếu không tìm được file .deb phù hợp thì thử cài từ APT repo.
do_dev_tools() {
    log_step "Cài Git + Fastfetch"
    sudo apt-get update
    apt_install git

    local arch fastfetch_deb
    arch="$(dpkg --print-architecture 2>/dev/null || uname -m)"
    case "$arch" in
        amd64|x86_64) fastfetch_deb="fastfetch-linux-amd64.deb" ;;
        arm64|aarch64) fastfetch_deb="fastfetch-linux-aarch64.deb" ;;
        armhf|armv7l) fastfetch_deb="fastfetch-linux-armv7l.deb" ;;
        armel|armv6l) fastfetch_deb="fastfetch-linux-armv6l.deb" ;;
        i386|i686) fastfetch_deb="fastfetch-linux-i686.deb" ;;
        ppc64el|ppc64le) fastfetch_deb="fastfetch-linux-ppc64le.deb" ;;
        riscv64) fastfetch_deb="fastfetch-linux-riscv64.deb" ;;
        s390x) fastfetch_deb="fastfetch-linux-s390x.deb" ;;
        *) fastfetch_deb="" ;;
    esac

    if [[ -n "$fastfetch_deb" ]]; then
        install_deb_from_url \
            "Fastfetch" \
            "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/${fastfetch_deb}" \
            "$fastfetch_deb"
    elif package_available fastfetch; then
        log_warn "Không tìm thấy file .deb Fastfetch cho kiến trúc ${arch}; thử cài từ APT"
        apt_install fastfetch
    else
        log_warn "Bỏ qua Fastfetch: chưa hỗ trợ kiến trúc ${arch} và repo APT không có gói fastfetch"
    fi

    log_ok "Git + Fastfetch đã cài xong"
}

# Cài OnlyOffice Desktop Editors qua Flatpak từ Flathub.
# Tương thích cao với .docx, .xlsx, .pptx của Microsoft Office.
do_onlyoffice() {
    log_step "Cài OnlyOffice Desktop Editors"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub org.onlyoffice.desktopeditors
    log_ok "OnlyOffice đã cài xong"
}

# Tải file .deb WPS Office trực tiếp từ CDN của WPS.
# Giao diện tương tự MS Office, hỗ trợ tiếng Việt tốt.
do_wps() {
    install_deb_from_url \
        "WPS Office" \
        "https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/download/linux/11723/wps-office_11.1.0.11723.XA_amd64.deb" \
        "wps-office_11.1.0.11723.XA_amd64.deb"
}

# Cài Spotify qua Flatpak từ Flathub.
# Flatpak đảm bảo Spotify hoạt động trên mọi distro Debian-based.
do_spotify() {
    log_step "Cài Spotify"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub com.spotify.Client
    log_ok "Spotify đã cài xong"
}

# Tải file .deb VS Code (Stable) mới nhất từ Microsoft.
# Dùng link download ổn định, không phụ thuộc version cụ thể.
do_vscode() {
    install_deb_from_url \
        "Visual Studio Code" \
        "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" \
        "code-stable_amd64.deb"
}

# Cài OBS Studio qua Flatpak từ Flathub.
# Flatpak đảm bảo luôn có phiên bản OBS mới nhất trên mọi distro.
# Hỗ trợ quay màn hình, livestream, virtual camera.
do_obs() {
    log_step "Cài OBS Studio"
    ensure_flathub
    flatpak install --assumeyes --noninteractive flathub com.obsproject.Studio
    log_ok "OBS Studio đã cài xong"
}

# Cài OpenJDK 17 (bắt buộc — Java 18+ sẽ lỗi) rồi cài TLauncher.
# TLauncher được tải dưới dạng .deb installer từ tlauncher.org.
# Installer tự tạo shortcut trong App Menu và cấu hình Java path.
do_tlauncher() {
    log_step "Cài TLauncher Minecraft"
    log_warn "Sẽ cài OpenJDK 17 để TLauncher có môi trường Java phù hợp"
    sudo apt-get update
    apt_install openjdk-17-jre
    install_deb_from_url \
        "TLauncher Minecraft" \
        "https://dl1.tlauncher.org/f.php?f=files%2Ftlauncher-linux-installer.deb" \
        "tlauncher-linux-installer.deb"
}

do_final_update() {
    log_step "Cập nhật lần cuối"
    sudo apt-get update
    sudo apt-get upgrade ${APT_OPTS}
    log_ok "Hoàn tất"
}

# ============================================================
#  MAIN
# ============================================================
main() {
    show_banner

    [[ $EUID -eq 0 ]] && \
        echo -e "  ${RED}Đừng chạy bằng root. Hãy dùng user thường có sudo.${RESET}" && exit 1

    check_debian_based
    echo ""

    local CURRENT_DE
    CURRENT_DE=$(detect_desktop_env)
    echo -e "  ${CYAN}> Môi trường desktop: ${WHITE}${BOLD}${CURRENT_DE}${RESET}"
    echo ""

    check_dependencies
    echo ""

    # ========================================================
    #  BƯỚC 1 - THIẾT LẬP CƠ BẢN
    # ========================================================
    local base_names=("Cập nhật hệ thống" "Debian contrib/non-free" "Flathub" "Hỗ trợ Snap")
    local base_descs=(
        "apt full-upgrade - cập nhật toàn bộ hệ thống"
        "Bật contrib/non-free/non-free-firmware nếu là Debian thuần"
        "Thêm kho Flathub để cài app Flatpak"
        "Cài snapd nếu bạn cần hỗ trợ ứng dụng Snap"
    )
    local base_sel=("1" "1" "1" "0")
    local base_dis=("0" "0" "0" "0")

    show_banner
    tput cup 7 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 1/4 - Thiết lập cơ bản${RESET}"
    echo ""
    checkbox_menu "Chọn:" base_names base_descs base_sel base_dis

    # ========================================================
    #  BƯỚC 2 - ỨNG DỤNG
    # ========================================================
    local app_names=(
        "Brave Browser"
        "Google Chrome"
        "VLC + FFmpeg"
        "Zoom"
        "Discord"
        "Blue Recorder"
        "Fcitx5 + Unikey"
        "Git + Fastfetch"
        "OnlyOffice"
        "WPS Office"
        "Spotify"
        "VS Code"
        "OBS Studio"
        "TLauncher Minecraft"
    )
    local app_descs=(
        "Trình duyệt bảo mật, cài qua Brave APT repo"
        "Trình duyệt Google Chrome, tải file DEB"
        "Xem phim + encode video + codec qua APT"
        "Họp online, tải file DEB từ zoom.us"
        "Chat gaming, tải file DEB mới nhất từ Discord"
        "Quay màn hình đơn giản, Flatpak"
        "Bộ gõ Unikey, hỗ trợ GTK/Qt/Wayland/X11"
        "Quản lý source code + hiển thị thông tin hệ thống"
        "Bộ Office miễn phí, cài qua Flatpak"
        "Bộ Office nhẹ tương thích MS Office, tải file DEB"
        "Nghe nhạc trực tuyến, Flatpak"
        "Editor mạnh cho lập trình, tải file DEB từ Microsoft"
        "Quay màn hình/stream chuyên nghiệp, Flatpak"
        "OpenJDK 17 + TLauncher installer DEB"
    )
    local app_sel=("0" "0" "0" "0" "0" "0" "0" "1" "0" "0" "0" "0" "0" "0")
    local app_dis=("0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0" "0")

    show_banner
    tput cup 7 0
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 2/4 - Chọn ứng dụng${RESET}"
    echo ""
    checkbox_menu "Chọn:" app_names app_descs app_sel app_dis

    # ========================================================
    #  BƯỚC 3 - XÁC NHẬN
    # ========================================================
    show_banner
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 3/4 - Xác nhận${RESET}"
    echo ""
    echo -e "  ${BOLD}${WHITE}Danh sách sẽ cài:${RESET}"
    echo ""

    local any=0
    [[ "${base_sel[0]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Cập nhật hệ thống"               && any=1
    [[ "${base_sel[1]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Debian contrib/non-free"         && any=1
    [[ "${base_sel[2]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Flathub"                         && any=1
    [[ "${base_sel[3]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Hỗ trợ Snap"                     && any=1
    [[ "${app_sel[0]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Brave Browser"                   && any=1
    [[ "${app_sel[1]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Google Chrome"                   && any=1
    [[ "${app_sel[2]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} VLC + FFmpeg"                    && any=1
    [[ "${app_sel[3]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Zoom"                            && any=1
    [[ "${app_sel[4]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Discord"                         && any=1
    [[ "${app_sel[5]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Blue Recorder (Flatpak)"         && any=1
    [[ "${app_sel[6]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Fcitx5 + Unikey"                 && any=1
    [[ "${app_sel[7]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} Git + Fastfetch"                 && any=1
    [[ "${app_sel[8]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} OnlyOffice (Flatpak)"            && any=1
    [[ "${app_sel[9]}"  == "1" ]] && echo -e "  ${GREEN}✓${RESET} WPS Office"                      && any=1
    [[ "${app_sel[10]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} Spotify (Flatpak)"               && any=1
    [[ "${app_sel[11]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} VS Code"                         && any=1
    [[ "${app_sel[12]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} OBS Studio (Flatpak)"            && any=1
    [[ "${app_sel[13]}" == "1" ]] && echo -e "  ${GREEN}✓${RESET} TLauncher Minecraft"             && any=1

    echo ""

    if [[ $any -eq 0 ]]; then
        echo -e "  ${YELLOW}Chưa chọn gì cả. Thoát.${RESET}"
        exit 0
    fi

    echo -ne "  ${BOLD}Xác nhận bắt đầu cài? [Y/n]: ${RESET}"
    read -r confirm
    [[ "$confirm" =~ ^[Nn]$ ]] && echo -e "\n  ${GRAY}Đã hủy.${RESET}\n" && exit 0

    # ========================================================
    #  BƯỚC 4 - CÀI ĐẶT
    # ========================================================
    echo ""
    echo -e "  ${BOLD}${MAGENTA}BƯỚC 4/4 - Đang cài đặt...${RESET}"
    log_div
    [[ "${base_sel[0]}" == "1" ]] && run_task "Cập nhật hệ thống" do_system_update
    [[ "${base_sel[1]}" == "1" ]] && run_task "Debian contrib/non-free" do_debian_repos
    [[ "${base_sel[2]}" == "1" ]] && run_task "Flathub" do_flathub
    [[ "${base_sel[3]}" == "1" ]] && run_task "Hỗ trợ Snap" do_snap_support

    [[ "${app_sel[0]}"  == "1" ]] && run_task "Brave Browser" do_brave
    [[ "${app_sel[1]}"  == "1" ]] && run_task "Google Chrome" do_chrome
    [[ "${app_sel[2]}"  == "1" ]] && run_task "VLC + FFmpeg" do_vlc_ffmpeg
    [[ "${app_sel[3]}"  == "1" ]] && run_task "Zoom" do_zoom
    [[ "${app_sel[4]}"  == "1" ]] && run_task "Discord" do_discord
    [[ "${app_sel[5]}"  == "1" ]] && run_task "Blue Recorder" do_bluerecorder
    [[ "${app_sel[6]}"  == "1" ]] && run_task "Fcitx5 + Unikey" do_fcitx5
    [[ "${app_sel[7]}"  == "1" ]] && run_task "Git + Fastfetch" do_dev_tools
    [[ "${app_sel[8]}"  == "1" ]] && run_task "OnlyOffice" do_onlyoffice
    [[ "${app_sel[9]}"  == "1" ]] && run_task "WPS Office" do_wps
    [[ "${app_sel[10]}" == "1" ]] && run_task "Spotify" do_spotify
    [[ "${app_sel[11]}" == "1" ]] && run_task "VS Code" do_vscode
    [[ "${app_sel[12]}" == "1" ]] && run_task "OBS Studio" do_obs
    [[ "${app_sel[13]}" == "1" ]] && run_task "TLauncher Minecraft" do_tlauncher

    run_task "Cập nhật lần cuối" do_final_update

    echo ""
    log_div
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        echo -e "  ${YELLOW}${BOLD}Setup đã chạy xong, nhưng có mục bị lỗi:${RESET}"
        for item in "${FAILED_ITEMS[@]}"; do
            echo -e "  ${RED}✗${RESET} ${item}"
        done
    else
        echo -e "  ${GREEN}${BOLD}Setup xong!${RESET}"
    fi
    echo ""
    log_div
    echo ""
    echo -ne "  ${BOLD}Khởi động lại ngay? [y/N]: ${RESET}"
    read -r rb
    if [[ "$rb" =~ ^[Yy]$ ]]; then
        echo -e "  ${CYAN}Đang khởi động lại...${RESET}"
        sudo systemctl reboot
    else
        echo -e "  ${GRAY}Nhớ khởi động lại sau để áp dụng toàn bộ thay đổi!${RESET}\n"
    fi
}

main "$@"
