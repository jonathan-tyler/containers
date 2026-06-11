#!/usr/bin/env bash

set -euo pipefail

INSTALL_ZSH="${INSTALL_ZSH:-${INSTALLZSH:-true}}"
SET_ZSH_AS_DEFAULT_SHELL="${SET_ZSH_AS_DEFAULT_SHELL:-${SETZSHASDEFAULTSHELL:-false}}"
INSTALL_ZSH_AUTOSUGGESTIONS="${INSTALL_ZSH_AUTOSUGGESTIONS:-${INSTALLZSHAUTOSUGGESTIONS:-true}}"
INSTALL_ZSH_VI_MODE="${INSTALL_ZSH_VI_MODE:-${INSTALLZSHVIMODE:-true}}"
INSTALL_STARSHIP="${INSTALL_STARSHIP:-${INSTALLSTARSHIP:-true}}"
INSTALL_TMUX="${INSTALL_TMUX:-${INSTALLTMUX:-true}}"
INSTALL_TREE="${INSTALL_TREE:-${INSTALLTREE:-false}}"
INSTALL_MAN_DB="${INSTALL_MAN_DB:-${INSTALLMANDB:-false}}"
INSTALL_MAN_PAGES="${INSTALL_MAN_PAGES:-${INSTALLMANPAGES:-false}}"
INSTALL_BAT="${INSTALL_BAT:-${INSTALLBAT:-false}}"
INSTALL_BTOP="${INSTALL_BTOP:-${INSTALLBTOP:-false}}"
INSTALL_NEOVIM="${INSTALL_NEOVIM:-${INSTALLNEOVIM:-true}}"
INSTALL_EZA="${INSTALL_EZA:-${INSTALLEZA:-true}}"
INSTALL_YAZI="${INSTALL_YAZI:-${INSTALLYAZI:-true}}"
INSTALL_ZOXIDE="${INSTALL_ZOXIDE:-${INSTALLZOXIDE:-true}}"
INSTALL_SESH="${INSTALL_SESH:-${INSTALLSESH:-true}}"
INSTALL_FZF="${INSTALL_FZF:-${INSTALLFZF:-true}}"
INSTALL_DELTA="${INSTALL_DELTA:-${INSTALLDELTA:-true}}"
INSTALL_DIFFTASTIC="${INSTALL_DIFFTASTIC:-${INSTALLDIFFTASTIC:-true}}"
INSTALL_LAZYGIT="${INSTALL_LAZYGIT:-${INSTALLLAZYGIT:-true}}"
USERNAME="${USERNAME:-automatic}"

STARSHIP_VERSION="1.25.1"
NEOVIM_VERSION="0.12.2"
EZA_VERSION="0.23.4"
YAZI_VERSION="26.5.6"
ZOXIDE_VERSION="0.9.9"
SESH_VERSION="2.26.2"
FZF_VERSION="0.73.1"
DELTA_VERSION="0.19.2"
DIFFTASTIC_VERSION="0.69.0"
LAZYGIT_VERSION="0.62.2"
ZSH_AUTOSUGGESTIONS_VERSION="0.7.1"
ZSH_VI_MODE_VERSION="0.12.0"

err() {
    echo "(!) $*" >&2
}

is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

resolve_username() {
    local candidate="${USERNAME}"

    if [ "${candidate}" = "auto" ] || [ "${candidate}" = "automatic" ]; then
        for current_user in vscode node codespace "$(awk -F: '$3 == 1000 { print $1 }' /etc/passwd)"; do
            if [ -n "${current_user}" ] && id -u "${current_user}" >/dev/null 2>&1; then
                echo "${current_user}"
                return
            fi
        done

        echo root
        return
    fi

    if id -u "${candidate}" >/dev/null 2>&1; then
        echo "${candidate}"
        return
    fi

    echo root
}

user_home() {
    local user_name="$1"
    awk -F: -v user_name="${user_name}" '$1 == user_name { print $6 }' /etc/passwd
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            err "Unsupported architecture: $(uname -m)."
            exit 1
            ;;
    esac
}

install_packages() {
    dnf -y install --setopt=install_weak_deps=False "$@"
}

