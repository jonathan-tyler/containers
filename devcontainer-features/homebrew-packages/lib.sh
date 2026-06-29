#!/usr/bin/env bash

err() {
    echo "(!) $*" >&2
}

imageSupportFamily() {
    local id=""
    local id_like=""

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        id="${ID:-}"
        id_like="${ID_LIKE:-}"
    fi

    case " ${id} ${id_like} " in
        *" alpine "*)
            echo "alpine"
            ;;
        *" ubuntu "*|*" debian "*)
            echo "ubuntu"
            ;;
        *" fedora "*|*" rhel "*|*" centos "*|*" rocky "*|*" almalinux "*)
            echo "fedora-rhel"
            ;;
        *)
            err "Unsupported Linux base image: ${id:-unknown} ${id_like}"
            exit 1
            ;;
    esac
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

requireHomebrewPrerequisiteCommands() {
    local required_command

    for required_command in bash curl git file awk ps tar gzip xz; do
        if ! commandExists "${required_command}"; then
            err "${required_command} is required to bootstrap Homebrew."
            exit 1
        fi
    done
}

isNumericId() {
    case "${1:-}" in
        ''|*[!0-9]*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

isUnsupportedHomebrewUid() {
    [ "${1:-}" = "65532" ]
}

firstUserForUid() {
    local uid="$1"

    awk -F: -v target_uid="${uid}" '$3 == target_uid { print $1; exit }' /etc/passwd
}

identifyNonRootUser() {
    local requested_user="${1:-automatic}"
    local candidate
    local candidate_uid

    if [ "${requested_user}" != "" ] && [ "${requested_user}" != "auto" ] && [ "${requested_user}" != "automatic" ]; then
        if [ "${requested_user}" = "none" ] || [ "${requested_user}" = "root" ]; then
            err "Homebrew requires a named non-root passwd user. Create one in your image or add the 'nonroot-user' feature before using homebrew-packages."
            exit 1
        fi

        if isNumericId "${requested_user}"; then
            err "Requested user '${requested_user}' is numeric-only. Homebrew requires a named non-root passwd user."
            exit 1
        fi

        if ! id -u "${requested_user}" >/dev/null 2>&1; then
            err "Requested user '${requested_user}' does not exist."
            exit 1
        fi

        candidate_uid="$(userUid "${requested_user}")"
        if [ "${candidate_uid}" -eq 0 ]; then
            err "Requested user '${requested_user}' is root. Homebrew requires a named non-root passwd user."
            exit 1
        fi

        if isUnsupportedHomebrewUid "${candidate_uid}"; then
            err "Requested user '${requested_user}' resolves to unsupported UID 65532. Create a real named non-root passwd user before using homebrew-packages."
            exit 1
        fi

        echo "${requested_user}"
        return
    fi

    for candidate in \
        "${_REMOTE_USER:-}" \
        "${_CONTAINER_USER:-}" \
        "nonroot" \
        "devcontainer" \
        "vscode" \
        "node" \
        "codespace" \
        "podman" \
        "ubuntu" \
        "coder" \
        "app" \
        "user" \
        "$(firstUserForUid 1000)"; do
        if [ -z "${candidate}" ] || isNumericId "${candidate}" || ! id -u "${candidate}" >/dev/null 2>&1; then
            continue
        fi

        candidate_uid="$(userUid "${candidate}")"
        if [ "${candidate_uid}" -ne 0 ] && ! isUnsupportedHomebrewUid "${candidate_uid}"; then
            echo "${candidate}"
            return
        fi
    done

    candidate="$(awk -F: '$3 >= 1000 && $3 < 65534 && $3 != 65532 && $1 != "nobody" { print $1; exit }' /etc/passwd)"
    if [ -n "${candidate}" ] && id -u "${candidate}" >/dev/null 2>&1 && [ "$(id -u "${candidate}")" -ne 0 ]; then
        echo "${candidate}"
        return
    fi

    err "Homebrew requires a named non-root passwd user. Create one in your image or add the 'nonroot-user' feature before using homebrew-packages."
    exit 1
}

userUid() {
    local username="$1"

    if id -u "${username}" >/dev/null 2>&1; then
        id -u "${username}"
        return
    fi

    if isNumericId "${username}"; then
        echo "${username}"
        return
    fi

    err "Unable to determine UID for '${username}'."
    exit 1
}

userGid() {
    local username="$1"
    local group_id

    if id -u "${username}" >/dev/null 2>&1; then
        id -g "${username}"
        return
    fi

    group_id="$(awk -F: -v target_user="${username}" '$1 == target_user { print $4; exit }' /etc/passwd)"
    if [ -n "${group_id}" ]; then
        echo "${group_id}"
        return
    fi

    if isNumericId "${username}"; then
        echo 0
        return
    fi

    err "Unable to determine group for '${username}'."
    exit 1
}

userHome() {
    local username="$1"
    local home_dir

    home_dir="$(awk -F: -v target_user="${username}" '$1 == target_user { print $6; exit }' /etc/passwd)"
    if [ -n "${home_dir}" ]; then
        echo "${home_dir}"
        return
    fi

    if [ "${_REMOTE_USER:-}" = "${username}" ] && [ -n "${_REMOTE_USER_HOME:-}" ]; then
        echo "${_REMOTE_USER_HOME}"
        return
    fi

    if [ "${_CONTAINER_USER:-}" = "${username}" ] && [ -n "${_CONTAINER_USER_HOME:-}" ]; then
        echo "${_CONTAINER_USER_HOME}"
        return
    fi

    if [ "${username}" = "root" ]; then
        echo "/root"
        return
    fi

    if isNumericId "${username}"; then
        echo "/tmp"
        return
    fi

    err "Unable to determine home directory for '${username}'."
    exit 1
}

runAsUser() {
    local username="$1"
    local home_dir
    local uid
    local gid
    shift

    home_dir="$(userHome "${username}")"
    uid="$(userUid "${username}")"
    gid="$(userGid "${username}")"

    if [ "${username}" = "root" ]; then
        env HOME="${home_dir}" USER="${username}" LOGNAME="${username}" PATH="${PATH}" "$@"
        return
    fi

    if commandExists setpriv; then
        if id -u "${username}" >/dev/null 2>&1; then
            env HOME="${home_dir}" USER="${username}" LOGNAME="${username}" PATH="${PATH}" setpriv --reuid "${uid}" --regid "${gid}" --init-groups "$@"
        else
            env HOME="${home_dir}" USER="${username}" LOGNAME="${username}" PATH="${PATH}" setpriv --reuid "${uid}" --regid "${gid}" --clear-groups "$@"
        fi
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

    err "Unable to switch to '${username}'. Install util-linux or shadow-utils so runuser, su, or setpriv is available."
    exit 1
}
