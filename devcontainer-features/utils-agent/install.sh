#!/usr/bin/env bash

set -euo pipefail

YQ_VERSION="4.53.3"
SHELLCHECK_VERSION="0.11.0"
SHFMT_VERSION="3.13.1"

err() {
    echo "(!) $*" >&2
}

install_packages() {
    dnf -y install --setopt=install_weak_deps=False "$@"
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            err "Unsupported architecture: $(uname -m)."
            exit 1
            ;;
    esac
}

install_direct_binary() {
    local url="$1"
    local target_name="$2"
    local tmp_dir

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' RETURN

    curl -fsSL "${url}" -o "${tmp_dir}/${target_name}"
    install -m 0755 "${tmp_dir}/${target_name}" "/usr/local/bin/${target_name}"

    trap - RETURN
    rm -rf "${tmp_dir}"
}

install_shellcheck() {
    local url="$1"
    local tmp_dir
    local candidate

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir}"' RETURN

    curl -fsSL "${url}" -o "${tmp_dir}/shellcheck.tar.xz"
    tar -xJf "${tmp_dir}/shellcheck.tar.xz" -C "${tmp_dir}"

    for candidate in "${tmp_dir}/shellcheck" "${tmp_dir}"/*/shellcheck; do
        if [ -f "${candidate}" ]; then
            install -m 0755 "${candidate}" /usr/local/bin/shellcheck
            trap - RETURN
            rm -rf "${tmp_dir}"
            return
        fi
    done

    err "Unable to find shellcheck in downloaded archive ${url}."
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
install_packages ca-certificates curl diffstat patchutils tar xz

if dnf -q list yamllint >/dev/null 2>&1; then
    install_packages yamllint
else
    install_packages python3 python3-pip
    if ! python3 -m pip install --no-cache-dir yamllint; then
        python3 -m pip install --no-cache-dir --break-system-packages yamllint
    fi
fi

arch="$(detect_arch)"

if [ "${arch}" = "amd64" ]; then
    yq_url="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64"
    shellcheck_url="https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.x86_64.tar.xz"
    shfmt_url="https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_amd64"
else
    yq_url="https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_arm64"
    shellcheck_url="https://github.com/koalaman/shellcheck/releases/download/v${SHELLCHECK_VERSION}/shellcheck-v${SHELLCHECK_VERSION}.linux.aarch64.tar.xz"
    shfmt_url="https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_arm64"
fi

install_direct_binary "${yq_url}" yq
install_shellcheck "${shellcheck_url}"
install_direct_binary "${shfmt_url}" shfmt

dnf clean all
rm -rf /root/.cache/pip

echo "Done!"
