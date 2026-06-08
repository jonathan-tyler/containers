#!/usr/bin/env bash

set -euo pipefail

err() {
    echo "(!) $*" >&2
}

install_packages() {
    dnf -y install --setopt=install_weak_deps=False "$@"
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
    ripgrep \
    sed \
    tar \
    unzip \
    which \
    xz \
    zip

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
