#!/usr/bin/env bash

set -euo pipefail

username="${USERNAME:-automatic}"
BREW_PREFIX="${BREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
homebrew_cache_directory="${CACHE_DIRECTORY:-${HOMEBREW_CACHE_DIR:-/tmp/homebrew-cache}}"
cleanup_homebrew="${CLEANUP_HOMEBREW:-${CLEANUPHOMEBREW:-false}}"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib.sh
source "${FEATURE_DIR}/lib.sh"
# shellcheck source=/dev/null
source "${FEATURE_DIR}/lib-$(imageSupportFamily).sh"

if commandExists brew; then
    BREW_PREFIX="$(brew --prefix)"
fi

prepareHomebrewPrefix() {
    local username="$1"
    local group="$2"
    local cache_directory="$3"
    local prefix_parent

    prefix_parent="$(dirname "${BREW_PREFIX}")"
    install -d "${prefix_parent}" "${BREW_PREFIX}" "${cache_directory}"
    chown -R "${username}:${group}" "${prefix_parent}" "${cache_directory}"
}

installHomebrew() {
    local username="$1"

    if [ -x "${BREW_PREFIX}/bin/brew" ]; then
        return
    fi

    runAsUser "${username}" env HOMEBREW_NO_ASK=1 NONINTERACTIVE=1 CI=1 /bin/bash -c "$(curl -fsSL "${HOMEBREW_INSTALL_URL}")"
}

linkHomebrewCheckout() {
    if [ -d "${BREW_PREFIX}/Homebrew/Library" ] && [ ! -e "${BREW_PREFIX}/Library" ]; then
        ln -s "Homebrew/Library" "${BREW_PREFIX}/Library"
    fi
}

linkBrewExecutable() {
    install -d /usr/local/bin
    ln -sf "${BREW_PREFIX}/bin/brew" /usr/local/bin/brew
}

pathContains() {
    case "$2" in
        "$1"|"$1"/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

cleanupHomebrewManager() {
    local target_home="$1"
    local cache_directory="$2"
    local cache_path

    rm -f /usr/local/bin/brew "${BREW_PREFIX}/bin/brew"
    for cache_path in \
        "/root/.cache/Homebrew" \
        "${target_home}/.cache/Homebrew"; do
        if ! pathContains "${cache_path}" "${cache_directory}"; then
            rm -rf "${cache_path}"
        fi
    done

    if [ "${cache_directory}" = "/tmp/homebrew-cache" ]; then
        rm -rf "${cache_directory}"
    fi

    rm -rf \
        "${BREW_PREFIX}/Homebrew" \
        "${BREW_PREFIX}/Library" \
        "${BREW_PREFIX}/Caskroom" \
        "${BREW_PREFIX}/var/homebrew" \
        "${BREW_PREFIX}/etc/bash_completion.d/brew" \
        "${BREW_PREFIX}/share/doc/homebrew" \
        "${BREW_PREFIX}/share/fish/vendor_completions.d/brew.fish" \
        "${BREW_PREFIX}/share/man/man1/brew.1" \
        "${BREW_PREFIX}/share/zsh/site-functions/_brew"

    find "${BREW_PREFIX}" -type d -empty -delete 2>/dev/null || true
}

shouldCleanupHomebrew() {
    case "$1" in
        false|False|FALSE|0|no|No|NO|off|Off|OFF)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

requireRoot
ensureHomebrewPrerequisites

target_user="$(identifyNonRootUser "${username}")"
target_group="$(userGid "${target_user}")"
target_home="$(userHome "${target_user}")"

ensureUserSwitchTool

prepareHomebrewPrefix "${target_user}" "${target_group}" "${homebrew_cache_directory}"
installHomebrew "${target_user}"
chown -R "${target_user}:${target_group}" "${BREW_PREFIX}"
linkHomebrewCheckout
linkBrewExecutable
if shouldCleanupHomebrew "${cleanup_homebrew}"; then
    cleanupHomebrewManager "${target_home}" "${homebrew_cache_directory}"
fi
chown -R root:root "${BREW_PREFIX}"

echo "Done!"