install_release_binary() {
    local url="$1"
    local binary_name="$2"
    local target_name="${3:-${binary_name}}"
    local archive_kind="${4:-tar.gz}"
    local tmp_dir
    local candidate

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' RETURN

    curl -fsSL "${url}" -o "${tmp_dir}/archive"

    case "${archive_kind}" in
        tar.gz)
            tar -xzf "${tmp_dir}/archive" -C "${tmp_dir}"
            ;;
        zip)
            unzip -q "${tmp_dir}/archive" -d "${tmp_dir}"
            ;;
        *)
            err "Unsupported archive kind: ${archive_kind}."
            exit 1
            ;;
    esac

    for candidate in \
        "${tmp_dir}/${binary_name}" \
        "${tmp_dir}"/*/"${binary_name}" \
        "${tmp_dir}"/*/*/"${binary_name}"; do
        if [ -f "${candidate}" ]; then
            install -m 0755 "${candidate}" "/usr/local/bin/${target_name}"
            trap - RETURN
            rm -rf "${tmp_dir}"
            return
        fi
    done

    err "Unable to find ${binary_name} in downloaded archive ${url}."
    exit 1
}

install_neovim_release() {
    local url="$1"
    local tmp_dir

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' RETURN

    curl -fsSL "${url}" -o "${tmp_dir}/nvim.tar.gz"
    rm -rf /opt/nvim
    mkdir -p /opt/nvim
    tar -xzf "${tmp_dir}/nvim.tar.gz" -C /opt/nvim --strip-components=1
    ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

    trap - RETURN
    rm -rf "${tmp_dir}"
}

install_yazi_release() {
    local url="$1"
    local tmp_dir
    local yazi_path=""
    local ya_path=""
    local candidate

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' RETURN

    curl -fsSL "${url}" -o "${tmp_dir}/yazi.zip"
    unzip -q "${tmp_dir}/yazi.zip" -d "${tmp_dir}"

    for candidate in "${tmp_dir}/yazi" "${tmp_dir}"/*/yazi; do
        if [ -f "${candidate}" ]; then
            yazi_path="${candidate}"
            break
        fi
    done

    for candidate in "${tmp_dir}/ya" "${tmp_dir}"/*/ya; do
        if [ -f "${candidate}" ]; then
            ya_path="${candidate}"
            break
        fi
    done

    if [ -z "${yazi_path}" ] || [ -z "${ya_path}" ]; then
        err "Unable to find yazi or ya in downloaded archive ${url}."
        exit 1
    fi

    install -m 0755 "${yazi_path}" /usr/local/bin/yazi
    install -m 0755 "${ya_path}" /usr/local/bin/ya

    trap - RETURN
    rm -rf "${tmp_dir}"
}

install_plugin_archive() {
    local url="$1"
    local destination="$2"
    local owner_name="$3"
    local owner_group="$4"
    local tmp_dir

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' RETURN

    rm -rf "${destination}"
    mkdir -p "${destination}"
    curl -fsSL "${url}" -o "${tmp_dir}/plugin.tar.gz"
    tar -xzf "${tmp_dir}/plugin.tar.gz" -C "${destination}" --strip-components=1
    chown -R "${owner_name}:${owner_group}" "${destination}"

    trap - RETURN
    rm -rf "${tmp_dir}"
}

if [ "$(id -u)" -ne 0 ]; then
    err "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
    exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
    err "This feature currently supports Fedora and RHEL-family images with dnf."
    exit 1
fi

dnf -y update
install_packages curl shadow-utils

resolved_user="$(resolve_username)"
resolved_home="$(user_home "${resolved_user}")"
resolved_group="$(id -gn "${resolved_user}")"
arch="$(detect_arch)"

if [ -z "${resolved_home}" ]; then
    err "Unable to determine home directory for ${resolved_user}."
    exit 1
fi

if is_true "${INSTALL_ZSH}" || is_true "${SET_ZSH_AS_DEFAULT_SHELL}"; then
    install_packages zsh
fi

if is_true "${INSTALL_TMUX}"; then
    install_packages tmux
fi

human_package_list=()

if is_true "${INSTALL_TREE}"; then
    human_package_list+=(tree)
fi

if is_true "${INSTALL_MAN_DB}"; then
    human_package_list+=(man-db)
fi

if is_true "${INSTALL_MAN_PAGES}"; then
    human_package_list+=(man-pages)
fi

if is_true "${INSTALL_BAT}"; then
    human_package_list+=(bat)
