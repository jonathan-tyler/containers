#!/usr/bin/env bash

USERNAME="${USERNAME:-automatic}"
PODMAN_USER="podman"
SUBID_RANGE_MAX="65536"

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

    grep -m1 "^[^:]*:[^:]*:${uid}:" /etc/passwd 2>/dev/null | cut -d: -f1 || true
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

resolveRuntimeUser() {
    local candidate="${USERNAME}"
    local current_user

    if [ "${candidate}" = "none" ] || [ "${candidate}" = "root" ]; then
        echo root
        return
    fi

    if [ "${candidate}" = "auto" ] || [ "${candidate}" = "automatic" ]; then
        for current_user in \
            "${_REMOTE_USER:-}" \
            "${_CONTAINER_USER:-}" \
            nonroot \
            devcontainer \
            vscode \
            node \
            codespace \
            podman \
            ubuntu \
            coder \
            app \
            user \
            "$(firstUserForUid 1000)"; do
            if [ -n "${current_user}" ] && ! isNumericId "${current_user}" && id -u "${current_user}" >/dev/null 2>&1; then
                if [ "$(id -u "${current_user}")" != "0" ]; then
                    echo "${current_user}"
                    return
                fi
            fi
        done

        echo root
        return
    fi

    if isNumericId "${candidate}"; then
        err "Requested user '${candidate}' is numeric-only. Podman-in-Podman supports only named non-root users or root."
        exit 1
    fi

    if id -u "${candidate}" >/dev/null 2>&1; then
        if [ "$(id -u "${candidate}")" = "0" ]; then
            echo root
            return
        fi

        echo "${candidate}"
        return
    fi

    err "Requested user '${candidate}' does not exist."
    exit 1
}

replaceRootlessSubids() {
    local user_name="$1"
    local file_path="$2"
    local user_id
    local tmp_file

    if id -u "${user_name}" >/dev/null 2>&1; then
        user_id="$(id -u "${user_name}")"
    elif isNumericId "${user_name}"; then
        user_id="${user_name}"
    else
        err "Unable to determine UID for ${user_name}"
        exit 1
    fi

    tmp_file="$(mktemp)"

    touch "${file_path}"
    grep -vE "^${user_name}:" "${file_path}" >"${tmp_file}" || true

    if [ "${user_id}" -le 1 ] || [ "${user_id}" -gt "${SUBID_RANGE_MAX}" ]; then
        printf '%s:%s:%s\n' "${user_name}" 1 "${SUBID_RANGE_MAX}" >>"${tmp_file}"
    else
        printf '%s:%s:%s\n' "${user_name}" 1 "$((user_id - 1))" >>"${tmp_file}"
        printf '%s:%s:%s\n' "${user_name}" "$((user_id + 1))" "$((SUBID_RANGE_MAX - user_id))" >>"${tmp_file}"
    fi

    cat "${tmp_file}" >"${file_path}"
    rm -f "${tmp_file}"
}

ensurePodmanUser() {
    if id -u "${PODMAN_USER}" >/dev/null 2>&1; then
        return
    fi

    if ! commandExists useradd; then
        installFedoraRhelPackages shadow-utils
    fi

    useradd --create-home --shell /bin/bash "${PODMAN_USER}"
}

writePodmanConfigs() {
    local fuse_overlayfs_path="$1"

    mkdir -p \
        /etc/containers \
        "/home/${PODMAN_USER}/.config/containers" \
        "/home/${PODMAN_USER}/.local/share/containers" \
        /usr/local/share \
        /var/lib/containers

    cat >/etc/containers/containers.conf <<'EOF'
[engine]
cgroup_manager = "cgroupfs"
events_logger = "file"
EOF

    cat >/etc/containers/storage.conf <<EOF
[storage]
driver = "overlay"

[storage.options]
mount_program = "${fuse_overlayfs_path}"

[storage.options.overlay]
mountopt = "nodev,fsync=0"
EOF
}

writeInitScript() {
    cat >/usr/local/share/podman-in-podman-init.sh <<'EOF'
#!/usr/bin/env bash

set -e

if [ "$(id -u)" -ne 0 ] && [ -z "${XDG_RUNTIME_DIR:-}" ]; then
    runtime_home="$(grep -m1 "^[^:]*:[^:]*:$(id -u):" /etc/passwd 2>/dev/null | cut -d: -f6 || true)"
    if [ -n "${runtime_home}" ] && [ -w "${runtime_home}" ]; then
        export XDG_RUNTIME_DIR="${runtime_home}/.podman-run-$(id -u)"
    elif [ -n "${HOME:-}" ] && [ -w "${HOME}" ]; then
        export XDG_RUNTIME_DIR="${HOME}/.podman-run-$(id -u)"
    else
        export XDG_RUNTIME_DIR="/tmp/podman-run-$(id -u)"
    fi
fi

if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
    mkdir -p "${XDG_RUNTIME_DIR}"
    chmod 700 "${XDG_RUNTIME_DIR}"
fi

exec "$@"
EOF

    chmod +x /usr/local/share/podman-in-podman-init.sh
}

configureRootlessUsers() {
    local resolved_user="$1"

    replaceRootlessSubids "${PODMAN_USER}" /etc/subuid
    replaceRootlessSubids "${PODMAN_USER}" /etc/subgid

    if [ "${resolved_user}" != "root" ] && [ "${resolved_user}" != "${PODMAN_USER}" ]; then
        replaceRootlessSubids "${resolved_user}" /etc/subuid
        replaceRootlessSubids "${resolved_user}" /etc/subgid
    fi

    chown -R "${PODMAN_USER}:${PODMAN_USER}" "/home/${PODMAN_USER}"
}
