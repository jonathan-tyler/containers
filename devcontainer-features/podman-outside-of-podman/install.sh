#!/usr/bin/env bash

set -e

SOCKET_PATH="${SOCKETPATH:-/run/user-host/podman/podman.sock}"

err() {
    echo "(!) $*" >&2
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
