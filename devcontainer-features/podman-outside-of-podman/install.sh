#!/usr/bin/env bash

set -e

SOCKET_PATH="${SOCKETPATH:-/run/user-host/podman/podman.sock}"
FEDORA_RELEASE="42"
FEDORA_REPO_PRIORITY="99"

err() {
    echo "(!) $*" >&2
}

write_fedora_repos() {
    local fedora_repo_dir="/etc/yum.repos.d"
    local gpgcheck="$1"
    local repo_gpgcheck="$2"

    mkdir -p "${fedora_repo_dir}"

    cat >"${fedora_repo_dir}/fedora.repo" <<EOF
[fedora]
name=Fedora ${FEDORA_RELEASE} - \$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-${FEDORA_RELEASE}&arch=\$basearch
enabled=1
metadata_expire=7d
type=rpm-md
priority=${FEDORA_REPO_PRIORITY}
repo_gpgcheck=${repo_gpgcheck}
gpgcheck=${gpgcheck}
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${FEDORA_RELEASE}-\$basearch

[updates]
name=Fedora ${FEDORA_RELEASE} - \$basearch - Updates
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f${FEDORA_RELEASE}&arch=\$basearch
enabled=1
metadata_expire=6h
type=rpm-md
priority=${FEDORA_REPO_PRIORITY}
repo_gpgcheck=${repo_gpgcheck}
gpgcheck=${gpgcheck}
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-${FEDORA_RELEASE}-\$basearch
EOF
}

bootstrap_fedora_keys() {
    write_fedora_repos 0 0
    dnf -y --setopt=install_weak_deps=False install fedora-gpg-keys
    write_fedora_repos 1 0
}

if [ "$(id -u)" -ne 0 ]; then
    err "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
    exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
    err "This feature currently supports Fedora and RHEL-family images with dnf."
    exit 1
fi

bootstrap_fedora_keys
dnf -y install --setopt=install_weak_deps=False \
    ca-certificates \
    podman

mkdir -p /usr/local/share

cat >/usr/local/share/podman-outside-of-podman-init.sh <<EOF
#!/usr/bin/env bash

set -e

SOCKET_PATH="${SOCKET_PATH}"

if [ "\$(id -u)" -ne 0 ] && [ -z "\${XDG_RUNTIME_DIR:-}" ]; then
    export XDG_RUNTIME_DIR="/tmp/podman-run-\$(id -u)"
fi

if [ -n "\${XDG_RUNTIME_DIR:-}" ]; then
    mkdir -p "\${XDG_RUNTIME_DIR}"
    chmod 700 "\${XDG_RUNTIME_DIR}"
fi

if [ -z "\${CONTAINER_HOST:-}" ]; then
    export CONTAINER_HOST="unix://\${SOCKET_PATH}"
fi

if [ -z "\${DOCKER_HOST:-}" ]; then
    export DOCKER_HOST="\${CONTAINER_HOST}"
fi

exec "\$@"
EOF

chmod +x /usr/local/share/podman-outside-of-podman-init.sh

dnf clean all

echo "Done!"
