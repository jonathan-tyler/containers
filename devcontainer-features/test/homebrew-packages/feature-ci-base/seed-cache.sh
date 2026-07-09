#!/usr/bin/env bash

set -euo pipefail

bootstrap_user="${1:-nonroot}"
brew_prefix="/home/linuxbrew/.linuxbrew"
shared_cache_dir="/var/cache/homebrew-shared"
custom_cache_dir="/var/cache/homebrew"
homebrew_install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

run_as_user() {
    local username="$1"
    local home_dir
    local uid
    local gid
    shift

    home_dir="$(getent passwd "${username}" | cut -d: -f6)"
    uid="$(id -u "${username}")"
    gid="$(id -g "${username}")"

    if command -v setpriv >/dev/null 2>&1; then
        env HOME="${home_dir}" USER="${username}" LOGNAME="${username}" PATH="${PATH}" \
            setpriv --reuid "${uid}" --regid "${gid}" --init-groups "$@"
        return
    fi

    if command -v runuser >/dev/null 2>&1; then
        runuser -u "${username}" -- env HOME="${home_dir}" USER="${username}" LOGNAME="${username}" PATH="${PATH}" "$@"
        return
    fi

    su -s /bin/bash "${username}" -c "export HOME=$(printf '%q' "${home_dir}") USER=$(printf '%q' "${username}") LOGNAME=$(printf '%q' "${username}") PATH=$(printf '%q' "${PATH}"); exec $(printf '%q ' "$@")"
}

install -d -o "${bootstrap_user}" -g "${bootstrap_user}" \
    "/home/linuxbrew" \
    "${brew_prefix}" \
    "${shared_cache_dir}" \
    "${custom_cache_dir}"

if [ ! -x "${brew_prefix}/bin/brew" ]; then
    run_as_user "${bootstrap_user}" env \
        HOMEBREW_CACHE="${shared_cache_dir}" \
        HOMEBREW_NO_ASK=1 \
        NONINTERACTIVE=1 \
        CI=1 \
        /bin/bash -c "$(curl -fsSL "${homebrew_install_url}")"
fi

run_as_user "${bootstrap_user}" env \
    HOMEBREW_CACHE="${shared_cache_dir}" \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_NO_ENV_HINTS=1 \
    HOMEBREW_NO_INSTALL_CLEANUP=1 \
    "${brew_prefix}/bin/brew" fetch --formula --force --force-bottle --deps hello

rm -rf "${custom_cache_dir}"
install -d "${custom_cache_dir}"
cp -a "${shared_cache_dir}/." "${custom_cache_dir}"

rm -rf \
    "/home/${bootstrap_user}/.cache/Homebrew" \
    "/root/.cache/Homebrew"

chown -R root:root "${brew_prefix}" "${shared_cache_dir}" "${custom_cache_dir}"
