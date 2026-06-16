#!/usr/bin/env bash

set -euo pipefail

INSTALL_CLI="${INSTALLCLI:-"true"}"

err() {
    echo "(!) $*" >&2
}

detect_pkg_mgr() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt-get"
        return
    fi

    if command -v dnf >/dev/null 2>&1; then
        echo "dnf"
        return
    fi

    err "This feature currently supports apt-get and dnf based images."
    exit 1
}

install_packages() {
    pkg_mgr="$1"
    shift

    case "${pkg_mgr}" in
        apt-get)
            apt-get update -y
            DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
            ;;
        dnf)
            dnf -y install --setopt=install_weak_deps=False "$@"
            ;;
        *)
            err "Unsupported package manager: ${pkg_mgr}"
            exit 1
            ;;
    esac
}

if [ "$(id -u)" -ne 0 ]; then
    err "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
    exit 1
fi

echo "Activating feature 'dotnet-aspire-cli'"

if [[ "${INSTALL_CLI,,}" == "true" ]]; then
    echo "Installing Aspire CLI..."

    pkg_mgr="$(detect_pkg_mgr)"
    pkgs=()

    if ! command -v curl >/dev/null 2>&1; then
        pkgs+=(curl ca-certificates)
    fi

    if ! command -v ldconfig >/dev/null 2>&1 || ! ldconfig -p 2>/dev/null | grep -q 'libicudata'; then
        case "${pkg_mgr}" in
            apt-get)
                pkgs+=(libicu-dev)
                ;;
            dnf)
                pkgs+=(libicu)
                ;;
        esac
    fi

    if [ "${#pkgs[@]}" -gt 0 ]; then
        install_packages "${pkg_mgr}" "${pkgs[@]}"
    fi

    curl -fsSL https://aspire.dev/install.sh | bash

    ASPIRE_BIN="${HOME}/.aspire/bin/aspire"
    if [[ -f "${ASPIRE_BIN}" ]]; then
        cp "${ASPIRE_BIN}" /usr/local/bin/aspire
        chmod 755 /usr/local/bin/aspire
    else
        err "Aspire CLI installer did not produce ${ASPIRE_BIN}."
        exit 1
    fi
fi

echo "... done activating feature 'dotnet-aspire-cli'"
