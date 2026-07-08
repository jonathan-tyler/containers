#!/bin/sh

set -eu

username="${USERNAME:-nonroot}"
requested_uid="${USER_UID:-automatic}"
requested_gid="${USER_GID:-automatic}"
requested_home="${USER_HOME:-automatic}"
requested_shell="${USER_SHELL:-automatic}"

err() {
    echo "(!) $*" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        err "Script must be run as root."
        exit 1
    fi
}

is_numeric_id() {
    case "${1:-}" in
        ''|*[!0-9]*)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

image_support_family() {
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
    fi

    case " ${ID:-} ${ID_LIKE:-} " in
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
            err "Unsupported Linux base image: ${ID:-unknown} ${ID_LIKE:-}"
            exit 1
            ;;
    esac
}

ensure_user_management_tools() {
    if command_exists useradd && command_exists groupadd; then
        return
    fi

    case "$(image_support_family)" in
        ubuntu)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update
            apt-get install -y --no-install-recommends passwd
            rm -rf /var/lib/apt/lists/*
            ;;
        fedora-rhel)
            dnf -y install --setopt=install_weak_deps=False shadow-utils
            dnf clean all
            ;;
        alpine)
            apk add --no-cache shadow
            ;;
    esac

    if ! command_exists useradd || ! command_exists groupadd; then
        err "Unable to install user management tools for creating '${username}'."
        exit 1
    fi
}

group_exists() {
    grep -q "^$1:" /etc/group
}

require_root

if [ -z "${username}" ]; then
    err "username must not be empty."
    exit 1
fi

if is_numeric_id "${username}"; then
    err "username must be a named user, not a numeric UID."
    exit 1
fi

if [ "${requested_uid}" != "automatic" ] && ! is_numeric_id "${requested_uid}"; then
    err "user_uid must be numeric or 'automatic'."
    exit 1
fi

if [ "${requested_gid}" != "automatic" ] && ! is_numeric_id "${requested_gid}"; then
    err "user_gid must be numeric or 'automatic'."
    exit 1
fi

if id -u "${username}" >/dev/null 2>&1; then
    if [ "$(id -u "${username}")" -eq 0 ]; then
        err "'${username}' already exists as root. Choose a different username."
        exit 1
    fi

    echo "User '${username}' already exists. Skipping."
    exit 0
fi

ensure_user_management_tools

home_dir="${requested_home}"
if [ "${home_dir}" = "automatic" ]; then
    home_dir="/home/${username}"
fi

shell_path="${requested_shell}"
if [ "${shell_path}" = "automatic" ]; then
    if [ -x /bin/bash ]; then
        shell_path=/bin/bash
    else
        shell_path=/bin/sh
    fi
fi

if [ "${requested_gid}" != "automatic" ] && ! group_exists "${username}"; then
    groupadd -g "${requested_gid}" "${username}"
fi

set -- useradd --create-home --home-dir "${home_dir}" --shell "${shell_path}"
if [ "${requested_uid}" != "automatic" ]; then
    set -- "$@" --uid "${requested_uid}"
fi
if [ "${requested_gid}" != "automatic" ]; then
    set -- "$@" --gid "${username}"
elif group_exists "${username}"; then
    set -- "$@" --gid "${username}"
else
    set -- "$@" --user-group
fi

"$@" "${username}"

echo "Created user '${username}'."
