#!/usr/bin/env bash

err() {
    echo "(!) $*" >&2
}

requireRoot() {
    if [ "$(id -u)" -ne 0 ]; then
        err "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
        exit 1
    fi
}

commandExists() {
    command -v "$1" >/dev/null 2>&1
}

firstUserForUid() {
    local uid="$1"

    awk -F: -v target_uid="${uid}" '$3 == target_uid { print $1; exit }' /etc/passwd
}

identifyNonRootUser() {
    local requested_user="${1:-automatic}"
    local candidate

    if [ "${requested_user}" != "" ] && [ "${requested_user}" != "auto" ] && [ "${requested_user}" != "automatic" ]; then
        if [ "${requested_user}" = "none" ]; then
            echo "root"
            return
        fi

        if ! id -u "${requested_user}" >/dev/null 2>&1; then
            err "Requested user '${requested_user}' does not exist."
            exit 1
        fi

        if [ "$(id -u "${requested_user}")" -eq 0 ]; then
            echo "root"
            return
        fi

        echo "${requested_user}"
        return
    fi

    for candidate in \
        "$(firstUserForUid 65532)" \
        "vscode" \
        "node" \
        "codespace" \
        "devcontainer" \
        "nonroot" \
        "podman" \
        "ubuntu" \
        "coder" \
        "app" \
        "user" \
        "$(firstUserForUid 1000)"; do
        if [ -n "${candidate}" ] && id -u "${candidate}" >/dev/null 2>&1 && [ "$(id -u "${candidate}")" -ne 0 ]; then
            echo "${candidate}"
            return
        fi
    done

    candidate="$(awk -F: '$3 >= 1000 && $3 < 65534 && $1 != "nobody" { print $1; exit }' /etc/passwd)"
    if [ -n "${candidate}" ] && id -u "${candidate}" >/dev/null 2>&1 && [ "$(id -u "${candidate}")" -ne 0 ]; then
        echo "${candidate}"
        return
    fi

    echo "root"
}

userHome() {
    local username="$1"
    local home_dir

    home_dir="$(awk -F: -v target_user="${username}" '$1 == target_user { print $6; exit }' /etc/passwd)"
    if [ -n "${home_dir}" ]; then
        echo "${home_dir}"
        return
    fi

    if [ "${username}" = "root" ]; then
        echo "/root"
        return
    fi

    err "Unable to determine home directory for '${username}'."
    exit 1
}

runAsUser() {
    local username="$1"
    local home_dir
    shift

    home_dir="$(userHome "${username}")"

    if [ "${username}" = "root" ]; then
        env HOME="${home_dir}" USER="${username}" LOGNAME="${username}" PATH="${PATH}" "$@"
        return
    fi

    if commandExists runuser; then
        runuser -u "${username}" -- env HOME="${home_dir}" USER="${username}" LOGNAME="${username}" PATH="${PATH}" "$@"
        return
    fi

    if commandExists su; then
        local escaped_command=""
        local argument

        for argument in "$@"; do
            escaped_command+=" $(printf '%q' "${argument}")"
        done

        su -s /bin/bash "${username}" -c "export HOME=$(printf '%q' "${home_dir}") USER=$(printf '%q' "${username}") LOGNAME=$(printf '%q' "${username}") PATH=$(printf '%q' "${PATH}"); exec${escaped_command}"
        return
    fi

    if commandExists setpriv; then
        env HOME="${home_dir}" USER="${username}" LOGNAME="${username}" PATH="${PATH}" setpriv --reuid "$(id -u "${username}")" --regid "$(id -g "${username}")" --init-groups "$@"
        return
    fi

    err "Unable to switch to '${username}'. Install util-linux or shadow-utils so runuser, su, or setpriv is available."
    exit 1
}
