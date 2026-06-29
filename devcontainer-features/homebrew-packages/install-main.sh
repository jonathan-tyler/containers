#!/usr/bin/env bash

set -euo pipefail

packages="${PACKAGES:-}"
username="${USERNAME:-automatic}"
BREW_PREFIX="${BREW_PREFIX:-/home/linuxbrew/.linuxbrew}"
homebrew_cache_directory="${CACHE_DIRECTORY:-${HOMEBREW_CACHE_DIR:-/tmp/homebrew-cache}}"
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

installFormulae() {
    local username="$1"
    local cache_directory="$2"
    shift
    shift

    if [ "$#" -eq 0 ]; then
        return
    fi

    runAsUser "${username}" env \
        HOMEBREW_NO_ASK=1 \
        NONINTERACTIVE=1 \
        HOMEBREW_NO_ANALYTICS=1 \
        HOMEBREW_NO_AUTO_UPDATE=1 \
        HOMEBREW_NO_ENV_HINTS=1 \
        HOMEBREW_NO_INSTALL_CLEANUP=1 \
        HOMEBREW_CACHE="${cache_directory}" \
        "${BREW_PREFIX}/bin/brew" install --formula "$@"

    runAsUser "${username}" env \
        HOMEBREW_NO_ANALYTICS=1 \
        HOMEBREW_NO_AUTO_UPDATE=1 \
        HOMEBREW_NO_ENV_HINTS=1 \
        HOMEBREW_CACHE="${cache_directory}" \
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

    rm -f "${BREW_PREFIX}/bin/brew"
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
        "${BREW_PREFIX}/Caskroom" \
        "${BREW_PREFIX}/var/homebrew" \
        "${BREW_PREFIX}/etc/bash_completion.d/brew" \
        "${BREW_PREFIX}/share/doc/homebrew" \
        "${BREW_PREFIX}/share/fish/vendor_completions.d/brew.fish" \
        "${BREW_PREFIX}/share/man/man1/brew.1" \
        "${BREW_PREFIX}/share/zsh/site-functions/_brew"

    find "${BREW_PREFIX}" -type d -empty -delete 2>/dev/null || true
}

requireRoot

if [ -z "${packages//[[:space:]]/}" ]; then
    echo "No Homebrew packages requested. Skipping."
    exit 0
fi

ensureHomebrewPrerequisites

read -r -a requested_packages <<< "${packages}"
target_user="$(identifyNonRootUser "${username}")"
if [ "${target_user}" = "root" ]; then
    target_user="$(ensureFallbackHomebrewUser)"
    echo "No non-root container user detected; using '${target_user}' for Homebrew installation."
fi

target_group="$(userGid "${target_user}")"
target_home="$(userHome "${target_user}")"

ensureUserSwitchTool

prepareHomebrewPrefix "${target_user}" "${target_group}" "${homebrew_cache_directory}"
installHomebrew "${target_user}"
chown -R "${target_user}:${target_group}" "${BREW_PREFIX}"
installFormulae "${target_user}" "${homebrew_cache_directory}" "${requested_packages[@]}"
linkExecutables "${BREW_PREFIX}/bin" /usr/local/bin
linkExecutables "${BREW_PREFIX}/sbin" /usr/local/sbin
cleanupHomebrewManager "${target_home}" "${homebrew_cache_directory}"
chown -R root:root "${BREW_PREFIX}"

echo "Done!"
