#!/usr/bin/env bash

set -euo pipefail

PACKAGES="${PACKAGES:-}"
USERNAME="${USERNAME:-automatic}"
BREW_PREFIX="${BREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib.sh
source "${FEATURE_DIR}/lib.sh"

ensureHomebrewPrerequisites() {
    local missing_packages=()

    if ! commandExists curl; then
        missing_packages+=(curl)
    fi

    if ! commandExists git; then
        missing_packages+=(git)
    fi

    if ! commandExists file; then
        missing_packages+=(file)
    fi

    if ! commandExists awk; then
        missing_packages+=(gawk)
    fi

    if ! commandExists ps; then
        missing_packages+=(procps-ng)
    fi

    if ! commandExists tar; then
        missing_packages+=(tar)
    fi

    if ! commandExists gzip; then
        missing_packages+=(gzip)
    fi

    if ! commandExists xz; then
        missing_packages+=(xz)
    fi

    if [ "${#missing_packages[@]}" -gt 0 ]; then
        if ! commandExists dnf; then
            err "Missing Homebrew prerequisites (${missing_packages[*]}) and no dnf package manager is available to install them."
            exit 1
        fi

        dnf -y install --setopt=install_weak_deps=False ca-certificates "${missing_packages[@]}"
        dnf clean all
    fi

    if ! commandExists curl || ! commandExists git || ! commandExists file || ! commandExists tar || ! commandExists gzip; then
        err "curl, git, file, tar, and gzip are required to bootstrap Homebrew."
        exit 1
    fi
}

ensureUserSwitchTool() {
    if commandExists runuser || commandExists su || commandExists setpriv; then
        return
    fi

    if ! commandExists dnf; then
        err "Installing formulae as a non-root user requires runuser, su, or setpriv. None were found."
        exit 1
    fi

    dnf -y install --setopt=install_weak_deps=False util-linux
    dnf clean all

    if ! commandExists runuser && ! commandExists su && ! commandExists setpriv; then
        err "Installing formulae as a non-root user requires runuser, su, or setpriv."
        exit 1
    fi
}

installHomebrew() {
    if [ -x "${BREW_PREFIX}/bin/brew" ]; then
        return
    fi

    NONINTERACTIVE=1 CI=1 /bin/bash -c "$(curl -fsSL "${HOMEBREW_INSTALL_URL}")"
}

installFormulae() {
    local username="$1"
    shift

    if [ "$#" -eq 0 ]; then
        return
    fi

    runAsUser "${username}" env \
        HOMEBREW_NO_ANALYTICS=1 \
        HOMEBREW_NO_AUTO_UPDATE=1 \
        HOMEBREW_NO_ENV_HINTS=1 \
        HOMEBREW_NO_INSTALL_CLEANUP=1 \
        HOMEBREW_CACHE=/tmp/homebrew-cache \
        "${BREW_PREFIX}/bin/brew" install --formula "$@"

    runAsUser "${username}" env \
        HOMEBREW_NO_ANALYTICS=1 \
        HOMEBREW_NO_AUTO_UPDATE=1 \
        HOMEBREW_NO_ENV_HINTS=1 \
        HOMEBREW_CACHE=/tmp/homebrew-cache \
        "${BREW_PREFIX}/bin/brew" cleanup --prune=all --scrub
}

linkExecutables() {
    local source_dir="$1"
    local target_dir="$2"
    local candidate
    local name

    [ -d "${source_dir}" ] || return

    install -d "${target_dir}"

    for candidate in "${source_dir}"/*; do
        [ -e "${candidate}" ] || continue

        name="${candidate##*/}"
        if [ "${name}" = "brew" ]; then
            continue
        fi

        ln -sf "${candidate}" "${target_dir}/${name}"
    done
}

cleanupHomebrewManager() {
    local target_home="$1"

    rm -f "${BREW_PREFIX}/bin/brew"
    rm -rf \
        "${BREW_PREFIX}/Homebrew" \
        "${BREW_PREFIX}/Caskroom" \
        "${BREW_PREFIX}/var/homebrew" \
        "${BREW_PREFIX}/etc/bash_completion.d/brew" \
        "${BREW_PREFIX}/share/doc/homebrew" \
        "${BREW_PREFIX}/share/fish/vendor_completions.d/brew.fish" \
        "${BREW_PREFIX}/share/man/man1/brew.1" \
        "${BREW_PREFIX}/share/zsh/site-functions/_brew" \
        "/root/.cache/Homebrew" \
        "${target_home}/.cache/Homebrew" \
        /tmp/homebrew-cache

    find "${BREW_PREFIX}" -type d -empty -delete 2>/dev/null || true
}

requireRoot

if [ -z "${PACKAGES//[[:space:]]/}" ]; then
    echo "No Homebrew packages requested. Skipping."
    exit 0
fi

ensureHomebrewPrerequisites

read -r -a requested_packages <<< "${PACKAGES}"
target_user="$(identifyNonRootUser "${USERNAME}")"
target_group="$(id -gn "${target_user}")"
target_home="$(userHome "${target_user}")"

if [ "${target_user}" = "root" ]; then
    echo "No non-root container user detected; installing Homebrew formulae as root."
else
    ensureUserSwitchTool
fi

installHomebrew
chown -R "${target_user}:${target_group}" "${BREW_PREFIX}"
installFormulae "${target_user}" "${requested_packages[@]}"
linkExecutables "${BREW_PREFIX}/bin" /usr/local/bin
linkExecutables "${BREW_PREFIX}/sbin" /usr/local/sbin
cleanupHomebrewManager "${target_home}"
chown -R root:root "${BREW_PREFIX}"

echo "Done!"