fi

if is_true "${INSTALL_BTOP}"; then
    human_package_list+=(btop)
fi

if [ "${#human_package_list[@]}" -gt 0 ]; then
    install_packages "${human_package_list[@]}"
fi

if is_true "${SET_ZSH_AS_DEFAULT_SHELL}"; then
    usermod --shell /usr/bin/zsh "${resolved_user}"
fi

if is_true "${INSTALL_ZSH_AUTOSUGGESTIONS}" || is_true "${INSTALL_ZSH_VI_MODE}"; then
    install -d -m 0755 -o "${resolved_user}" -g "${resolved_group}" "${resolved_home}/.local/share/zsh/plugins"
fi

if is_true "${INSTALL_ZSH_AUTOSUGGESTIONS}"; then
    install_plugin_archive \
        "https://github.com/zsh-users/zsh-autosuggestions/archive/refs/tags/v${ZSH_AUTOSUGGESTIONS_VERSION}.tar.gz" \
        "${resolved_home}/.local/share/zsh/plugins/zsh-autosuggestions" \
        "${resolved_user}" \
        "${resolved_group}"
fi

if is_true "${INSTALL_ZSH_VI_MODE}"; then
    install_plugin_archive \
        "https://github.com/jeffreytse/zsh-vi-mode/archive/refs/tags/v${ZSH_VI_MODE_VERSION}.tar.gz" \
        "${resolved_home}/.local/share/zsh/plugins/zsh-vi-mode" \
        "${resolved_user}" \
        "${resolved_group}"
fi

if [ "${arch}" = "x86_64" ]; then
    starship_url="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-musl.tar.gz"
    neovim_url="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"
    eza_url="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz"
    yazi_url="https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-x86_64-unknown-linux-gnu.zip"
    zoxide_url="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    sesh_url="https://github.com/joshmedeski/sesh/releases/download/v${SESH_VERSION}/sesh_Linux_x86_64.tar.gz"
    fzf_url="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
    delta_url="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    difftastic_url="https://github.com/Wilfred/difftastic/releases/download/${DIFFTASTIC_VERSION}/difft-x86_64-unknown-linux-gnu.tar.gz"
    lazygit_url="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz"
else
    starship_url="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-aarch64-unknown-linux-musl.tar.gz"
    neovim_url="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-arm64.tar.gz"
    eza_url="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_aarch64-unknown-linux-gnu_no_libgit.tar.gz"
    yazi_url="https://github.com/sxyazi/yazi/releases/download/v${YAZI_VERSION}/yazi-aarch64-unknown-linux-gnu.zip"
    zoxide_url="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-aarch64-unknown-linux-musl.tar.gz"
    sesh_url="https://github.com/joshmedeski/sesh/releases/download/v${SESH_VERSION}/sesh_Linux_arm64.tar.gz"
    fzf_url="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_arm64.tar.gz"
    delta_url="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
    difftastic_url="https://github.com/Wilfred/difftastic/releases/download/${DIFFTASTIC_VERSION}/difft-aarch64-unknown-linux-gnu.tar.gz"
    lazygit_url="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_arm64.tar.gz"
fi

if is_true "${INSTALL_STARSHIP}"; then
    install_release_binary "${starship_url}" starship
fi

if is_true "${INSTALL_NEOVIM}"; then
    install_neovim_release "${neovim_url}"
fi

if is_true "${INSTALL_EZA}"; then
    install_release_binary "${eza_url}" eza
fi

if is_true "${INSTALL_YAZI}"; then
    install_yazi_release "${yazi_url}"
fi

if is_true "${INSTALL_ZOXIDE}"; then
    install_release_binary "${zoxide_url}" zoxide
fi

if is_true "${INSTALL_SESH}"; then
    install_release_binary "${sesh_url}" sesh
fi

if is_true "${INSTALL_FZF}"; then
    install_release_binary "${fzf_url}" fzf
fi

if is_true "${INSTALL_DELTA}"; then
    install_release_binary "${delta_url}" delta
fi

if is_true "${INSTALL_DIFFTASTIC}"; then
    install_release_binary "${difftastic_url}" difft
fi

if is_true "${INSTALL_LAZYGIT}"; then
    install_release_binary "${lazygit_url}" lazygit
fi

dnf clean all

echo "Done!"
