#!/usr/bin/env bash

set -euo pipefail

VERSION="${VERSION:-latest}"

err() {
    echo "(!) $*" >&2
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
dnf -y install --setopt=install_weak_deps=False ca-certificates

if ! command -v npm >/dev/null 2>&1; then
    dnf -y install --setopt=install_weak_deps=False nodejs npm || dnf -y install --setopt=install_weak_deps=False nodejs
fi

if [ "${VERSION}" = "latest" ]; then
    npm install -g @devcontainers/cli@latest
else
    npm install -g "@devcontainers/cli@${VERSION#v}"
fi

dnf clean all

echo "Done!"
