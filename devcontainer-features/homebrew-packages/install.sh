#!/bin/sh

set -eu

packages="${PACKAGES:-}"
FEATURE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

if [ -z "$(printf '%s' "${packages}" | tr -d '[:space:]')" ]; then
    echo "No Homebrew packages requested. Skipping."
    exit 0
fi

if ! command -v bash >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . /etc/os-release

    case " ${ID:-} ${ID_LIKE:-} " in
        *" alpine "*)
            apk add --no-cache bash
            ;;
        *" ubuntu "*|*" debian "*)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update
            apt-get install -y --no-install-recommends bash
            rm -rf /var/lib/apt/lists/*
            ;;
        *" fedora "*|*" rhel "*|*" centos "*|*" rocky "*|*" almalinux "*)
            dnf -y install --setopt=install_weak_deps=False bash
            dnf clean all
            ;;
        *)
            echo "(!) Unsupported Linux base image: ${ID:-unknown} ${ID_LIKE:-}" >&2
            exit 1
            ;;
    esac
fi

exec bash "${FEATURE_DIR}/install-main.sh"
