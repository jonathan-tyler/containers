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
    bind-utils \
    ca-certificates \
    curl \
    iproute \
    lsof \
    net-tools \
    nmap-ncat \
    openssh-clients \
    psmisc \
    rsync \
    socat \
    strace \
    wget

dnf clean all

echo "Done!"
