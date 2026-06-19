#!/usr/bin/env bash

set -euo pipefail

RIPGREP_VERSION="15.1.0"

err() {
    echo "(!) $*" >&2
}

install_packages() {
    dnf -y install --setopt=install_weak_deps=False "$@"
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

if [ "$(id -u)" -ne 0 ]; then
    err "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
    exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
    err "This feature currently supports Fedora and RHEL-family images with dnf."
    exit 1
fi

dnf -y update

install_packages \
    ca-certificates \
    curl \
    diffutils \
    file \
    findutils \
    gawk \
    git \
    grep \
    gzip \
    jq \
    less \
    patch \
    procps-ng \
    sed \
    tar \
    unzip \
    which \
    xz \
    zip

arch="$(detect_arch)"

if [ "${arch}" = "x86_64" ]; then
    ripgrep_url="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
else
    ripgrep_url="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
fi

install_release_binary "${ripgrep_url}" rg

if dnf -q list fd-find >/dev/null 2>&1; then
    install_packages fd-find
elif dnf -q list fd >/dev/null 2>&1; then
    install_packages fd
fi

if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

dnf clean all

echo "Done!"
