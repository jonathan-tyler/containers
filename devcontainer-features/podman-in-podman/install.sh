#!/usr/bin/env bash

set -e

USERNAME="${USERNAME:-${_REMOTE_USER:-automatic}}"
PREFERRED_UID="65532"
PODMAN_USER="podman"
PODMAN_SUBID_START="100000"
REMOTE_USER_SUBID_START="165536"
SUBID_COUNT="65536"

err() {
    echo "(!) $*" >&2
}

get_username_for_uid() {
    local uid="$1"

    getent passwd "${uid}" | cut -d: -f1
}

resolve_username() {
    local candidate="${USERNAME}"

    if [ "${candidate}" = "none" ]; then
        echo root
        return
    fi

    if [ "${candidate}" = "${PREFERRED_UID}" ]; then
        preferred_user="$(get_username_for_uid "${PREFERRED_UID}")"
        if [ -n "${preferred_user}" ]; then
            echo "${preferred_user}"
            return
        fi
    fi

    if [ "${candidate}" = "auto" ] || [ "${candidate}" = "automatic" ] || [ "${candidate}" = "root" ]; then
        local preferred_user

        preferred_user="$(get_username_for_uid "${PREFERRED_UID}")"
        if [ -n "${preferred_user}" ]; then
            echo "${preferred_user}"
            return
        fi

        if [ -n "${_REMOTE_USER:-}" ] && [ "${_REMOTE_USER}" != "root" ] && id -u "${_REMOTE_USER}" >/dev/null 2>&1; then
            echo "${_REMOTE_USER}"
            return
        fi

        for current_user in devcontainer vscode node codespace "$(awk -F: '$3 == 1000 { print $1 }' /etc/passwd)"; do
            if [ -n "${current_user}" ] && id -u "${current_user}" >/dev/null 2>&1; then
                echo "${current_user}"
                return
            fi
        done

        echo root
        return
    fi

    if [ "${candidate}" = "none" ] || ! id -u "${candidate}" >/dev/null 2>&1; then
        preferred_user="$(get_username_for_uid "${candidate}")"
        if [ -n "${preferred_user}" ]; then
            echo "${preferred_user}"
            return
        fi

        echo root
        return
    fi

    echo "${candidate}"
}

ensure_subids() {
    local user_name="$1"
    local start="$2"
    local count="$3"
    local file_path="$4"

    touch "${file_path}"
    if ! grep -qE "^${user_name}:" "${file_path}"; then
        printf '%s:%s:%s\n' "${user_name}" "${start}" "${count}" >>"${file_path}"
    fi
}

if [ "$(id -u)" -ne 0 ]; then
    err "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
    exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
    err "This feature currently supports Fedora and RHEL-family images with dnf."
    exit 1
fi

dnf -y update
dnf -y reinstall shadow-utils
dnf -y install --setopt=install_weak_deps=False \
    ca-certificates \
    containernetworking-plugins \
    fuse-overlayfs \
    podman \
    shadow-utils \
    slirp4netns

resolved_user="$(resolve_username)"

if ! id -u "${PODMAN_USER}" >/dev/null 2>&1; then
    useradd --create-home --shell /bin/bash "${PODMAN_USER}"
fi

mkdir -p \
    /etc/containers \
    /home/${PODMAN_USER}/.config/containers \
    /home/${PODMAN_USER}/.local/share/containers \
    /usr/local/share \
    /var/lib/containers

cat >/etc/containers/containers.conf <<'EOF'
[engine]
cgroup_manager = "cgroupfs"
events_logger = "file"
EOF

cat >/etc/containers/storage.conf <<'EOF'
[storage]
driver = "overlay"

[storage.options]
mount_program = "/usr/bin/fuse-overlayfs"

[storage.options.overlay]
mountopt = "nodev,fsync=0"
EOF

cat >/usr/local/share/podman-in-podman-init.sh <<'EOF'
#!/usr/bin/env bash

set -e

if [ "$(id -u)" -ne 0 ] && [ -z "${XDG_RUNTIME_DIR:-}" ]; then
    export XDG_RUNTIME_DIR="/tmp/podman-run-$(id -u)"
fi

if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
    mkdir -p "${XDG_RUNTIME_DIR}"
    chmod 700 "${XDG_RUNTIME_DIR}"
fi

exec "$@"
EOF

chmod +x /usr/local/share/podman-in-podman-init.sh

ensure_subids "${PODMAN_USER}" "${PODMAN_SUBID_START}" "${SUBID_COUNT}" /etc/subuid
ensure_subids "${PODMAN_USER}" "${PODMAN_SUBID_START}" "${SUBID_COUNT}" /etc/subgid

if [ "${resolved_user}" != "root" ] && [ "${resolved_user}" != "${PODMAN_USER}" ]; then
    ensure_subids "${resolved_user}" "${REMOTE_USER_SUBID_START}" "${SUBID_COUNT}" /etc/subuid
    ensure_subids "${resolved_user}" "${REMOTE_USER_SUBID_START}" "${SUBID_COUNT}" /etc/subgid
fi

chown -R "${PODMAN_USER}:${PODMAN_USER}" "/home/${PODMAN_USER}"

dnf clean all

echo "Done!"
