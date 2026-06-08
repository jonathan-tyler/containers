#!/usr/bin/env bash

set -euo pipefail

VERSION="${VERSION:-latest}"

err() {
    echo "(!) $*" >&2
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x64"
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

if [ "$(id -u)" -ne 0 ]; then
    err "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
    exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
    err "This feature currently supports Fedora and RHEL-family images with dnf."
    exit 1
fi

dnf -y update
dnf -y install --setopt=install_weak_deps=False ca-certificates curl tar unzip

arch="$(detect_arch)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

if [ "${VERSION}" = "latest" ]; then
    url="https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-${arch}.tar.gz"
else
    clean_version="${VERSION#v}"
    url="https://github.com/anomalyco/opencode/releases/download/v${clean_version}/opencode-linux-${arch}.tar.gz"
fi

curl -fsSL "${url}" -o "${tmp_dir}/opencode.tar.gz"
tar -xzf "${tmp_dir}/opencode.tar.gz" -C "${tmp_dir}"
install -m 0755 "${tmp_dir}/opencode" /usr/local/bin/opencode

dnf clean all

echo "Done!"
